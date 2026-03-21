# Minimal categorical pipeline (nominal, up to 3-way). Copy to project and edit paths/vars.
# Outputs under ./skill_output/vcd_categorical/

output_dir <- "./skill_output/vcd_categorical/"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- Packages: prefer pacman in interactive env; offline use library() + manual install ---
# if (requireNamespace("pacman", quietly = TRUE)) pacman::p_load(datasets, vcd, gt)
suppressPackageStartupMessages({
  library(datasets)
  library(vcd)
  library(gt)
})

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
