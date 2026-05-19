archived_from: docs/superpowers/plans/2026-04-04-vcd-skill-improvement.md

# VCD カテゴリカル分析スキル改善 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `vcd-categorical-analysis` を2スキルに分割し、2パス方式の分析パイプライン＋判断ファーストレポートを実装する。

**Architecture:** `analysis.R` を5関数構成にリファクタリング（profile/data/gt/DT/plots）。新スキル `vcd-categorical-reporting` を作成し、AI判断手順とレポートテンプレートを分離。共有契約 `interface.md` で協調。

**Tech Stack:** R 4.4.x, gt, DT, htmlwidgets, jsonlite, vcd, ggplot2

**Spec:** [2026-04-04-vcd-skill-improvement-design.md](../../superpowers/specs/2026-04-04-vcd-skill-improvement-design.md)

---

## ファイル構成

### 新規作成

| ファイル | 役割 |
| :--- | :--- |
| `.agent/skills/vcd-categorical-analysis/references/interface.md` | 共有契約（JSON/CSVスキーマ、命名規則） |
| `.agent/skills/vcd-categorical-reporting/SKILL.md` | AI判断手順＋レポート構成指示 |
| `.agent/skills/vcd-categorical-reporting/references/interface.md` | 共有契約（同一内容） |
| `.agent/skills/vcd-categorical-reporting/references/workflow.md` | 2パスシーケンス図 |
| `.agent/skills/vcd-categorical-reporting/references/report-template.md` | 3章構成テンプレート |
| `.agent/skills/vcd-categorical-reporting/references/evaluation-criteria.md` | AI判断基準 |

### 変更

| ファイル | 変更内容 |
| :--- | :--- |
| `.agent/skills/vcd-categorical-analysis/templates/analysis.R` | 5関数構成にリファクタリング。`generate_profile`, `generate_gt_matrix`, `generate_dt_table` 追加 |
| `.agent/skills/vcd-categorical-analysis/SKILL.md` | スコープを「R側データ・図表生成」に限定。連携スキル記載追加 |
| `.agent/skills/vcd-categorical-analysis/references/dependencies.md` | `DT`, `htmlwidgets` 追加 |
| `.agent/skills/vcd-categorical-analysis/references/workflow.md` | 2パス方式のシーケンス図に更新 |

### ミラー

全タスク完了後、`.agent/skills/` の変更を `.cursor/skills/` にミラーする。

---

## Task 1: interface.md（共有契約）の作成

**Files:**
- Create: `.agent/skills/vcd-categorical-analysis/references/interface.md`

- [ ] **Step 1: interface.md を作成**

