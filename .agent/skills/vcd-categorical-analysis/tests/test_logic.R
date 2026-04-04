# vcd-categorical-analysis/tests/test_logic.R
# 
# Logic verification for factor conversion and sparsity ratio

suppressPackageStartupMessages({
  library(jsonlite)
})

# Mock data with numbers that SHOULD be factors
test_df <- data.frame(
  item = c(1, 1, 2, 2),
  group = c(10, 20, 10, 20),
  Freq = c(5, 0, 10, 5)
)

test_csv <- "temp_test.csv"
write.csv(test_df, test_csv, row.names = FALSE)

# Resolve script path independently of CWD
# When running as Rscript tests/test_logic.R, getwd() is the skill root
# When running inside tests/, getwd() is tests/
script_path <- "templates/analysis.R"
if (!file.exists(script_path)) {
  script_path <- "../templates/analysis.R"
}

out_dir <- "test_out_logic"
dir.create(out_dir, showWarnings = FALSE)

cat("[TEST] Testing factor conversion and sparsity...\n")
system2("Rscript", c(script_path, "--profile", "--data", test_csv, "--vars", "item,group", "--freq", "Freq", "--out", out_dir))

# Check data_profile.json
profile_path <- file.path(out_dir, "data_profile.json")
if (!file.exists(profile_path)) stop("data_profile.json not generated")

profile <- fromJSON(profile_path)

# Verify factors (item should have 2 levels)
if (profile$variables$item$n_levels != 2) stop("Factor conversion failed for 'item'")
if (profile$variables$group$n_levels != 2) stop("Factor conversion failed for 'group'")

# Verify Sparsity (1 zero out of 4 cells -> 0.75 ratio)
if (profile$sparsity_ratio != 0.75) stop("Sparsity ratio calculation error: ", profile$sparsity_ratio)
if (is.null(profile$warning)) stop("Sparsity warning missing")

cat("[PASS] Logic verification successful.\n")

# Cleanup
unlink(test_csv)
unlink(out_dir, recursive = TRUE)
