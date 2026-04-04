# VCD Categorical Analysis Pipeline (v2.0)
# 2-pass mode: --profile (Pass 1) or --render --config <path> (Pass 2)
# Outputs under ./skill_out/vcd_categorical/
#
# Usage:
#   Pass 1: Rscript analysis.R --profile --data data.csv --vars x,y,z --freq Freq
#   Pass 2: Rscript analysis.R --render  --data data.csv --vars x,y,z --freq Freq --label mydata
#   Default (no --data): uses built-in HairEyeColor dataset

# --- Packages ---
if (!base::requireNamespace("pacman", quietly = TRUE)) utils::install.packages("pacman")
pacman::p_load(vcd, gt, DT, htmlwidgets, ggplot2, jsonlite)

# --- CLI argument parser ---
parse_cli_arg <- function(args, flag, default = NULL) {
  if (flag %in% args) {
    idx <- base::which(args == flag)
    if (idx < base::length(args)) {
      return(args[idx + 1])
    }
  }
  return(default)
}

args <- base::commandArgs(trailingOnly = TRUE)
mode <- if ("--profile" %in% args) "profile" else "render"
config_path <- parse_cli_arg(args, "--config")
data_path <- parse_cli_arg(args, "--data")
vars_str <- parse_cli_arg(args, "--vars")
freq_col_arg <- parse_cli_arg(args, "--freq", "Freq")
label_arg <- parse_cli_arg(args, "--label")
out_arg <- parse_cli_arg(args, "--out")

# --- Config validator ---
validate_config <- function(raw) {
  defaults <- base::list(
    collapse_below_n = 0L,
    max_levels_per_var = 999L,
    strata_to_render = base::character(0),
    gt_matrix_vars = c(1L, 2L),
    plot_mode = "auto"
  )
  known_keys <- base::names(defaults)
  unknown <- base::setdiff(base::names(raw), known_keys)
  if (base::length(unknown) > 0) {
    base::message("[WARNING] Unknown config keys ignored: ", base::paste(unknown, collapse = ", "))
  }

  cfg <- defaults
  if ("collapse_below_n" %in% base::names(raw)) {
    v <- base::suppressWarnings(base::as.integer(raw$collapse_below_n))
    if (!base::is.na(v)) {
      cfg$collapse_below_n <- v
    } else {
      base::message("[WARNING] collapse_below_n: not integer, using default 0")
    }
  }
  if ("max_levels_per_var" %in% base::names(raw)) {
    v <- base::suppressWarnings(base::as.integer(raw$max_levels_per_var))
    if (!base::is.na(v)) {
      cfg$max_levels_per_var <- v
    } else {
      base::message("[WARNING] max_levels_per_var: not integer, using default 999")
    }
  }
  if ("strata_to_render" %in% base::names(raw)) {
    v <- raw$strata_to_render
    if (base::is.character(v) || base::is.list(v)) {
      cfg$strata_to_render <- base::as.character(base::unlist(v))
    } else {
      base::message("[WARNING] strata_to_render: not character array, using default []")
    }
  }
  if ("gt_matrix_vars" %in% base::names(raw)) {
    v <- base::suppressWarnings(base::as.integer(base::unlist(raw$gt_matrix_vars)))
    if (base::length(v) >= 2 && !base::any(base::is.na(v))) {
      cfg$gt_matrix_vars <- v[1:2]
    } else {
      base::message("[WARNING] gt_matrix_vars: invalid, using default [1,2]")
    }
  }
  if ("plot_mode" %in% base::names(raw)) {
    v <- raw$plot_mode
    if (base::is.character(v) && v %in% c("auto", "always", "residual_only")) {
      cfg$plot_mode <- v
    } else {
      base::message("[WARNING] plot_mode: invalid '", v, "', using default 'auto'")
    }
  }
  cfg
}