```markdown
# VCD Analysis ↔ Reporting インターフェース契約

interface_version: "2.0"

## 出力ディレクトリ

`./skill_out/vcd_categorical/`

## Pass 1 出力: data_profile.json

| フィールド | 型 | 説明 |
| :--- | :--- | :--- |
| n_dimensions | int | 変数の数（2 or 3） |
| variables | object | 変数名をキー、{n_levels, levels} を値 |
| total_cells | int | 全セル数 |
| total_cells_2way_marginal | int | 2-way 周辺表のセル数 |
| n_nonzero_cells | int | Freq > 0 のセル数 |
| sparsity_ratio | float | n_nonzero_cells / total_cells |

## Pass 2 入力: render_config.json

| フィールド | 型 | 既定値 | 説明 |
| :--- | :--- | :--- | :--- |
| collapse_below_n | int | 0 | この Freq 以下のセルを集約（0=集約しない） |
| max_levels_per_var | int | 999 | 各変数の最大水準数（超過分は集約） |
| strata_to_render | array(string) | [] | gt マトリックスを生成する層（空=全層） |
| gt_matrix_vars | array(int) | [1, 2] | マトリックスの行・列に使う変数インデックス |
| plot_mode | string | "auto" | "auto" / "always" / "residual_only" |

## Pass 2 出力ファイル規約

| ファイル名パターン | 形式 | 生成元 | 消費先 |
| :--- | :--- | :--- | :--- |
| `data_profile.json` | JSON | analysis (Pass 1) | reporting |
| `summary_{data}.json` | JSON | analysis (Pass 2) | reporting |
| `residuals_{data}.csv` | CSV | analysis (Pass 2) | reporting |
| `residuals_{data}_significant.csv` | CSV | analysis (Pass 2) | reporting |
| `matrix_marginal_{data}.html` | gt HTML | analysis (Pass 2) | reporting |
| `matrix_{data}_{layer}.html` | gt HTML | analysis (Pass 2) | reporting |
| `dt_residuals_{data}.html` | DT HTML | analysis (Pass 2) | reporting |
| `mosaic_{data}.png` | PNG | analysis (Pass 2) | reporting |
| `assoc_{data}.png` | PNG | analysis (Pass 2) | reporting |

## summary_*.json スキーマ

```json
{
  "interface_version": "2.0",
  "test_used": "string",
  "models_tested": ["string"],
  "deviance_main": "number",
  "df_main": "integer",
  "deviance_2way": "number",
  "df_2way": "integer",
  "p_value_main_vs_2way": "number",
  "cramers_v_marginal": "number",
  "top_residuals_main": [{"cell": "string", "res": "number"}],
  "top_residuals_2way": [{"cell": "string", "res": "number"}],
  "strata_summary": {
    "strata_var": "string",
    "n_strata": "integer",
    "max_abs_res_per_stratum": {"layer_name": "number"},
    "cramers_v_per_stratum": {"layer_name": "number"},
    "n_significant_cells_5pct": "integer",
    "n_significant_cells_1pct": "integer",
    "total_cells": "integer"
  }
}
```

## 変更ルール

- analysis 側が出力フォーマットを変更する場合、interface_version をインクリメントすること。
- reporting 側は interface_version を確認し、非互換の場合はユーザーに警告すること。
```

- [ ] **Step 2: コミット**

```bash
git add .agent/skills/vcd-categorical-analysis/references/interface.md
git commit -m "feat(vcd-analysis): 共有契約 interface.md を作成"
```

---

## Task 2: analysis.R を5関数構成にリファクタリング

**Files:**
- Modify: `.agent/skills/vcd-categorical-analysis/templates/analysis.R` (全面書き換え)

- [ ] **Step 1: generate_profile() を実装**

`analysis.R` の冒頭を以下に書き換え。データの次元・水準数・疎密度を `data_profile.json` に出力する関数。

```r
# VCD Categorical Analysis Pipeline (v2.0)
# 2-pass mode: --profile (Pass 1) or --render --config <path> (Pass 2)
# Outputs under ./skill_out/vcd_categorical/

# --- Packages ---
if (!base::requireNamespace("pacman", quietly = TRUE)) utils::install.packages("pacman")
pacman::p_load(vcd, gt, DT, htmlwidgets, ggplot2, jsonlite)

# --- CLI args ---
args <- base::commandArgs(trailingOnly = TRUE)
mode <- if ("--profile" %in% args) "profile" else "render"
config_path <- NULL
if ("--config" %in% args) {
  idx <- base::which(args == "--config")
  if (idx < base::length(args)) config_path <- args[idx + 1]
}

# ============================================================
# generate_profile: Pass 1 - lightweight data profiling
# ============================================================
generate_profile <- function(df, vars, freq_col = "Freq", output_dir) {
  var_info <- base::lapply(vars, function(v) {
    lvls <- base::levels(base::factor(df[[v]]))
    base::list(n_levels = base::length(lvls), levels = lvls)
  })
  base::names(var_info) <- vars

  tab <- stats::xtabs(stats::as.formula(
    base::paste(freq_col, "~", base::paste(vars, collapse = " + "))
  ), data = df)
  total_cells <- base::prod(base::dim(tab))
  n_nonzero <- base::sum(base::as.vector(tab) > 0)

  marginal_cells <- if (base::length(vars) >= 2) {
    base::prod(base::dim(tab)[1:2])
  } else total_cells

  profile <- base::list(
    n_dimensions = base::length(vars),
    variables = var_info,
    total_cells = total_cells,
    total_cells_2way_marginal = marginal_cells,
    n_nonzero_cells = n_nonzero,
    sparsity_ratio = base::round(n_nonzero / total_cells, 3)
  )
  jsonlite::write_json(profile, base::file.path(output_dir, "data_profile.json"),
                       auto_unbox = TRUE, pretty = TRUE)
  base::message("[PROFILE] data_profile.json written to ", output_dir)
  return(base::invisible(profile))
}
```

