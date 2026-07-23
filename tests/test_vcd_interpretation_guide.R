#!/usr/bin/env Rscript
# tests/test_vcd_interpretation_guide.R
# report.Rmd に残差解釈ガイドセクションが存在することを検証（vcd 不要）
# Run: Rscript tests/test_vcd_interpretation_guide.R

ca <- commandArgs(trailingOnly = FALSE)
f <- sub("^--file=", "", ca[startsWith(ca, "--file=")][1L])
repo <- if (is.na(f) || !nzchar(f)) {
  normalizePath(".", winslash = "/", mustWork = TRUE)
} else {
  normalizePath(file.path(dirname(f), ".."), winslash = "/", mustWork = TRUE)
}

# --- 対象: vcd-categorical-analysis report.Rmd ---
vcd_path <- file.path(repo, ".agent/skills/vcd-categorical-analysis/templates/report.Rmd")

# --- 対象: questionnaire-batch-analysis report.Rmd ---
qba_path <- file.path(repo, ".agent/skills/questionnaire-batch-analysis/templates/report.Rmd")

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

p <- vcd_path
check(paste("file exists:", basename(dirname(dirname(p)))), file.exists(p))

if (file.exists(p)) {
  lines <- readLines(p, warn = FALSE)

  # 解釈ガイドチャンクの存在
  check(
    paste("interpretation-guide chunk exists:", p),
    any(grepl("^```\\{r interpretation-guide", lines))
  )

  # ±1.96 の閾値説明が含まれる
  check(
    paste("±1.96 threshold explanation:", p),
    any(grepl("1\\.96", lines))
  )

  # ±2.58 の閾値説明が含まれる
  check(
    paste("±2.58 threshold explanation:", p),
    any(grepl("2\\.58", lines))
  )

  # 正残差・負残差の解釈が含まれる
  check(
    paste("positive/negative residual interpretation:", p),
    any(grepl("(正の残差|positive residual|期待より多)", lines, ignore.case = TRUE))
  )

  # 効果量の解釈基準
  check(
    paste("effect size interpretation guide:", p),
    any(grepl("(Cramer|効果量|effect size)", lines, ignore.case = TRUE))
  )
}

p <- qba_path
check(paste("file exists:", basename(dirname(dirname(p)))), file.exists(p))

if (file.exists(p)) {
  lines <- readLines(p, warn = FALSE)

  check(
    paste("interpretation-guide chunk exists:", p),
    any(grepl("^```\\{r interpretation-guide", lines))
  )
}

cat(sprintf("\n--- Results: %d passed, %d failed ---\n", pass, fail))
if (fail > 0L) stop("Some interpretation guide tests failed.")
message("OK: interpretation guide tests passed.")