# --- Data loader (CRLF-safe) ---
load_input_data <- function(data_path, vars_str, freq_col_arg, label_arg) {
  if (base::is.null(data_path)) {
    utils::data("HairEyeColor", package = "datasets")
    df <- base::as.data.frame(HairEyeColor)
    vars <- c("Hair", "Eye", "Sex")
    freq_col <- "Freq"
    data_label <- if (!base::is.null(label_arg)) label_arg else "haireye"
  } else {
    df <- utils::read.csv(data_path, check.names = FALSE, fileEncoding = "UTF-8")
    base::names(df) <- base::trimws(base::names(df))
    for (j in base::seq_len(base::ncol(df))) {
      if (base::is.character(df[[j]])) df[[j]] <- base::trimws(df[[j]])
    }

    if (base::is.null(vars_str)) base::stop("[ERROR] --vars is required when --data is specified")
    vars <- base::trimws(base::strsplit(vars_str, ",")[[1]])
    freq_col <- base::trimws(freq_col_arg)

    missing_cols <- base::setdiff(c(vars, freq_col), base::names(df))
    if (base::length(missing_cols) > 0) {
      base::stop(
        "[ERROR] Columns not found in data: ", base::paste(missing_cols, collapse = ", "),
        "\n  Available columns: ", base::paste(base::names(df), collapse = ", ")
      )
    }

    # Validate frequency column is numeric
    if (!base::is.numeric(df[[freq_col]])) {
      base::message("[WARNING] frequency column '", freq_col, "' is not numeric. Attempting conversion.")
      df[[freq_col]] <- base::as.numeric(base::as.character(df[[freq_col]]))
    }

    # Ensure categorical variables are factors
    for (v in vars) {
      if (!base::is.factor(df[[v]])) {
        base::message("[INFO] Converting '", v, "' to factor.")
        df[[v]] <- base::as.factor(df[[v]])
      }
    }

    # Handle empty levels
    for (v in vars) {
      df[[v]] <- base::droplevels(df[[v]])
    }

    data_label <- if (!base::is.null(label_arg)) {
      label_arg
    } else {
      base::gsub("\\.[^.]+$", "", base::basename(data_path))
    }
  }
  base::list(df = df, vars = vars, freq_col = freq_col, data_label = data_label)
}

# ============================================================
# generate_profile: Pass 1 - lightweight data profiling
# ============================================================
generate_profile <- function(df, vars, freq_col = "Freq", output_dir,
                             config = NULL, out_filename = "data_profile.json") {
  if (!base::is.null(config)) {
    if (!base::is.null(config$collapse_below_n) && config$collapse_below_n > 0) {
      for (v in vars) {
        freq_by_level <- stats::tapply(df[[freq_col]], df[[v]], base::sum)
        minor_levels <- base::names(freq_by_level[freq_by_level <= config$collapse_below_n])
        if (base::length(minor_levels) > 0) {
          df[[v]] <- base::ifelse(df[[v]] %in% minor_levels, "Other", base::as.character(df[[v]]))
          df[[v]] <- base::factor(df[[v]])
        }
      }
    }
    max_lev <- config$max_levels_per_var
    if (!base::is.null(max_lev) && base::is.numeric(max_lev) && max_lev < 999) {
      for (v in vars) {
        lvls <- base::levels(df[[v]])
        if (base::length(lvls) > max_lev) {
          freq_by_level <- stats::tapply(df[[freq_col]], df[[v]], base::sum)
          top_levels <- base::names(base::sort(freq_by_level, decreasing = TRUE))[base::seq_len(max_lev)]
          df[[v]] <- base::ifelse(base::as.character(df[[v]]) %in% top_levels,
            base::as.character(df[[v]]), "Other"
          )
          df[[v]] <- base::factor(df[[v]])
        }
      }
    }
  }

  var_info <- base::lapply(vars, function(v) {
    lvls <- base::levels(base::factor(df[[v]]))
    base::list(n_levels = base::length(lvls), levels = lvls)
  })
  base::names(var_info) <- vars

  tab <- stats::xtabs(stats::as.formula(
    base::paste(freq_col, "~", base::paste(vars, collapse = " + "))
  ), data = df)
  total_cells <- base::prod(base::dim(tab))
  n_nonzero <- base::sum(base::as.vector(tab) > 0)

  marginal_cells <- if (base::length(vars) >= 2) {
    base::prod(base::dim(tab)[1:2])
  } else {
    total_cells
  }

  profile <- base::list(
    n_dimensions = base::length(vars),
    variables = var_info,
    total_cells = total_cells,
    total_cells_2way_marginal = marginal_cells,
    n_nonzero_cells = n_nonzero,
    sparsity_ratio = base::round(n_nonzero / total_cells, 3),
    warning = if (n_nonzero < total_cells) "Contains zero-count cells (Sparsity). GLM may have convergence issues." else NULL
  )
  jsonlite::write_json(profile, base::file.path(output_dir, out_filename),
    auto_unbox = TRUE, pretty = TRUE
  )
  base::message("[PROFILE] ", out_filename, " written to ", output_dir)
  return(base::invisible(profile))
}