- [ ] **Step 2: generate_data() を実装**

Poisson GLM フィッティング＋残差計算＋JSON/CSV出力。`config` の `collapse_below_n` に対応。

```r
# ============================================================
# generate_data: Pass 2 - GLM fitting, residuals, JSON/CSV
# ============================================================
generate_data <- function(df, vars, freq_col = "Freq", output_dir, config, data_label = "data") {
  # Apply collapse if configured
  if (!base::is.null(config$collapse_below_n) && config$collapse_below_n > 0) {
    for (v in vars) {
      freq_by_level <- stats::tapply(df[[freq_col]], df[[v]], base::sum)
      minor_levels <- base::names(freq_by_level[freq_by_level <= config$collapse_below_n])
      if (base::length(minor_levels) > 0) {
        df[[v]] <- base::ifelse(df[[v]] %in% minor_levels, "Other", base::as.character(df[[v]]))
        df[[v]] <- base::factor(df[[v]])
      }
    }
  }

  fml_main <- stats::as.formula(base::paste(freq_col, "~", base::paste(vars, collapse = " + ")))
  fml_2way <- stats::as.formula(base::paste(freq_col, "~ (", base::paste(vars, collapse = " + "), ")^2"))
  fml_sat  <- stats::as.formula(base::paste(freq_col, "~", base::paste(vars, collapse = " * ")))

  fit_main <- base::tryCatch(stats::glm(fml_main, family = stats::poisson, data = df),
    error = function(e) { base::message("[ERROR] fit_main: ", base::conditionMessage(e)); NULL })
  fit_2way <- base::tryCatch(stats::glm(fml_2way, family = stats::poisson, data = df),
    error = function(e) { base::message("[ERROR] fit_2way: ", base::conditionMessage(e)); NULL })
  fit_sat  <- base::tryCatch(stats::glm(fml_sat, family = stats::poisson, data = df),
    error = function(e) { base::message("[ERROR] fit_sat: ", base::conditionMessage(e)); NULL })

  anova_res <- base::tryCatch(stats::anova(fit_main, fit_2way, fit_sat, test = "Chisq"),
    error = function(e) { base::message("[WARNING] anova: ", base::conditionMessage(e)); NULL })

  collect_res <- function(fit, label) {
    if (base::is.null(fit)) return(NULL)
    res_df <- df
    res_df$model_type <- label
    res_df$pearson_res <- stats::residuals(fit, type = "pearson")
    res_df$abs_pearson_res <- base::abs(res_df$pearson_res)
    res_df$cell_label <- base::apply(res_df[, vars, drop = FALSE], 1, base::paste, collapse = ":")
    return(res_df)
  }

  res_main <- collect_res(fit_main, "Main")
  res_2way <- collect_res(fit_2way, "2-Way")
  res_combined <- base::rbind(res_main, res_2way)
  utils::write.csv(res_combined, base::file.path(output_dir,
    base::paste0("residuals_", data_label, ".csv")), row.names = FALSE)

  top_n <- 20
  sig_compact <- base::rbind(
    utils::head(res_main[base::order(-res_main$abs_pearson_res), ], top_n),
    utils::head(res_2way[base::order(-res_2way$abs_pearson_res), ], top_n)
  )
  sig_compact <- sig_compact[!base::duplicated(
    base::paste(sig_compact$model_type, sig_compact$cell_label)), ]
  utils::write.csv(sig_compact, base::file.path(output_dir,
    base::paste0("residuals_", data_label, "_significant.csv")), row.names = FALSE)

  tab <- stats::xtabs(stats::as.formula(
    base::paste(freq_col, "~", base::paste(vars, collapse = " + "))), data = df)

  anova_p <- if (!base::is.null(anova_res)) anova_res$`Pr(>Chi)`[2] else NA

  # strata_summary (3-way only)
  strata_info <- NULL
  if (base::length(vars) >= 3) {
    strata_var <- vars[3]
    strata_levels <- base::levels(base::factor(df[[strata_var]]))
    max_res_per <- base::sapply(strata_levels, function(lv) {
      sub <- res_main[res_main[[strata_var]] == lv, ]
      if (base::nrow(sub) == 0) return(NA)
      base::max(sub$abs_pearson_res, na.rm = TRUE)
    })
    cv_per <- base::sapply(strata_levels, function(lv) {
      sub_tab <- stats::xtabs(stats::as.formula(
        base::paste(freq_col, "~", base::paste(vars[1:2], collapse = " + "))),
        data = df[df[[strata_var]] == lv, ])
      base::tryCatch(vcd::assocstats(sub_tab)$cramer, error = function(e) NA)
    })
    n_sig_5 <- base::sum(res_combined$abs_pearson_res >= 1.96, na.rm = TRUE)
    n_sig_1 <- base::sum(res_combined$abs_pearson_res >= 2.58, na.rm = TRUE)
    strata_info <- base::list(
      strata_var = strata_var, n_strata = base::length(strata_levels),
      max_abs_res_per_stratum = base::as.list(max_res_per),
      cramers_v_per_stratum = base::as.list(cv_per),
      n_significant_cells_5pct = n_sig_5,
      n_significant_cells_1pct = n_sig_1,
      total_cells = base::nrow(res_combined)
    )
  }

  summary_obj <- base::list(
    interface_version = "2.0",
    test_used = "stats::anova (Poisson GLM)",
    models_tested = c("Main Effects", "2-way Interactions"),
    deviance_main = if (!base::is.null(fit_main)) fit_main$deviance else NA,
    df_main = if (!base::is.null(fit_main)) fit_main$df.residual else NA,
    deviance_2way = if (!base::is.null(fit_2way)) fit_2way$deviance else NA,
    df_2way = if (!base::is.null(fit_2way)) fit_2way$df.residual else NA,
    p_value_main_vs_2way = anova_p,
    cramers_v_marginal = base::tryCatch(
      vcd::assocstats(base::margin.table(tab, c(1, 2)))$cramer, error = function(e) NA),
    top_residuals_main = if (!base::is.null(res_main)) {
      idx <- utils::head(base::order(-res_main$abs_pearson_res), 5)
      base::lapply(idx, function(i) base::list(cell = res_main$cell_label[i], res = res_main$pearson_res[i]))
    } else NULL,
    top_residuals_2way = if (!base::is.null(res_2way)) {
      idx <- utils::head(base::order(-res_2way$abs_pearson_res), 5)
      base::lapply(idx, function(i) base::list(cell = res_2way$cell_label[i], res = res_2way$pearson_res[i]))
    } else NULL,
    strata_summary = strata_info
  )
  jsonlite::write_json(summary_obj, base::file.path(output_dir,
    base::paste0("summary_", data_label, ".json")), auto_unbox = TRUE, pretty = TRUE)

  base::message("[DATA] JSON/CSV written for: ", data_label)
  return(base::list(df = df, tab = tab, res_main = res_main, res_2way = res_2way,
                    fit_main = fit_main, fit_2way = fit_2way))
}
```

