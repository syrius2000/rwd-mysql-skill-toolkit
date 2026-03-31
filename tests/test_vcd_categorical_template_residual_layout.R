#!/usr/bin/env Rscript
# report.Rmd の residual plot + table レイアウトを検証
# Run: Rscript tests/test_vcd_categorical_template_residual_layout.R

ca <- commandArgs(trailingOnly = FALSE)
f <- sub("^--file=", "", ca[startsWith(ca, "--file=")][1L])
repo <- if (is.na(f) || !nzchar(f)) {
  normalizePath(".", winslash = "/", mustWork = TRUE)
} else {
  normalizePath(file.path(dirname(f), ".."), winslash = "/", mustWork = TRUE)
}

paths <- c(
  file.path(repo, ".cursor/skills/vcd-categorical-analysis/templates/report.Rmd"),
  file.path(repo, ".agent/skills/vcd-categorical-analysis/templates/report.Rmd")
)

for (p in paths) {
  stopifnot(file.exists(p))
  lines <- readLines(p, warn = FALSE)

  chunk_names <- c(
    "summary-text",
    "residual-model",
    "residual-plot-heading",
    "residual-plot",
    "residual-table",
    "mosaic-plot",
    "assoc-plot",
    "glm-loglinear"
  )
  chunk_pos <- vapply(
    chunk_names,
    function(name) {
      idx <- grep(sprintf("^```\\{r %s([,}])", name), lines)
      if (length(idx) != 1L) stop("Chunk not found exactly once: ", name, " in ", p)
      idx
    },
    integer(1)
  )

  if (!all(diff(chunk_pos) > 0)) {
    stop("Residual layout chunk order is invalid in: ", p)
  }

  if (!any(grepl("Residual plot", lines, fixed = TRUE))) {
    stop("Residual plot heading is missing in: ", p)
  }

  if (!any(grepl("order\\(-resid_tbl\\$abs_res\\)", lines))) {
    stop("Residual table sort by absolute residual is missing in: ", p)
  }

  if (!any(grepl("utils::head\\(", lines)) || !any(grepl("20L", lines, fixed = TRUE))) {
    stop("Residual table top-N truncation is missing in: ", p)
  }
}

message("OK: residual plot + table layout present in both vcd report templates.")