# ============================================================
# generate_data: Pass 2 - GLM fitting, residuals, JSON/CSV
# ============================================================
generate_data <- function(df, vars, freq_col = "Freq", output_dir, config, data_label = "data") {
  if (!base::is.null(config$collapse_below_n) && config$collapse_below_n > 0) {
    for (v in vars) {
      freq_by_level <- stats::tapply(df[[freq_col]], df[[v]], base::sum)
      minor_levels <- base::names(freq_by_level[freq_by_level <= config$collapse_below_n])
      if (base::length(minor_levels) > 0) {
        df[[v]] <- base::ifelse(df[[v]] %in% minor_levels, "Other", base::as.character(df[[v]]))
        df[[v]] <- base::factor(df[[v]])
      }
    }
  }

  max_lev <- config$max_levels_per_var
  if (!base::is.null(max_lev) && base::is.numeric(max_lev) && max_lev < 999) {
    for (v in vars) {
      lvls <- base::levels(df[[v]])
      if (base::length(lvls) > max_lev) {
        freq_by_level <- stats::tapply(df[[freq_col]], df[[v]], base::sum)
        top_levels <- base::names(base::sort(freq_by_level, decreasing = TRUE))[base::seq_len(max_lev)]
        df[[v]] <- base::ifelse(base::as.character(df[[v]]) %in% top_levels,
          base::as.character(df[[v]]), "Other"
        )
        df[[v]] <- base::factor(df[[v]])
        base::message("[INFO] Variable '", v, "' trimmed to top ", max_lev, " levels + Other")
      }
    }
  }

  fml_main <- stats::as.formula(base::paste(freq_col, "~", base::paste(vars, collapse = " + ")))
  fml_2way <- stats::as.formula(base::paste(freq_col, "~ (", base::paste(vars, collapse = " + "), ")^2"))
  fml_sat <- stats::as.formula(base::paste(freq_col, "~", base::paste(vars, collapse = " * ")))

  fit_main <- base::tryCatch(stats::glm(fml_main, family = stats::poisson, data = df),
    error = function(e) {
      base::message("[ERROR] fit_main: ", base::conditionMessage(e))
      NULL
    }
  )
  fit_2way <- base::tryCatch(stats::glm(fml_2way, family = stats::poisson, data = df),
    error = function(e) {
      base::message("[ERROR] fit_2way: ", base::conditionMessage(e))
      NULL
    }
  )
  fit_sat <- base::tryCatch(stats::glm(fml_sat, family = stats::poisson, data = df),
    error = function(e) {
      base::message("[ERROR] fit_sat: ", base::conditionMessage(e))
      NULL
    }
  )

  anova_res <- base::tryCatch(stats::anova(fit_main, fit_2way, fit_sat, test = "Chisq"),
    error = function(e) {
      base::message("[WARNING] anova: ", base::conditionMessage(e))
      NULL
    }
  )

  collect_res <- function(fit, label) {
    if (base::is.null(fit)) {
      return(NULL)
    }
    res_df <- df
    res_df$model_type <- label
    res_df$pearson_res <- stats::residuals(fit, type = "pearson")
    res_df$abs_pearson_res <- base::abs(res_df$pearson_res)
    res_df$cell_label <- base::apply(res_df[, vars, drop = FALSE], 1, base::paste, collapse = ":")
    return(res_df)
  }

  res_main <- collect_res(fit_main, "Main")
  res_2way <- collect_res(fit_2way, "2-Way")
  res_combined <- base::rbind(res_main, res_2way)
  utils::write.csv(res_combined, base::file.path(
    output_dir,
    base::paste0("residuals_", data_label, ".csv")
  ), row.names = FALSE)

  top_n <- 20
  sig_compact <- base::rbind(
    utils::head(res_main[base::order(-res_main$abs_pearson_res), ], top_n),
    utils::head(res_2way[base::order(-res_2way$abs_pearson_res), ], top_n)
  )
  sig_compact <- sig_compact[!base::duplicated(
    base::paste(sig_compact$model_type, sig_compact$cell_label)
  ), ]
  utils::write.csv(sig_compact, base::file.path(
    output_dir,
    base::paste0("residuals_", data_label, "_significant.csv")
  ), row.names = FALSE)

  tab <- stats::xtabs(stats::as.formula(
    base::paste(freq_col, "~", base::paste(vars, collapse = " + "))
  ), data = df)

  anova_p <- if (!base::is.null(anova_res)) anova_res$`Pr(>Chi)`[2] else NA

  strata_info <- NULL
  if (base::length(vars) >= 3) {
    strata_var <- vars[3]
    strata_levels <- base::levels(base::factor(df[[strata_var]]))
    max_res_per <- base::sapply(strata_levels, function(lv) {
      sub <- res_main[res_main[[strata_var]] == lv, ]
      if (base::nrow(sub) == 0) {
        return(NA)
      }
      base::max(sub$abs_pearson_res, na.rm = TRUE)
    })
    cv_per <- base::sapply(strata_levels, function(lv) {
      sub_tab <- stats::xtabs(
        stats::as.formula(
          base::paste(freq_col, "~", base::paste(vars[1:2], collapse = " + "))
        ),
        data = df[df[[strata_var]] == lv, ]
      )
      base::tryCatch(vcd::assocstats(sub_tab)$cramer, error = function(e) NA)
    })
    n_sig_5 <- base::sum(res_combined$abs_pearson_res >= 1.96, na.rm = TRUE)
    n_sig_1 <- base::sum(res_combined$abs_pearson_res >= 2.58, na.rm = TRUE)
    strata_info <- base::list(
      strata_var = strata_var, n_strata = base::length(strata_levels),
      max_abs_res_per_stratum = base::as.list(max_res_per),
      cramers_v_per_stratum = base::as.list(cv_per),
      n_significant_cells_5pct = n_sig_5,
      n_significant_cells_1pct = n_sig_1,
      total_cells = base::nrow(res_combined)
    )
  }

  summary_obj <- base::list(
    interface_version = "2.1",
    test_used = "stats::anova (Poisson GLM)",
    models_tested = c("Main Effects", "2-way Interactions"),
    deviance_main = if (!base::is.null(fit_main)) fit_main$deviance else NA,
    df_main = if (!base::is.null(fit_main)) fit_main$df.residual else NA,
    deviance_2way = if (!base::is.null(fit_2way)) fit_2way$deviance else NA,
    df_2way = if (!base::is.null(fit_2way)) fit_2way$df.residual else NA,
    p_value_main_vs_2way = anova_p,
    cramers_v_marginal = base::tryCatch(
      vcd::assocstats(base::margin.table(tab, c(1, 2)))$cramer,
      error = function(e) NA
    ),
    top_residuals_main = if (!base::is.null(res_main)) {
      idx <- utils::head(base::order(-res_main$abs_pearson_res), 5)
      base::lapply(idx, function(i) base::list(cell = res_main$cell_label[i], res = res_main$pearson_res[i]))
    } else {
      NULL
    },
    top_residuals_2way = if (!base::is.null(res_2way)) {
      idx <- utils::head(base::order(-res_2way$abs_pearson_res), 5)
      base::lapply(idx, function(i) base::list(cell = res_2way$cell_label[i], res = res_2way$pearson_res[i]))
    } else {
      NULL
    },
    strata_summary = strata_info
  )
  jsonlite::write_json(summary_obj, base::file.path(
    output_dir,
    base::paste0("summary_", data_label, ".json")
  ), auto_unbox = TRUE, pretty = TRUE)

  base::message("[DATA] JSON/CSV written for: ", data_label)
  return(base::list(
    df = df, tab = tab, res_main = res_main, res_2way = res_2way,
    fit_main = fit_main, fit_2way = fit_2way
  ))
}

