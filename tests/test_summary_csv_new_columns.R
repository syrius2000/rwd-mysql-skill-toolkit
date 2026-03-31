#!/usr/bin/env Rscript
# tests/test_summary_csv_new_columns.R
# summary.csv に新規カラム (n_significant_cells, n_total_cells,
# top3_residual_cells, interpretation_flag) が存在し値が妥当であることを検証
# 前提: test_questionnaire_batch_ucbadmissions.R が先に実行されていること
# Run: Rscript tests/test_summary_csv_new_columns.R

suppressPackageStartupMessages({
  if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
  pacman::p_load(datasets)
})

ca <- commandArgs(trailingOnly = FALSE)
fa <- ca[grep("^--file=", ca)]
root <- if (length(fa) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", fa[1]))))
} else {
  getwd()
}

runner_path <- file.path(
  root, ".agent", "skills",
  "questionnaire-batch-analysis", "templates", "batch_runner.R"
)
tmp_dir <- file.path(tempdir(), "summary_csv_test")
dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
out_dir <- file.path(tmp_dir, "output")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# UCBAdmissions データ作成
data_path <- file.path(tmp_dir, "ucbadmissions.csv")
ucb <- as.data.frame(UCBAdmissions)
expanded <- ucb[rep(seq_len(nrow(ucb)), ucb$Freq), c("Admit", "Gender", "Dept")]
utils::write.csv(expanded, data_path, row.names = FALSE, quote = TRUE)

config_path <- file.path(tmp_dir, "config.csv")
config_lines <- c(
  "survey_id,question_id,analysis_type,var1,var2,var3,output_slug,question_label,subset_expr,na_policy,ordered_levels,reference_note",
  "ucb,q01,nominal_2way,Admit,Gender,,q01_admit_gender,Admit x Gender,,drop,,2-way",
  "ucb,q02,nominal_3way,Admit,Gender,Dept,q02_admit_gender_dept,Admit x Gender x Dept,,drop,,3-way"
)
writeLines(config_lines, config_path, useBytes = TRUE)

cmd <- sprintf(
  'cd "%s" && Rscript --vanilla "%s" --data "%s" --config "%s" --out "%s" --run-id summary_test',
  root, runner_path, data_path, config_path, out_dir
)
cat("Running:", cmd, "\n\n")
ret <- system(cmd)

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

check("batch_runner exit 0", ret == 0L)

summary_csv <- file.path(out_dir, "summary.csv")
check("summary.csv exists", file.exists(summary_csv))

if (file.exists(summary_csv)) {
  s <- read.csv(summary_csv, stringsAsFactors = FALSE, na.strings = "")

  # 新規カラムの存在チェック
  new_cols <- c("n_significant_cells", "n_total_cells", "top3_residual_cells", "interpretation_flag")
  for (col in new_cols) {
    check(paste("column exists:", col), col %in% names(s))
  }

  # 値の妥当性チェック
  if ("n_significant_cells" %in% names(s)) {
    check("n_significant_cells is non-negative integer",
          all(!is.na(s$n_significant_cells)) && all(s$n_significant_cells >= 0))
  }

  if ("n_total_cells" %in% names(s)) {
    check("n_total_cells is positive integer",
          all(!is.na(s$n_total_cells)) && all(s$n_total_cells > 0))
    # 2-way: Admit(2) x Gender(2) = 4, 3-way: Admit(2) x Gender(2) x Dept(6) = 24
    check("n_total_cells q01 = 4", s$n_total_cells[s$question_id == "q01"] == 4L)
    check("n_total_cells q02 = 24", s$n_total_cells[s$question_id == "q02"] == 24L)
  }

  if ("n_significant_cells" %in% names(s) && "n_total_cells" %in% names(s)) {
    check("n_significant_cells <= n_total_cells",
          all(s$n_significant_cells <= s$n_total_cells))
  }

  if ("top3_residual_cells" %in% names(s)) {
    check("top3_residual_cells is non-empty string",
          all(!is.na(s$top3_residual_cells)) && all(nzchar(s$top3_residual_cells)))
    # パイプ区切りで最大3要素
    for (i in seq_len(nrow(s))) {
      parts <- strsplit(s$top3_residual_cells[i], "\\|")[[1]]
      check(paste("top3 has <= 3 elements, row", i), length(parts) <= 3L && length(parts) >= 1L)
    }
  }

  if ("interpretation_flag" %in% names(s)) {
    valid_flags <- c("strong_association", "weak_association", "no_association")
    check("interpretation_flag values are valid",
          all(s$interpretation_flag %in% valid_flags))
  }
}

cat(sprintf("\n--- Results: %d passed, %d failed ---\n", pass, fail))
if (fail > 0L) stop("Some summary CSV new column tests failed.")
message("OK: summary CSV new column tests passed.")
