# Minimal categorical pipeline (nominal, up to 3-way). Copy to project and edit paths/vars.
# Outputs under ./skill_out/vcd_categorical/

output_dir <- "./skill_out/vcd_categorical/"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- Packages: prefer pacman in interactive env; offline use library() + manual install ---
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(datasets, vcd, gt, ggplot2)

# --- Example: 2-way (Titanic) ---
data("Titanic", package = "datasets")
df <- as.data.frame(Titanic)
tab <- xtabs(Freq ~ Class + Survived, data = df)

print(tab)
ct <- chisq.test(tab)
print(ct)

png(file.path(output_dir, "mosaic_titanic.png"), width = 800, height = 600)
mosaic(tab, shade = TRUE, main = "Titanic Class x Survived")
dev.off()

png(file.path(output_dir, "assoc_titanic.png"), width = 800, height = 600)
assoc(tab, residuals_type = "Pearson", shade = TRUE, main = "Association (Pearson, shaded)")
dev.off()

res <- ct$residuals
longdf <- as.data.frame(as.table(res))
names(longdf) <- c("Var1", "Var2", "pearson_res")
mx <- max(abs(longdf$pearson_res), na.rm = TRUE)
if (!is.finite(mx) || mx < 1e-12) mx <- 1

tbl <- gt::gt(longdf) |>
  gt::fmt_number(columns = pearson_res, decimals = 3) |>
  gt::data_color(
    columns = pearson_res,
    domain = c(-mx, mx),
    palette = "RdBu"
  )
gt::gtsave(tbl, file.path(output_dir, "residuals_titanic.html"))

# --- Poisson loglinear (2-way) ---
fit <- glm(Freq ~ Class * Survived, family = poisson, data = df)
print(summary(fit))

# --- Example: 3-way (HairEyeColor) ---
data("HairEyeColor", package = "datasets")
df3 <- as.data.frame(HairEyeColor)
tab3 <- xtabs(Freq ~ Hair + Eye + Sex, data = df3)

png(file.path(output_dir, "mosaic_haireye.png"), width = 800, height = 600)
mosaic(tab3, shade = TRUE, main = "HairEyeColor 3-way")
dev.off()

png(file.path(output_dir, "cotab_haireye.png"), width = 800, height = 600)
vcd::cotabplot(tab3, panel = vcd::cotab_mosaic, shade = TRUE, main = "Conditional mosaic (by Sex)")
dev.off()

# Poisson loglinear (3-way)
fit3_sat <- glm(Freq ~ Hair * Eye * Sex, family = poisson, data = df3)
fit3_ind <- glm(Freq ~ Hair + Eye + Sex, family = poisson, data = df3)
print(anova(fit3_ind, fit3_sat, test = "Chisq"))

# 残差プロット（3-way 用）
res_df3 <- data.frame(
  pearson_res = residuals(fit3_ind, type = "pearson"),
  df3
)
res_df3$cell_label <- apply(res_df3[, c("Hair", "Eye", "Sex"), drop = FALSE],
                            1, paste, collapse = ":")
# 長いラベルの折り返し
res_df3$cell_label_wrap <- sapply(res_df3$cell_label, function(x) {
  paste(strwrap(x, width = 15), collapse = "\n")
})
png(file.path(output_dir, "residual_plot.png"), width = 1000, height = 800)
ggplot2::ggplot(res_df3, ggplot2::aes(x = reorder(cell_label_wrap, seq_len(nrow(res_df3))),
                    y = pearson_res, color = Hair)) +
  ggplot2::geom_point(size = 3) +
  ggplot2::geom_hline(yintercept = c(-1.96, 1.96), linetype = "dashed",
             color = "grey50") +
  ggplot2::coord_flip() +
  ggplot2::labs(title = "Pearson residuals (independence loglinear)",
       x = "Hair : Eye : Sex", y = "Pearson residual", color = "Hair") +
  ggplot2::theme_minimal(base_size = 13) +
  ggplot2::theme(axis.text.y = ggplot2::element_text(size = 10))
dev.off()