- [ ] **Step 3: generate_gt_matrix() を実装**

`gt` による残差マトリックス表。青赤グラデーション＋有意セル太枠。

```r
# ============================================================
# generate_gt_matrix: Pass 2 - gt pivot residual matrix
# ============================================================
generate_gt_matrix <- function(res_df, vars, freq_col = "Freq",
                               output_dir, config, data_label = "data") {
  row_var <- vars[1]
  col_var <- vars[2]

  build_matrix <- function(sub_df, suffix) {
    agg <- stats::aggregate(
      stats::as.formula(base::paste("pearson_res ~", row_var, "+", col_var)),
      data = sub_df, FUN = base::mean
    )
    wide <- stats::reshape(agg, idvar = row_var, timevar = col_var,
                           direction = "wide")
    base::names(wide) <- base::gsub("^pearson_res\\.", "", base::names(wide))
    row_names <- wide[[row_var]]
    wide[[row_var]] <- NULL

    mx <- base::max(base::abs(base::unlist(wide)), na.rm = TRUE)
    if (!base::is.finite(mx) || mx < 1e-12) mx <- 1

    tbl <- gt::gt(base::cbind(data.frame(V1 = row_names), wide),
                  rowname_col = "V1") |>
      gt::fmt_number(decimals = 3) |>
      gt::data_color(columns = base::names(wide),
                     domain = c(-mx, mx), palette = c("#D73027", "#FFFFFF", "#4575B4")) |>
      gt::tab_header(title = base::paste("Pearson Residuals:", suffix)) |>
      gt::tab_stubhead(label = row_var) |>
      gt::tab_style(
        style = gt::cell_borders(sides = "all", weight = gt::px(2), color = "#333333"),
        locations = gt::cells_body(
          columns = base::names(wide),
          rows = base::apply(wide, 1, function(r) base::any(base::abs(r) >= 1.96, na.rm = TRUE))
        )
      )
    fname <- base::paste0("matrix_", suffix, ".html")
    gt::gtsave(tbl, base::file.path(output_dir, fname))
    base::message("[GT] ", fname)
  }

  # Main effects residuals only
  main_df <- res_df[res_df$model_type == "Main", ]

  # Marginal matrix
  build_matrix(main_df, base::paste0("marginal_", data_label))

  # Strata matrices (3-way)
  if (base::length(vars) >= 3) {
    strata_var <- vars[3]
    strata_to_render <- if (!base::is.null(config$strata_to_render) &&
                            base::length(config$strata_to_render) > 0) {
      config$strata_to_render
    } else {
      base::levels(base::factor(main_df[[strata_var]]))
    }
    for (lv in strata_to_render) {
      sub <- main_df[main_df[[strata_var]] == lv, ]
      if (base::nrow(sub) > 0) {
        build_matrix(sub, base::paste0(data_label, "_", lv))
      }
    }
  }
}
```