# ============================================================
# generate_gt_matrix: Pass 2 - gt pivot residual matrix
# ============================================================
generate_gt_matrix <- function(res_df, vars, freq_col = "Freq",
                               output_dir, config, data_label = "data") {
  gm_vars <- config$gt_matrix_vars
  row_idx <- if (!base::is.null(gm_vars) && base::length(gm_vars) >= 2) gm_vars[[1]] else 1L
  col_idx <- if (!base::is.null(gm_vars) && base::length(gm_vars) >= 2) gm_vars[[2]] else 2L
  row_idx <- base::min(base::max(row_idx, 1L), base::length(vars))
  col_idx <- base::min(base::max(col_idx, 1L), base::length(vars))
  row_var <- vars[row_idx]
  col_var <- vars[col_idx]

  build_matrix <- function(sub_df, suffix) {
    agg <- stats::aggregate(
      stats::as.formula(base::paste("pearson_res ~", row_var, "+", col_var)),
      data = sub_df, FUN = base::mean
    )
    wide <- stats::reshape(agg,
      idvar = row_var, timevar = col_var,
      direction = "wide"
    )
    base::names(wide) <- base::gsub("^pearson_res\\.", "", base::names(wide))
    row_names <- wide[[row_var]]
    wide[[row_var]] <- NULL

    mx <- base::max(base::abs(base::unlist(wide)), na.rm = TRUE)
    if (!base::is.finite(mx) || mx < 1e-12) mx <- 1

    tbl <- gt::gt(base::cbind(data.frame(V1 = row_names), wide),
      rowname_col = "V1"
    ) |>
      gt::fmt_number(decimals = 3) |>
      gt::data_color(
        columns = base::names(wide),
        domain = c(-mx, mx), palette = c("#D73027", "#FFFFFF", "#4575B4")
      ) |>
      gt::tab_header(title = base::paste("Pearson Residuals:", suffix)) |>
      gt::tab_stubhead(label = row_var) |>
      gt::tab_style(
        style = gt::cell_borders(sides = "all", weight = gt::px(2), color = "#333333"),
        locations = gt::cells_body(
          columns = base::names(wide),
          rows = base::apply(wide, 1, function(r) base::any(base::abs(r) >= 1.96, na.rm = TRUE))
        )
      )
    fname <- base::paste0("matrix_", suffix, ".html")
    gt::gtsave(tbl, base::file.path(output_dir, fname))
    base::message("[GT] ", fname)
  }

  main_df <- res_df[res_df$model_type == "Main", ]
  build_matrix(main_df, base::paste0("marginal_", data_label))

  if (base::length(vars) >= 3) {
    strata_var <- vars[3]
    strata_to_render <- if (!base::is.null(config$strata_to_render) &&
      base::length(config$strata_to_render) > 0) {
      config$strata_to_render
    } else {
      base::levels(base::factor(main_df[[strata_var]]))
    }
    for (lv in strata_to_render) {
      sub <- main_df[main_df[[strata_var]] == lv, ]
      if (base::nrow(sub) > 0) {
        build_matrix(sub, base::paste0(data_label, "_", lv))
      }
    }
  }
}

