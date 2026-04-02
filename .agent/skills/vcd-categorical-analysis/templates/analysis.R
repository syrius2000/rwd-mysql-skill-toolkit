# Minimal categorical pipeline (nominal, up to 3-way). Copy to project and edit paths/vars.
# Outputs under ./skill_out/vcd_categorical/
# AI-Pipeline mode: each result is saved as JSON/CSV for AI evaluation

output_dir <- "./skill_out/vcd_categorical/"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- Packages ---
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(datasets, vcd, gt, ggplot2, jsonlite)

# --- Example: 2-way (Titanic) ---
data("Titanic", package = "datasets")
df <- as.data.frame(Titanic)
tab <- xtabs(Freq ~ Class + Survived, data = df)

print(tab)
ct <- stats::chisq.test(tab)
print(ct)

grDevices::png(file.path(output_dir, "mosaic_titanic.png"), width = 800, height = 600)
vcd::mosaic(tab, shade = TRUE, main = "Titanic Class x Survived")
grDevices::dev.off()

grDevices::png(file.path(output_dir, "assoc_titanic.png"), width = 800, height = 600)
vcd::assoc(tab, residuals_type = "Pearson", shade = TRUE, main = "Association (Pearson, shaded)")
grDevices::dev.off()

res <- ct$residuals
longdf <- as.data.frame(as.table(res))
names(longdf) <- c("Var1", "Var2", "pearson_res")
longdf$abs_pearson_res <- abs(longdf$pearson_res)
longdf <- longdf[order(-longdf$abs_pearson_res), ]
mx <- max(longdf$abs_pearson_res, na.rm = TRUE)
if (!is.finite(mx) || mx < 1e-12) mx <- 1

tbl <- gt::gt(longdf) |>
  gt::fmt_number(columns = pearson_res, decimals = 3) |>
  gt::data_color(
    columns = pearson_res,
    domain = c(-mx, mx),
    palette = "RdBu"
  )
gt::gtsave(tbl, file.path(output_dir, "residuals_titanic.html"))

# AI評価用：CSVとJSONの出力（namespace::function 形式統一）
utils::write.csv(longdf, file.path(output_dir, "residuals_titanic.csv"), row.names = FALSE)
ast_res <- suppressWarnings(vcd::assocstats(tab))
titanic_summary <- list(
  test_used = "stats::chisq.test",
  statistic = ct$statistic,
  p_value = ct$p.value,
  cramers_v = ast_res$cramer,
  max_residual_cell = paste(longdf[1, c("Var1", "Var2")], collapse = ":"),
  max_residual_value = longdf$abs_pearson_res[1]
)
jsonlite::write_json(titanic_summary, file.path(output_dir, "summary_titanic.json"), auto_unbox = TRUE)

# --- Poisson loglinear (2-way) ---
fit <- stats::glm(Freq ~ Class * Survived, family = stats::poisson, data = df)
print(summary(fit))

# --- Example: 3-way (HairEyeColor) ---
data("HairEyeColor", package = "datasets")
df3 <- as.data.frame(HairEyeColor)
tab3 <- xtabs(Freq ~ Hair + Eye + Sex, data = df3)

grDevices::png(file.path(output_dir, "mosaic_haireye.png"), width = 800, height = 600)
vcd::mosaic(tab3, shade = TRUE, main = "HairEyeColor 3-way")
grDevices::dev.off()

grDevices::png(file.path(output_dir, "cotab_haireye.png"), width = 800, height = 600)
vcd::cotabplot(tab3, panel = vcd::cotab_mosaic, shade = TRUE, main = "Conditional mosaic (by Sex)")
grDevices::dev.off()

# 2段階ポアソンモデル (Phase 1: 主効果のみ, Phase 2: 2-way交互作用)
fit3_ind <- stats::glm(Freq ~ Hair + Eye + Sex, family = stats::poisson, data = df3)
fit3_2way <- stats::glm(Freq ~ (Hair + Eye + Sex)^2, family = stats::poisson, data = df3)
fit3_sat  <- stats::glm(Freq ~ Hair * Eye * Sex,   family = stats::poisson, data = df3)

anova_res <- tryCatch(
  stats::anova(fit3_ind, fit3_2way, fit3_sat, test = "Chisq"),
  error = function(e) {
    message("[WARNING] stats::anova failed (possibly sparse data): ", conditionMessage(e))
    NULL
  }
)
if (!is.null(anova_res)) print(anova_res)

# 残差プロット（主効果モデルを提示用として固定）
res_df3 <- data.frame(
  pearson_res = stats::residuals(fit3_ind, type = "pearson"),
  df3
)
res_df3$cell_label <- apply(res_df3[, c("Hair", "Eye", "Sex"), drop = FALSE],
                            1, paste, collapse = ":")
res_df3$abs_pearson_res <- abs(res_df3$pearson_res)
res_df3 <- res_df3[order(-res_df3$abs_pearson_res), ]

res_df3$cell_label_wrap <- sapply(res_df3$cell_label, function(x) {
  paste(strwrap(x, width = 15), collapse = "\n")
})
grDevices::png(file.path(output_dir, "residual_plot.png"), width = 1000, height = 800)
ggplot2::ggplot(res_df3, ggplot2::aes(x = reorder(cell_label_wrap, seq_len(nrow(res_df3))),
                    y = pearson_res, color = Hair)) +
  ggplot2::geom_point(size = 3) +
  ggplot2::geom_hline(yintercept = c(-1.96, 1.96), linetype = "dashed",
             color = "grey50") +
  ggplot2::coord_flip() +
  ggplot2::labs(title = "Pearson residuals (Main Effects model: Hair+Eye+Sex)",
       x = "Hair : Eye : Sex", y = "Pearson residual", color = "Hair") +
  ggplot2::theme_minimal(base_size = 13) +
  ggplot2::theme(axis.text.y = ggplot2::element_text(size = 10))
grDevices::dev.off()

# AI評価用：全件CSV(生) + 有意セルのみCSV + JSON出力
utils::write.csv(res_df3, file.path(output_dir, "residuals_haireye_raw.csv"), row.names = FALSE)
sig_df3 <- res_df3[res_df3$abs_pearson_res >= 1.96, ]
utils::write.csv(sig_df3, file.path(output_dir, "residuals_haireye_significant.csv"), row.names = FALSE)

anova_p <- if (!is.null(anova_res)) anova_res$`Pr(>Chi)`[2] else NA
haireye_summary <- list(
  test_used = "stats::anova (Poisson GLM)",
  models_tested = c("Main Effects (Hair+Eye+Sex)", "2-way Interactions ((Hair+Eye+Sex)^2)", "Saturated"),
  deviance_main = fit3_ind$deviance,
  df_main = fit3_ind$df.residual,
  deviance_2way = fit3_2way$deviance,
  df_2way = fit3_2way$df.residual,
  p_value_main_vs_2way = anova_p,
  cramers_v_marginal = suppressWarnings(vcd::assocstats(stats::margin.table(tab3, c(1, 2)))$cramer),
  top_residual_main = list(
    cell = res_df3$cell_label[1],
    res  = res_df3$pearson_res[1],
    abs  = res_df3$abs_pearson_res[1]
  )
)
jsonlite::write_json(haireye_summary, file.path(output_dir, "summary_haireye.json"), auto_unbox = TRUE)