- [ ] **Step 4: generate_dt_table() を実装**

`DT::datatable` によるソート可能テーブル。青赤着色、絶対値降順。

```r
# ============================================================
# generate_dt_table: Pass 2 - DT interactive residual table
# ============================================================
generate_dt_table <- function(res_df, vars, output_dir, config, data_label = "data") {
  display_cols <- c(vars, "Freq", "pearson_res", "abs_pearson_res", "model_type")
  dt_df <- res_df[, display_cols, drop = FALSE]
  dt_df <- dt_df[base::order(-dt_df$abs_pearson_res), ]

  mx <- base::max(dt_df$abs_pearson_res, na.rm = TRUE)
  if (!base::is.finite(mx) || mx < 1e-12) mx <- 1

  # Color breaks: negative = red, positive = blue
  brks <- base::seq(-mx, mx, length.out = 100)
  clrs <- grDevices::colorRampPalette(c("#D73027", "#FFFFFF", "#4575B4"))(99)

  widget <- DT::datatable(dt_df,
    filter = "top",
    options = base::list(
      pageLength = 50,
      order = base::list(base::list(
        base::which(base::names(dt_df) == "abs_pearson_res") - 1, "desc")),
      dom = "lftipr"
    ),
    caption = base::paste("Pearson Residuals:", data_label, "| Click headers to sort")
  ) |>
    DT::formatRound(columns = c("pearson_res", "abs_pearson_res"), digits = 3) |>
    DT::formatStyle("pearson_res",
      backgroundColor = DT::styleInterval(brks[-1], clrs))

  fname <- base::paste0("dt_residuals_", data_label, ".html")
  htmlwidgets::saveWidget(widget, base::file.path(output_dir, fname),
                          selfcontained = TRUE)
  base::message("[DT] ", fname)
}
```

- [ ] **Step 5: generate_plots() を実装**

