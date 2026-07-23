#!/usr/bin/env Rscript
# tests/test_summary_csv_new_columns.R
# summary.csv のCramér's V・層別指標が存在し値が妥当であることを検証
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
  'cd "%s" && Rscript --vanilla "%s" --data "%s" --question-config "%s" --out "%s" --run-id summary_test',
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

summary_csv <- file.path(out_dir, "runs", "summary_test", "summary.csv")
check("summary.csv exists", file.exists(summary_csv))

if (file.exists(summary_csv)) {
  s <- read.csv(summary_csv, stringsAsFactors = FALSE, na.strings = "")

  cram_cols <- c(
    "cramer_v_marginal", "cramer_v_df_star", "cramer_v_effect_label",
    "cramer_v_strata_json", "cramer_v_strata_mean", "cramer_v_strata_max",
    "cramer_v_strata_max_level", "marginal_strata_signal", "marginal_strata_note"
  )
  for (col in cram_cols) {
    check(paste("column exists:", col), col %in% names(s))
  }

  if (all(cram_cols %in% names(s))) {
    row2 <- s[s$question_id == "q02", , drop = FALSE]
    check("3-way cramer_v_marginal is finite", nrow(row2) == 1L && is.finite(row2$cramer_v_marginal[1]))
    check("3-way cramer_v_strata_json parses as JSON",
          nrow(row2) == 1L && nzchar(row2$cramer_v_strata_json[1]))
    if (nrow(row2) == 1L && nzchar(row2$cramer_v_strata_json[1])) {
      suppressPackageStartupMessages({
        if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
      })
      parsed <- tryCatch(jsonlite::parse_json(row2$cramer_v_strata_json[1]), error = function(e) NULL)
      check("cramer_v_strata_json is valid JSON", is.list(parsed) && length(parsed) >= 1L)
    }
    sig_ok <- is.na(row2$marginal_strata_signal[1]) ||
      row2$marginal_strata_signal[1] %in% c("none", "review_stratified")
    check("marginal_strata_signal is NA, none, or review_stratified", nrow(row2) == 1L && sig_ok)
  }
}

cat(sprintf("\n--- Results: %d passed, %d failed ---\n", pass, fail))
if (fail > 0L) stop("Some summary CSV new column tests failed.")
message("OK: summary CSV new column tests passed.")
