# report.Rmd の assoc チャンクに shade = TRUE があることを検証（vcd 不要）
# Run: Rscript tests/test_vcd_categorical_template_assoc_shade.R

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
  chunk_start <- grep("^```\\{r assoc-plot\\}", lines)
  chunk_end <- grep("^```$", lines)
  chunk_end <- chunk_end[chunk_end > chunk_start[1L]][1L]
  stopifnot(length(chunk_start) == 1L, !is.na(chunk_end))
  chunk <- lines[(chunk_start + 1L):(chunk_end - 1L)]
  assoc_lines <- grep("^[[:space:]]*assoc\\(", chunk, value = TRUE)
  stopifnot(length(assoc_lines) >= 1L)
  if (!all(grepl("shade\\s*=\\s*TRUE", assoc_lines))) {
    stop("assoc() must use shade = TRUE in: ", p)
  }
}
message("OK: assoc shade = TRUE present in both report.Rmd templates.")