```r
# ============================================================
# generate_plots: Pass 2 - Mosaic / Association PNG
# ============================================================
generate_plots <- function(tab, vars, output_dir, config, data_label = "data") {
  grDevices::png(base::file.path(output_dir, base::paste0("mosaic_", data_label, ".png")),
                 width = 1000, height = 800)
  vcd::mosaic(tab, shade = TRUE,
              main = base::paste("Mosaic:", base::paste(vars, collapse = " x ")))
  grDevices::dev.off()

  if (base::length(vars) == 2) {
    grDevices::png(base::file.path(output_dir, base::paste0("assoc_", data_label, ".png")),
                   width = 1000, height = 800)
    vcd::assoc(tab, residuals_type = "Pearson", shade = TRUE,
               main = base::paste("Association:", base::paste(vars, collapse = " x ")))
    grDevices::dev.off()
  }

  if (base::length(vars) >= 3) {
    grDevices::png(base::file.path(output_dir, base::paste0("cotab_", data_label, ".png")),
                   width = 1000, height = 800)
    vcd::cotabplot(tab, panel = vcd::cotab_mosaic, shade = TRUE,
                   main = base::paste("Conditional mosaic (by", vars[3], ")"))
    grDevices::dev.off()
  }
  base::message("[PLOTS] PNG files written for: ", data_label)
}
```

- [ ] **Step 6: メインディスパッチャーを実装**

```r
# ============================================================
# Main dispatcher
# ============================================================
output_dir <- "./skill_out/vcd_categorical/"
base::dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- User must set these ---
# df <- utils::read.csv("your_data.csv")
# vars <- c("var1", "var2", "var3")  # 2 or 3 variables
# freq_col <- "Freq"
# data_label <- "mydata"

# Example: HairEyeColor
base::data("HairEyeColor", package = "datasets")
df <- base::as.data.frame(HairEyeColor)
vars <- c("Hair", "Eye", "Sex")
freq_col <- "Freq"
data_label <- "haireye"

if (mode == "profile") {
  generate_profile(df, vars, freq_col, output_dir)
} else {
  config <- if (!base::is.null(config_path) && base::file.exists(config_path)) {
    jsonlite::read_json(config_path)
  } else {
    base::list()  # defaults
  }
  result <- generate_data(df, vars, freq_col, output_dir, config, data_label)
  generate_gt_matrix(result$res_main, vars, freq_col, output_dir, config, data_label)
  # Combine for DT
  res_all <- base::rbind(result$res_main, result$res_2way)
  generate_dt_table(res_all, vars, output_dir, config, data_label)
  generate_plots(result$tab, vars, output_dir, config, data_label)
  base::message("[DONE] All outputs generated for: ", data_label)
}
```

- [ ] **Step 7: analysis.R をテスト（Pass 1）**

```bash
cd /Users/myamaguchi/Programing/OSX_IDE_Skill_management
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R --profile
```

Expected: `skill_out/vcd_categorical/data_profile.json` が生成される。中身に `n_dimensions`, `variables`, `sparsity_ratio` が含まれる。

- [ ] **Step 8: analysis.R をテスト（Pass 2、デフォルト config）**

```bash
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R --render
```

Expected: `summary_haireye.json`, `residuals_haireye.csv`, `matrix_marginal_haireye.html`, `dt_residuals_haireye.html`, `mosaic_haireye.png` が生成される。

- [ ] **Step 9: コミット**

```bash
git add .agent/skills/vcd-categorical-analysis/templates/analysis.R
git commit -m "feat(vcd-analysis): analysis.R を5関数構成にリファクタリング（2パス対応）"
```

---

## Task 3: dependencies.md の更新

**Files:**
- Modify: `.agent/skills/vcd-categorical-analysis/references/dependencies.md`

- [ ] **Step 1: DT, htmlwidgets を追加**

L12 の `pacman` 行の後に以下を追加：

```markdown
| **必須** | `DT` | ソート可能インタラクティブ残差テーブル（`DT::datatable`） |
| **必須** | `htmlwidgets` | DT の self-contained HTML 出力（`htmlwidgets::saveWidget`） |
```

- [ ] **Step 2: コミット**

```bash
git add .agent/skills/vcd-categorical-analysis/references/dependencies.md
git commit -m "docs(vcd-analysis): DT, htmlwidgets を依存に追加"
```

---

## Task 4: vcd-categorical-analysis の SKILL.md 更新

**Files:**
- Modify: `.agent/skills/vcd-categorical-analysis/SKILL.md`

- [ ] **Step 1: スコープを「R側データ・図表生成」に限定し、連携スキル記載を追加**

