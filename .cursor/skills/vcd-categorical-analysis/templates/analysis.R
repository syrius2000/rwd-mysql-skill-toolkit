# Minimal categorical pipeline (nominal, up to 3-way). Copy to project and edit paths/vars.
# Outputs under ./skill_out/vcd_categorical/
# AI-Pipeline mode: each result is saved as JSON/CSV for AI evaluation

output_dir <- "./skill_out/vcd_categorical/"
base::dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- Packages ---
if (!base::requireNamespace("pacman", quietly = TRUE)) utils::install.packages("pacman")
pacman::p_load(datasets, vcd, gt, ggplot2, jsonlite)

# --- Example: 2-way (Titanic) ---
base::data("Titanic", package = "datasets")
df <- base::as.data.frame(Titanic)
tab <- stats::xtabs(Freq ~ Class + Survived, data = df)

base::print(tab)
ct <- stats::chisq.test(tab)
base::print(ct)

grDevices::png(base::file.path(output_dir, "mosaic_titanic.png"), width = 800, height = 600)
vcd::mosaic(tab, shade = TRUE, main = "Titanic Class x Survived")
grDevices::dev.off()

grDevices::png(base::file.path(output_dir, "assoc_titanic.png"), width = 800, height = 600)
vcd::assoc(tab, residuals_type = "Pearson", shade = TRUE, main = "Association (Pearson, shaded)")
grDevices::dev.off()

res <- ct$residuals
longdf <- base::as.data.frame(base::as.table(res))
base::names(longdf) <- c("Var1", "Var2", "pearson_res")
longdf$abs_pearson_res <- base::abs(longdf$pearson_res)
longdf <- longdf[base::order(-longdf$abs_pearson_res), ]
mx <- base::max(longdf$abs_pearson_res, na.rm = TRUE)
if (!base::is.finite(mx) || mx < 1e-12) mx <- 1

tbl <- gt::gt(longdf) |>
  gt::fmt_number(columns = pearson_res, decimals = 3) |>
  gt::data_color(
    columns = pearson_res,
    domain = c(-mx, mx),
    palette = "RdBu"
  )
gt::gtsave(tbl, base::file.path(output_dir, "residuals_titanic.html"))

# AI評価用：CSVとJSONの出力
utils::write.csv(longdf, base::file.path(output_dir, "residuals_titanic.csv"), row.names = FALSE)
ast_res <- base::suppressWarnings(vcd::assocstats(tab))
titanic_summary <- base::list(
  test_used = "stats::chisq.test",
  statistic = base::unname(ct$statistic),
  p_value = ct$p.value,
  cramers_v = ast_res$cramer,
  max_residual_cell = base::paste(longdf[1, c("Var1", "Var2")], collapse = ":"),
  max_residual_value = longdf$abs_pearson_res[1]
)
jsonlite::write_json(titanic_summary, base::file.path(output_dir, "summary_titanic.json"), auto_unbox = TRUE)

# --- Poisson loglinear (2-way) ---
fit <- base::tryCatch(
  stats::glm(Freq ~ Class * Survived, family = stats::poisson, data = df),
  error = function(e) { base::message("[ERROR] glm fit failed: ", base::conditionMessage(e)); NULL }
)
if (!base::is.null(fit)) base::print(base::summary(fit))

# --- Example: 3-way (HairEyeColor) ---
base::data("HairEyeColor", package = "datasets")
df3 <- base::as.data.frame(HairEyeColor)
vars3 <- c("Hair", "Eye", "Sex")
tab3 <- stats::xtabs(Freq ~ Hair + Eye + Sex, data = df3)

grDevices::png(base::file.path(output_dir, "mosaic_haireye.png"), width = 800, height = 600)
vcd::mosaic(tab3, shade = TRUE, main = "HairEyeColor 3-way")
grDevices::dev.off()

grDevices::png(base::file.path(output_dir, "cotab_haireye.png"), width = 800, height = 600)
vcd::cotabplot(tab3, panel = vcd::cotab_mosaic, shade = TRUE, main = "Conditional mosaic (by Sex)")
grDevices::dev.off()