# ============================================================
# generate_dt_table: Pass 2 - DT interactive residual table
# ============================================================
generate_dt_table <- function(res_df, vars, output_dir, config, data_label = "data") {
  display_cols <- c(vars, "Freq", "pearson_res", "abs_pearson_res", "model_type")
  dt_df <- res_df[, display_cols, drop = FALSE]
  dt_df <- dt_df[base::order(-dt_df$abs_pearson_res), ]

  mx <- base::max(dt_df$abs_pearson_res, na.rm = TRUE)
  if (!base::is.finite(mx) || mx < 1e-12) mx <- 1

  n_brk <- 100
  cuts <- base::seq(-mx, mx, length.out = n_brk + 1)
  cuts_inner <- cuts[-c(1, base::length(cuts))]
  clrs <- grDevices::colorRampPalette(c("#D73027", "#FFFFFF", "#4575B4"))(base::length(cuts_inner) + 1)

  widget <- DT::datatable(dt_df,
    filter = "top",
    options = base::list(
      pageLength = 50,
      order = base::list(base::list(
        base::which(base::names(dt_df) == "abs_pearson_res") - 1, "desc"
      )),
      dom = "lftipr"
    ),
    caption = base::paste("Pearson Residuals:", data_label, "| Click headers to sort")
  ) |>
    DT::formatRound(columns = c("pearson_res", "abs_pearson_res"), digits = 3) |>
    DT::formatStyle("pearson_res",
      backgroundColor = DT::styleInterval(cuts_inner, clrs)
    )

  fname <- base::paste0("dt_residuals_", data_label, ".html")
  htmlwidgets::saveWidget(widget, base::file.path(
    base::normalizePath(output_dir), fname
  ), selfcontained = TRUE)
  base::message("[DT] ", fname)
}

