#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
  pacman::p_load(optparse, rmarkdown)
})

option_list <- list(
  optparse::make_option("--data", type = "character", help = "Path to survey CSV"),
  optparse::make_option("--config", type = "character", help = "Path to question_config.csv"),
  optparse::make_option("--out", type = "character", default = "./skill_out/questionnaire", help = "Output directory"),
  optparse::make_option("--run-id", type = "character", default = format(Sys.time(), "run_%Y%m%d_%H%M%S"), help = "Batch run id")
)

opt <- optparse::parse_args(optparse::OptionParser(option_list = option_list))

ca <- commandArgs(trailingOnly = FALSE)
file_arg <- ca[grep("^--file=", ca)]
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = FALSE)
} else {
  ""
}
script_dir <- if (nzchar(script_path)) dirname(script_path) else "."
report_template <- file.path(script_dir, "report.Rmd")

if (!file.exists(report_template)) {
  stop("report.Rmd not found next to batch_runner.R: ", report_template)
}

if (is.null(opt$data) || is.null(opt$config)) {
  stop("Both --data and --config are required")
}

cfg <- utils::read.csv(opt$config, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("survey_id", "question_id", "analysis_type", "var1", "var2", "output_slug")
missing_cols <- setdiff(required, names(cfg))
if (length(missing_cols) > 0) {
  stop("Missing required config columns: ", paste(missing_cols, collapse = ", "))
}

optional_defaults <- list(
  var3 = "",
  question_label = "",
  subset_expr = "",
  na_policy = "drop",
  ordered_levels = "",
  reference_note = ""
)
for (nm in names(optional_defaults)) {
  if (!nm %in% names(cfg)) {
    cfg[[nm]] <- optional_defaults[[nm]]
    next
  }

  values <- cfg[[nm]]
  values[is.na(values)] <- optional_defaults[[nm]]
  cfg[[nm]] <- as.character(values)
}

dir.create(opt$out, recursive = TRUE, showWarnings = FALSE)
opt$out <- normalizePath(opt$out, winslash = "/", mustWork = FALSE)
summary_path <- file.path(opt$out, "summary.csv")

summary_columns <- c(
  "run_id","survey_id","question_id","analysis_type","variables","subset_expr_applied",
  "na_policy","n_total","n_used","n_missing","model_name","statistic_name",
  "statistic_value","df","p_value","effect_name","effect_value","max_abs_pearson_res",
  "max_residual_cell","residual_plot_path","mosaic_plot_path","assoc_plot_path",
  "report_path","status","error_message","executed_at"
)

rows <- vector("list", nrow(cfg))
for (i in seq_len(nrow(cfg))) {
  row <- cfg[i, ]
  q_out <- file.path(opt$out, row$output_slug)
  dir.create(q_out, recursive = TRUE, showWarnings = FALSE)

  vars <- c(row$var1, row$var2)
  if (nzchar(row$var3)) vars <- c(vars, row$var3)

  report_file <- file.path(q_out, "report.html")
  residual_plot <- file.path(q_out, "figures", "residual_plot.png")
  mosaic_plot <- file.path(q_out, "figures", "mosaic_plot.png")
  assoc_plot <- file.path(q_out, "figures", "assoc_plot.png")

  status <- "success"
  error_message <- ""

  tryCatch({
    rmarkdown::render(
      input = report_template,
      output_file = "report.html",
      output_dir = q_out,
      params = list(
        data_path = opt$data,
        survey_id = row$survey_id,
        question_id = row$question_id,
        question_label = row$question_label,
        analysis_type = row$analysis_type,
        vars = vars,
        subset_expr = row$subset_expr,
        na_policy = row$na_policy,
        ordered_levels = row$ordered_levels,
        output_dir = q_out
      ),
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
  }, error = function(e) {
    status <<- "error"
    error_message <<- conditionMessage(e)
  })

  # report.Rmd が保存した計算値を回収する
  m <- list(
    n_total             = NA_integer_,
    n_used              = NA_integer_,
    n_missing           = NA_integer_,
    model_name          = "",
    statistic_name      = "",
    statistic_value     = NA_real_,
    df                  = NA_real_,
    p_value             = NA_real_,
    effect_name         = "",
    effect_value        = NA_real_,
    max_abs_pearson_res = NA_real_,
    max_residual_cell   = "",
    residual_plot_path  = residual_plot,
    mosaic_plot_path    = mosaic_plot,
    assoc_plot_path     = assoc_plot
  )
  metrics_path <- file.path(q_out, ".metrics.rds")
  if (status == "success" && file.exists(metrics_path)) {
    loaded <- tryCatch(readRDS(metrics_path), error = function(e) NULL)
    if (!is.null(loaded)) {
      for (nm in names(m)) {
        if (!is.null(loaded[[nm]])) m[[nm]] <- loaded[[nm]]
      }
    }
  }

  rows[[i]] <- data.frame(
    run_id = opt$`run-id`,
    survey_id = row$survey_id,
    question_id = row$question_id,
    analysis_type = row$analysis_type,
    variables = paste(vars, collapse = "|"),
    subset_expr_applied = row$subset_expr,
    na_policy = row$na_policy,
    n_total              = m$n_total,
    n_used               = m$n_used,
    n_missing            = m$n_missing,
    model_name           = m$model_name,
    statistic_name       = m$statistic_name,
    statistic_value      = m$statistic_value,
    df                   = m$df,
    p_value              = m$p_value,
    effect_name          = m$effect_name,
    effect_value         = m$effect_value,
    max_abs_pearson_res  = m$max_abs_pearson_res,
    max_residual_cell    = m$max_residual_cell,
    residual_plot_path   = m$residual_plot_path,
    mosaic_plot_path     = m$mosaic_plot_path,
    assoc_plot_path      = m$assoc_plot_path,
    report_path = report_file,
    status = status,
    error_message = error_message,
    executed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    stringsAsFactors = FALSE
  )
}

summary_df <- do.call(rbind, rows)
summary_df <- summary_df[, summary_columns, drop = FALSE]
utils::write.csv(summary_df, summary_path, row.names = FALSE, na = "")

cat("Completed. Summary:", summary_path, "\n")