# 2段階ポアソンモデル (Phase 1: 主効果のみ, Phase 2: 2-way交互作用)
fit3_ind <- base::tryCatch(
  stats::glm(Freq ~ Hair + Eye + Sex, family = stats::poisson, data = df3),
  error = function(e) { base::message("[ERROR] fit3_ind failed: ", base::conditionMessage(e)); NULL }
)
fit3_2way <- base::tryCatch(
  stats::glm(Freq ~ (Hair + Eye + Sex)^2, family = stats::poisson, data = df3),
  error = function(e) { base::message("[ERROR] fit3_2way failed: ", base::conditionMessage(e)); NULL }
)
fit3_sat <- base::tryCatch(
  stats::glm(Freq ~ Hair * Eye * Sex, family = stats::poisson, data = df3),
  error = function(e) { base::message("[ERROR] fit3_sat failed: ", base::conditionMessage(e)); NULL }
)

anova_res <- base::tryCatch(
  stats::anova(fit3_ind, fit3_2way, fit3_sat, test = "Chisq"),
  error = function(e) {
    base::message("[WARNING] stats::anova failed (possibly sparse data): ", base::conditionMessage(e))
    NULL
  }
)
if (!base::is.null(anova_res)) base::print(anova_res)

# 残差データの回収 (Main & 2-Way)
collect_res <- function(fit, label, vars) {
  if (base::is.null(fit)) return(NULL)
  d <- base::as.data.frame(base::as.table(stats::xtabs(base::stats::formula(fit), data = df3)))
  # Note: xtabs(formula(fit)) matches the data structure of fit's response
  # However, it's safer to use the original df3 with residual values
  res_df <- df3
  res_df$model_type <- label
  res_df$pearson_res <- stats::residuals(fit, type = "pearson")
  res_df$abs_pearson_res <- base::abs(res_df$pearson_res)
  res_df$cell_label <- base::apply(res_df[, vars, drop = FALSE], 1, base::paste, collapse = ":")
  return(res_df)
}

res_main <- collect_res(fit3_ind, "Main", vars3)
res_2way <- collect_res(fit3_2way, "2-Way", vars3)
res_combined <- base::rbind(res_main, res_2way)

# AI評価用フットプリントの出力
utils::write.csv(res_combined, base::file.path(output_dir, "residuals_haireye_raw.csv"), row.names = FALSE)

# 有意または上位残差の抽出 (トークン節約)
sig_res <- res_combined[res_combined$abs_pearson_res >= 1.96, ]
sig_res <- sig_res[base::order(-sig_res$abs_pearson_res), ]
# 各モデルタイプから最低限いくつか残す
top_n <- 20
sig_compact <- base::rbind(
  utils::head(res_main[base::order(-res_main$abs_pearson_res), ], top_n),
  utils::head(res_2way[base::order(-res_2way$abs_pearson_res), ], top_n)
)
sig_compact <- sig_compact[!base::duplicated(base::paste(sig_compact$model_type, sig_compact$cell_label)), ]
utils::write.csv(sig_compact, base::file.path(output_dir, "residuals_haireye_significant.csv"), row.names = FALSE)

anova_p <- if (!base::is.null(anova_res)) anova_res$`Pr(>Chi)`[2] else NA
haireye_summary <- base::list(
  test_used = "stats::anova (Poisson GLM)",
  models_tested = c("Main Effects (A+B+C)", "All 2-way Interactions ((A+B+C)^2)"),
  deviance_main = if (!base::is.null(fit3_ind)) fit3_ind$deviance else NA,
  df_main = if (!base::is.null(fit3_ind)) fit3_ind$df.residual else NA,
  deviance_2way = if (!base::is.null(fit3_2way)) fit3_2way$deviance else NA,
  df_2way = if (!base::is.null(fit3_2way)) fit3_2way$df.residual else NA,
  p_value_main_vs_2way = anova_p,
  cramers_v_marginal = base::suppressWarnings(vcd::assocstats(base::margin.table(tab3, c(1, 2)))$cramer),
  top_residual_main_effects = if (!base::is.null(res_main)) {
    base::list(cell = res_main$cell_label[base::which.max(res_main$abs_pearson_res)], 
               res = res_main$pearson_res[base::which.max(res_main$abs_pearson_res)])
  } else NULL,
  top_residual_2way_interactions = if (!base::is.null(res_2way)) {
    base::list(cell = res_2way$cell_label[base::which.max(res_2way$abs_pearson_res)], 
               res = res_2way$pearson_res[base::which.max(res_2way$abs_pearson_res)])
  } else NULL
)
jsonlite::write_json(haireye_summary, base::file.path(output_dir, "summary_haireye.json"), auto_unbox = TRUE)