SKILL.md の冒頭 description を更新し、末尾に連携スキルセクションを追加する。

description 行を変更：
```yaml
description: 名義カテゴリカル変数（最大 3-way）のクロス表・独立性・残差分析のための R パイプライン。2パス方式で data_profile.json（Pass 1）と統計成果物（Pass 2）を生成する。AI解釈・レポート構成は `vcd-categorical-reporting` を参照。
```

末尾に追加：
```markdown
## 連携スキル

- **後続**: `vcd-categorical-reporting` が本スキルの出力を読み取り、AI判断レポートを生成する。
- **契約**: `references/interface.md` を参照。
```

手順セクションは analysis 側に適合するように「R実行の手順」のみに絞る（AI評価フェーズの記述は reporting 側に移動）。

- [ ] **Step 2: コミット**

```bash
git add .agent/skills/vcd-categorical-analysis/SKILL.md
git commit -m "docs(vcd-analysis): スコープをR側に限定、連携スキル記載追加"
```

---

## Task 5: vcd-categorical-reporting スキルの新規作成

**Files:**
- Create: `.agent/skills/vcd-categorical-reporting/SKILL.md`
- Create: `.agent/skills/vcd-categorical-reporting/references/interface.md` (Task 1 と同一内容をコピー)
- Create: `.agent/skills/vcd-categorical-reporting/references/workflow.md`
- Create: `.agent/skills/vcd-categorical-reporting/references/report-template.md`
- Create: `.agent/skills/vcd-categorical-reporting/references/evaluation-criteria.md`

- [ ] **Step 1: SKILL.md を作成**

```markdown
---
name: vcd-categorical-reporting
description: vcd-categorical-analysis の出力（JSON/CSV/HTML/PNG）を読み取り、判断ファースト形式の AI 評価レポート（vcd_analysis_report.md）を3章構成で作成する。
license: MIT
metadata:
  author: vcd-categorical-reporting-skill
  version: "2.0"
---

`vcd-categorical-analysis` が生成した統計成果物を AI が読み取り、**判断ファースト**形式のレポートを構成する。

## 前提スキル

- **先行**: `vcd-categorical-analysis` を先に実行し、`./skill_out/vcd_categorical/` に成果物が存在すること。
- **契約**: `references/interface.md` を参照。

## 手順

### Pass 1: データプロファイルの確認

1. `data_profile.json` を読み取る。
2. 次元数・水準数・疎密度を確認し、`render_config.json` を生成して `vcd-categorical-analysis` の Pass 2 を実行させる。
   - 水準数が多い場合（合計セル数 > 200）: `collapse_below_n` や `max_levels_per_var` の調整を検討
   - 3-way の場合: `strata_to_render` で注目すべき層を選択（全層を生成する場合は空配列）

### Pass 2 成果物の読み取りと判断

1. `summary_*.json` を読み取り、以下の2段階で思考すること：
   - **第1段階（全体構造の俯瞰）**: 主効果モデルの残差から、変数間の自明かつ強力な関連性を指摘
   - **第2段階（局所交互作用の洞察）**: 2-way モデルの残差から、単純な相関では説明できない特異な偏りを言語化
2. `strata_summary` を読み取り、**どの層の gt マトリックスを第2章に前面配置するか**を決定する。`max_abs_res_per_stratum` と `cramers_v_per_stratum` の値から統計的に最も注目すべき層を選ぶ。
3. `n_significant_cells_5pct` と `n_significant_cells_1pct` の比率を確認し、有意セルが多すぎる場合は注釈を付与する。

### レポート構成

`vcd_analysis_report.md` を以下の3章構成で Artifact として作成すること：

- **第1章：結論と所見** — サマリー文（1-2文）→ 箇条書き所見 → 推奨アクション（1-2文）
- **第2章：判断根拠** — モデル比較表、AI が選択した gt マトリックス、有意セル数
- **第3章：詳細データ** — DT テーブルへのリンク、全層別マトリックス、Mosaic/Assoc プロット

> [!IMPORTANT]
> デザインは Mermaid シーケンス図による概況、`> [!NOTE]` / `> [!TIP]` バッジを活用し、ビジネスエグゼクティブにそのまま提示できる品質とすること。

## リソース

| パス | 役割 |
| :--- | :--- |
| `references/interface.md` | 共有契約（JSON/CSVスキーマ、命名規則） |
| `references/workflow.md` | 2パスシーケンス図 |
| `references/report-template.md` | 3章構成テンプレート |
| `references/evaluation-criteria.md` | AI判断基準（残差閾値、層別選択ロジック） |
```

