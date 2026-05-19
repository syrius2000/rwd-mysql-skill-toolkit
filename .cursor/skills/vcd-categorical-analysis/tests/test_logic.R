# vcd-categorical-analysis/tests/test_logic.R
#
# Logic verification: factor conversion, sparsity, validate_config,
# Pass 2 data_profile_post.json, plot_mode

suppressPackageStartupMessages({
  library(jsonlite)
})

test_df <- data.frame(
  item = c(1, 1, 2, 2),
  group = c(10, 20, 10, 20),
  Freq = c(5, 0, 10, 5)
)

test_csv <- "temp_test.csv"
write.csv(test_df, test_csv, row.names = FALSE)

script_path <- "templates/analysis.R"
if (!file.exists(script_path)) {
  script_path <- "../templates/analysis.R"
}

out_dir <- "test_out_logic"
dir.create(out_dir, showWarnings = FALSE)

# ============================================================
# Test 1: Pass 1 - factor conversion and sparsity
# ============================================================
cat("[TEST 1] Pass 1: factor conversion and sparsity...\n")
system2("Rscript", c(
  script_path, "--profile", "--data", test_csv,
  "--vars", "item,group", "--freq", "Freq", "--out", out_dir
))

profile_path <- file.path(out_dir, "data_profile.json")
if (!file.exists(profile_path)) stop("data_profile.json not generated")

profile <- fromJSON(profile_path)
if (profile$variables$item$n_levels != 2) stop("Factor conversion failed for 'item'")
if (profile$variables$group$n_levels != 2) stop("Factor conversion failed for 'group'")
if (profile$sparsity_ratio != 0.75) stop("Sparsity ratio error: ", profile$sparsity_ratio)
if (is.null(profile$warning)) stop("Sparsity warning missing")
cat("[PASS 1] OK\n")

# ============================================================
# Test 2: validate_config (source the function directly)
# ============================================================
cat("[TEST 2] validate_config...\n")
env <- new.env()
sys.source(script_path, envir = env, chdir = TRUE)

good_cfg <- env$validate_config(list(
  collapse_below_n = 3, max_levels_per_var = 5,
  plot_mode = "always", gt_matrix_vars = list(2, 1),
  strata_to_render = list("A", "B")
))
if (good_cfg$collapse_below_n != 3L) stop("collapse_below_n not set")
if (good_cfg$max_levels_per_var != 5L) stop("max_levels_per_var not set")
if (good_cfg$plot_mode != "always") stop("plot_mode not set")
if (good_cfg$gt_matrix_vars[1] != 2L) stop("gt_matrix_vars[1] not set")
if (!identical(good_cfg$strata_to_render, c("A", "B"))) stop("strata_to_render not set")

bad_cfg <- env$validate_config(list(
  collapse_below_n = "abc", plot_mode = "invalid_mode",
  unknown_key = TRUE
))
if (bad_cfg$collapse_below_n != 0L) stop("Bad collapse_below_n should fallback to 0")
if (bad_cfg$plot_mode != "auto") stop("Bad plot_mode should fallback to 'auto'")
cat("[PASS 2] OK\n")

# ============================================================
# Test 3: Pass 2 with config - data_profile_post.json
# ============================================================
cat("[TEST 3] Pass 2: data_profile_post.json...\n")
config_path <- file.path(out_dir, "test_config.json")
write_json(list(collapse_below_n = 0, plot_mode = "residual_only"),
  config_path,
  auto_unbox = TRUE
)

unlink(out_dir, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE)
write_json(list(collapse_below_n = 0, plot_mode = "residual_only"),
  config_path,
  auto_unbox = TRUE
)

system2("Rscript", c(
  script_path, "--render", "--data", test_csv,
  "--vars", "item,group", "--freq", "Freq",
  "--config", config_path, "--out", out_dir
))

post_path <- file.path(out_dir, "data_profile_post.json")
if (!file.exists(post_path)) stop("data_profile_post.json not generated in Pass 2")
cat("[PASS 3] OK\n")

# ============================================================
# Test 4: plot_mode=residual_only skips PNG
# ============================================================
cat("[TEST 4] plot_mode=residual_only skips PNG...\n")
mosaic_files <- list.files(out_dir, pattern = "^mosaic_.*\\.png$")
assoc_files <- list.files(out_dir, pattern = "^assoc_.*\\.png$")
if (length(mosaic_files) > 0) stop("mosaic PNG should NOT exist with plot_mode=residual_only")
if (length(assoc_files) > 0) stop("assoc PNG should NOT exist with plot_mode=residual_only")
cat("[PASS 4] OK\n")

# ============================================================
cat("\n[ALL TESTS PASSED]\n")

# Cleanup
unlink(test_csv)
unlink(out_dir, recursive = TRUE)
