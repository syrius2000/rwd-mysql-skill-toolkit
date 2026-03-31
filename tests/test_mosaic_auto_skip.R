#!/usr/bin/env Rscript
# tests/test_mosaic_auto_skip.R
# should_render_mosaic() ヘルパーの単体テスト + 大テーブルで省略されることを確認
# 実行: Rscript tests/test_mosaic_auto_skip.R

pass <- 0L
fail <- 0L

check <- function(label, expr) {
  ok <- tryCatch(isTRUE(expr), error = function(e) FALSE)
  if (ok) {
    cat("[PASS]", label, "\n")
    pass <<- pass + 1L
  } else {
    cat("[FAIL]", label, "\n")
    fail <<- fail + 1L
  }
}

# ---- should_render_mosaic 関数を再定義（テンプレート外で直接テスト） ----
should_render_mosaic <- function(tbl, plot_mode = "auto",
                                 max_cells_2way = 16L,
                                 max_cells_3way = 36L,
                                 max_label_chars = 24L) {
  if (identical(plot_mode, "always")) return(TRUE)
  if (identical(plot_mode, "residual_only")) return(FALSE)
  dims <- dim(tbl)
  n_way <- length(dims)
  total_cells <- prod(dims)
  cell_limit <- if (n_way <= 2L) max_cells_2way else max_cells_3way
  if (total_cells > cell_limit) return(FALSE)
  all_labels <- unlist(dimnames(tbl))
  if (max(nchar(all_labels), na.rm = TRUE) > max_label_chars) return(FALSE)
  TRUE
}

# ---- テストケース ----

cat("=== should_render_mosaic unit tests ===\n\n")

# 2x2 (4 cells) — 描画
small_2way <- matrix(c(10, 20, 30, 40), nrow = 2,
                     dimnames = list(A = c("a1", "a2"), B = c("b1", "b2")))
check("2x2 table renders (4 <= 16)", should_render_mosaic(as.table(small_2way)))

# 3x3 (9 cells) — 描画
mid_2way <- matrix(1:9, nrow = 3,
                   dimnames = list(A = c("a1", "a2", "a3"), B = c("b1", "b2", "b3")))
check("3x3 table renders (9 <= 16)", should_render_mosaic(as.table(mid_2way)))

# 4x4 (16 cells) — 境界値: 描画
border_2way <- matrix(1:16, nrow = 4,
                      dimnames = list(A = paste0("a", 1:4), B = paste0("b", 1:4)))
check("4x4 table renders (16 <= 16)", should_render_mosaic(as.table(border_2way)))

# 5x5 (25 cells) — 省略
large_2way <- matrix(1:25, nrow = 5,
                     dimnames = list(A = paste0("a", 1:5), B = paste0("b", 1:5)))
check("5x5 table skipped (25 > 16)", !should_render_mosaic(as.table(large_2way)))

# 3-way: 2x2x6 = 24 cells — 描画
small_3way <- array(1:24, dim = c(2, 2, 6),
                    dimnames = list(A = c("a1", "a2"), B = c("b1", "b2"),
                                    C = paste0("c", 1:6)))
check("2x2x6 3-way renders (24 <= 36)", should_render_mosaic(as.table(small_3way)))

# 3-way: 4x4x3 = 48 cells — 省略
large_3way <- array(1:48, dim = c(4, 4, 3),
                    dimnames = list(A = paste0("a", 1:4), B = paste0("b", 1:4),
                                    C = paste0("c", 1:3)))
check("4x4x3 3-way skipped (48 > 36)", !should_render_mosaic(as.table(large_3way)))

# ラベル長が長い (> 24 chars) — 省略
long_label_2way <- matrix(c(10, 20, 30, 40), nrow = 2,
                          dimnames = list(
                            A = c("very_long_category_label_A1", "short"),
                            B = c("b1", "b2")))
check("long label skipped (26 > 24 chars)", !should_render_mosaic(as.table(long_label_2way)))

# plot_mode = "always" — 大テーブルでも描画
check("always mode renders even 5x5", should_render_mosaic(as.table(large_2way), plot_mode = "always"))

# plot_mode = "residual_only" — 小テーブルでも省略
check("residual_only mode skips 2x2", !should_render_mosaic(as.table(small_2way), plot_mode = "residual_only"))

# ---- residual_plot_mode unit tests ----

cat("\n=== residual_plot_mode unit tests ===\n\n")

residual_plot_mode <- function(tbl, max_cells_dotplot = 25L) {
  dims <- dim(tbl)
  n_way <- length(dims)
  total_cells <- prod(dims)
  if (total_cells <= max_cells_dotplot) return("dotplot")
  if (n_way <= 2L) return("heatmap")
  "facet_heatmap"
}

# 2x2 (4 cells) → dotplot
check("rp_mode: 2x2 → dotplot", residual_plot_mode(as.table(small_2way)) == "dotplot")

# 5x5 (25 cells) → dotplot (boundary)
check("rp_mode: 5x5 → dotplot (25 <= 25)", residual_plot_mode(as.table(large_2way)) == "dotplot")

# 6x5 (30 cells) → heatmap
large_6x5 <- matrix(1:30, nrow = 6,
                     dimnames = list(A = paste0("a", 1:6), B = paste0("b", 1:5)))
check("rp_mode: 6x5 → heatmap (30 > 25)", residual_plot_mode(as.table(large_6x5)) == "heatmap")

# 10x10 (100 cells) → heatmap
huge_2way <- matrix(1:100, nrow = 10,
                    dimnames = list(A = paste0("a", 1:10), B = paste0("b", 1:10)))
check("rp_mode: 10x10 → heatmap (100 > 25)", residual_plot_mode(as.table(huge_2way)) == "heatmap")

# 3-way: 2x2x6 = 24 → dotplot
check("rp_mode: 2x2x6 3-way → dotplot (24 <= 25)", residual_plot_mode(as.table(small_3way)) == "dotplot")

# 3-way: 4x4x3 = 48 → facet_heatmap
check("rp_mode: 4x4x3 3-way → facet_heatmap (48 > 25)", residual_plot_mode(as.table(large_3way)) == "facet_heatmap")

# 3-way: 10x10x6 = 600 → facet_heatmap
huge_3way <- array(1:600, dim = c(10, 10, 6),
                   dimnames = list(A = paste0("a", 1:10), B = paste0("b", 1:10),
                                   C = paste0("c", 1:6)))
check("rp_mode: 10x10x6 → facet_heatmap (600 > 25)", residual_plot_mode(as.table(huge_3way)) == "facet_heatmap")

# custom threshold: max_cells_dotplot = 10 → 4x4 (16) becomes heatmap
check("rp_mode: custom thresh 10, 4x4 → heatmap", residual_plot_mode(as.table(border_2way), max_cells_dotplot = 10L) == "heatmap")

cat("\n===============================\n")
cat(sprintf("Results: %d passed, %d failed\n", pass, fail))
if (fail > 0L) quit(status = 1L) else quit(status = 0L)