- [ ] **Step 2: interface.md をコピー**

```bash
mkdir -p .agent/skills/vcd-categorical-reporting/references
cp .agent/skills/vcd-categorical-analysis/references/interface.md \
   .agent/skills/vcd-categorical-reporting/references/interface.md
```

- [ ] **Step 3: workflow.md を作成**

設計書のシーケンス図を `references/workflow.md` に配置する。

- [ ] **Step 4: report-template.md を作成**

設計書のセクション5（レポート構成）の3章テンプレートを配置。

- [ ] **Step 5: evaluation-criteria.md を作成**

AI判断基準を記載：残差閾値（1.96/2.58）、層別選択ロジック、ハイブリッド記述スタイルの指針。

- [ ] **Step 6: コミット**

```bash
git add .agent/skills/vcd-categorical-reporting/
git commit -m "feat(vcd-reporting): 新スキル vcd-categorical-reporting を作成"
```

---

## Task 6: workflow.md の更新（analysis 側）

**Files:**
- Modify: `.agent/skills/vcd-categorical-analysis/references/workflow.md`

- [ ] **Step 1: 2パス方式のシーケンス図に更新**

既存の workflow.md を設計書の2パスシーケンス図で置換する。

- [ ] **Step 2: コミット**

```bash
git add .agent/skills/vcd-categorical-analysis/references/workflow.md
git commit -m "docs(vcd-analysis): workflow.md を2パス方式に更新"
```

---

## Task 7: .cursor へのミラーリング

**Files:**
- Mirror: `.agent/skills/vcd-categorical-analysis/` → `.cursor/skills/vcd-categorical-analysis/`
- Mirror: `.agent/skills/vcd-categorical-reporting/` → `.cursor/skills/vcd-categorical-reporting/`

- [ ] **Step 1: ミラーコピー**

```bash
cp -r .agent/skills/vcd-categorical-analysis/* .cursor/skills/vcd-categorical-analysis/
mkdir -p .cursor/skills/vcd-categorical-reporting/references
cp -r .agent/skills/vcd-categorical-reporting/* .cursor/skills/vcd-categorical-reporting/
```

- [ ] **Step 2: コミット**

```bash
git add .cursor/skills/vcd-categorical-analysis/ .cursor/skills/vcd-categorical-reporting/
git commit -m "chore: .cursor スキルディレクトリをミラー同期"
```

---

## Task 8: 統合テスト（Q09_long.csv）

**Files:**
- None (テスト実行のみ)

- [ ] **Step 1: Pass 1 テスト**

`analysis.R` のデータソースを Q09_long.csv に差し替えて実行し、`data_profile.json` が正しく生成されることを確認。

- [ ] **Step 2: render_config.json を作成**

Pass 1 の結果を見て AI が判断し、適切な `render_config.json` を生成。

- [ ] **Step 3: Pass 2 テスト**

```bash
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R \
  --render --config render_config.json
```

Expected: `summary_q09.json`, `matrix_marginal_q09.html`, `dt_residuals_q09.html` 等が生成される。

- [ ] **Step 4: gt マトリックスの表示確認**

生成された `matrix_marginal_q09.html` をブラウザで開き、青赤グラデーション＋数値表示を確認。

- [ ] **Step 5: DT テーブルの表示確認**

生成された `dt_residuals_q09.html` をブラウザで開き、ソート・フィルタ・着色を確認。

- [ ] **Step 6: レポート生成テスト**

`vcd-categorical-reporting` のSKILL.md 手順に従い、`vcd_analysis_report.md` を作成。3章構成＋判断ファーストを確認。

- [ ] **Step 7: 最終コミット**

```bash
git add -A
git commit -m "test: Q09_long.csv による統合テスト完了"
```