# ============================================================
# generate_plots: Pass 2 - Mosaic / Association PNG
# ============================================================
generate_plots <- function(tab, vars, output_dir, config, data_label = "data") {
  pm <- if (!base::is.null(config$plot_mode)) config$plot_mode else "auto"

  should_render <- if (base::identical(pm, "always")) {
    TRUE
  } else if (base::identical(pm, "residual_only")) {
    FALSE
  } else {
    total_cells <- base::prod(base::dim(tab))
    max_label <- base::max(base::nchar(base::unlist(base::dimnames(tab))), na.rm = TRUE)
    threshold_cells <- if (base::length(vars) == 2) 16L else 36L
    total_cells <= threshold_cells && max_label <= 24L
  }

  if (should_render) {
    grDevices::png(base::file.path(output_dir, base::paste0("mosaic_", data_label, ".png")),
      width = 1000, height = 800
    )
    vcd::mosaic(tab,
      shade = TRUE,
      main = base::paste("Mosaic:", base::paste(vars, collapse = " x "))
    )
    grDevices::dev.off()

    if (base::length(vars) == 2) {
      grDevices::png(base::file.path(output_dir, base::paste0("assoc_", data_label, ".png")),
        width = 1000, height = 800
      )
      vcd::assoc(tab,
        residuals_type = "Pearson", shade = TRUE,
        main = base::paste("Association:", base::paste(vars, collapse = " x "))
      )
      grDevices::dev.off()
    }

    if (base::length(vars) >= 3) {
      grDevices::png(base::file.path(output_dir, base::paste0("cotab_", data_label, ".png")),
        width = 1000, height = 800
      )
      vcd::cotabplot(tab,
        panel = vcd::cotab_mosaic, shade = TRUE,
        main = base::paste("Conditional mosaic (by", vars[3], ")")
      )
      grDevices::dev.off()
    }
    base::message("[PLOTS] PNG files written for: ", data_label)
  } else {
    base::message(
      "[PLOTS] Skipped (plot_mode=", pm,
      ", cells=", base::prod(base::dim(tab)),
      ", max_label=", base::max(base::nchar(base::unlist(base::dimnames(tab))), na.rm = TRUE), ")"
    )
  }
}

# ============================================================
# Main dispatcher
# ============================================================
output_dir <- if (!base::is.null(out_arg)) out_arg else "./skill_out/vcd_categorical/"
base::dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

input <- load_input_data(data_path, vars_str, freq_col_arg, label_arg)
df <- input$df
vars <- input$vars
freq_col <- input$freq_col
data_label <- input$data_label

base::message(
  "[INFO] data_label=", data_label, " vars=", base::paste(vars, collapse = ","),
  " freq=", freq_col, " mode=", mode
)

if (mode == "profile") {
  generate_profile(df, vars, freq_col, output_dir)
} else {
  raw_config <- if (!base::is.null(config_path) && base::file.exists(config_path)) {
    jsonlite::read_json(config_path)
  } else {
    base::list()
  }
  config <- validate_config(raw_config)
  generate_profile(df, vars, freq_col, output_dir,
    config = config, out_filename = "data_profile_post.json"
  )
  result <- generate_data(df, vars, freq_col, output_dir, config, data_label)
  generate_gt_matrix(
    base::rbind(result$res_main, result$res_2way),
    vars, freq_col, output_dir, config, data_label
  )
  res_all <- base::rbind(result$res_main, result$res_2way)
  generate_dt_table(res_all, vars, output_dir, config, data_label)
  generate_plots(result$tab, vars, output_dir, config, data_label)
  base::message("[DONE] All outputs generated for: ", data_label)
}
