#!/usr/bin/env Rscript
# =============================================================================
# vcd-bayesian-evidence-analysis: analysis.R
# Pass 1: Poisson GLM + BIC近似ベイズファクター + Evidence Score 算出
# =============================================================================
# Evidence Score = r^2 - k*log(N)
#   r    : 標準化ピアソン残差 (Poisson GLM 独立モデルより)
#   k*log(N): BIC ペナルティ項（多段階閾値）
#   正値  : 実質的エビデンス（統計ノイズを超える真の関連）
#   負値  : ノイズレベル（独立モデルで説明可能）
# =============================================================================

`%||%` <- function(x, y) if (is.null(x)) y else x

suppressPackageStartupMessages({
  if (!base::requireNamespace("pacman", quietly = TRUE)) {
    utils::install.packages("pacman", repos = "https://cloud.r-project.org")
  }
  pacman::p_load(dplyr, tidyr, jsonlite, DT, htmlwidgets, htmltools, effectsize)
})

# -----------------------------------------------------------------------------
# CLI 引数パース
# -----------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  result <- list(
    input              = NULL,
    output_dir         = "./skill_out/vcd_bayesian",
    dataset_name       = "dataset",
    vars               = NULL,
    freq               = "Freq",
    top_k              = 10L,
    threshold_k        = 1,
    large_n_threshold  = 1000,
    show_help          = FALSE,
    show_help_stats    = FALSE
  )
  i <- 1L
  while (i <= length(args)) {
    switch(args[i],
      "--input" = {
        i <- i + 1L
        result$input <- args[i]
      },
      "--output_dir" = {
        i <- i + 1L
        result$output_dir <- args[i]
      },
      "--dataset_name" = {
        i <- i + 1L
        result$dataset_name <- args[i]
      },
      "--vars" = {
        i <- i + 1L
        # カンマ区切りを分解し、前後の空白を除去
        raw_vars <- strsplit(args[i], ",")[[1]]
        result$vars <- trimws(raw_vars)
      },
      "--freq" = {
        i <- i + 1L
        result$freq <- args[i]
      },
      "--top_k" = {
        i <- i + 1L
        result$top_k <- as.integer(args[i])
      },
      "--threshold_k" = {
        i <- i + 1L
        result$threshold_k <- as.numeric(args[i])
      },
      "--large_n_threshold" = {
        i <- i + 1L
        result$large_n_threshold <- as.numeric(args[i])
      },
      "--help" = {
        result$show_help <- TRUE
      },
      "--help_stats" = {
        result$show_help_stats <- TRUE
      }
    )
    i <- i + 1L
  }
  result
}

cfg <- parse_args(args)

# --help
if (isTRUE(cfg$show_help)) {
  cat("
Usage: Rscript analysis.R [OPTIONS]

Options:
  --input <file>            入力CSVファイル（省略時: HairEyeColor）
  --output_dir <dir>        出力ディレクトリ（既定: ./skill_out/vcd_bayesian）
  --dataset_name <name>     データセット名（既定: dataset）
  --vars <v1,v2,...>        分析変数（カンマ区切り、省略時: 全変数）
  --freq <col>              度数列名（既定: Freq）
  --top_k <N>               Top-K 表示件数（既定: 10）
  --threshold_k <k>         多段階閾値係数 Score > k*log(N)（既定: 1）
  --large_n_threshold <N>   大規模データモード閾値（既定: 1000）
  --help                    このヘルプを表示
  --help_stats              統計指標ガイドを表示
")
  quit(status = 0L)
}

# --help_stats
if (isTRUE(cfg$show_help_stats)) {
  cat("
=================================================================
 統計指標ガイド（vcd-bayesian-evidence-analysis）
=================================================================

 ■ Evidence Score = r² − log(N)
   各セルが「独立モデルからどれだけ逸脱しているか」を測る指標。
   正値 → 真の関連（ノイズを超える逸脱）
   負値 → ノイズ範囲（偶然で説明可能）

 ■ ベイズファクター（BF10）
   「変数間に関連がある」vs「独立」仮説の証拠比。
   BF > 100: 決定的  BF > 10: 強い  BF > 3: 中程度

 ■ Cramér's V（0〜1）
   変数間の関連の「強さ」。サンプルサイズに依存しない。
   0.1未満: 弱い  0.3前後: 中程度  0.5以上: 強い
   ※ Cohen (1988) 基準

 ■ 標準化ピアソン残差（r）
   正(+): 期待より多い（過剰）  負(−): 期待より少ない（過少）

 ■ 大規模データモード（N > 1,000）
   P値が飽和しやすい大標本では、効果量（Cramér's V）を
   優先して解釈します。Evidence Score の閾値も調整可能です。
=================================================================
")
  quit(status = 0L)
}

# -----------------------------------------------------------------------------
# データ読み込み
# -----------------------------------------------------------------------------
load_data <- function(cfg) {
  if (is.null(cfg$input)) {
    # デフォルト: HairEyeColor (3D 組み込みデータセット)
    message("[INFO] --input 未指定。HairEyeColor データセットを使用します。")
    df <- as.data.frame(HairEyeColor)
    # 列名: Hair, Eye, Sex, Freq
    return(df)
  }

  if (!file.exists(cfg$input)) {
    stop(paste("[ERROR] 入力ファイルが見つかりません:", cfg$input))
  }
  df <- read.csv(cfg$input, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  message(paste("[INFO] データ読み込み完了:", nrow(df), "行,", ncol(df), "列"))
  df
}

df_raw <- load_data(cfg)

# -----------------------------------------------------------------------------
# 変数選択と度数列の確認
# -----------------------------------------------------------------------------
freq_col <- cfg$freq

# 度数列が存在しない場合: 非集計データとして行数をカウント
if (!(freq_col %in% names(df_raw))) {
  message(paste("[INFO]", freq_col, "列が見つかりません。行数を度数として集計します。"))
  cat_vars <- if (!is.null(cfg$vars)) cfg$vars else names(df_raw)
  df_raw <- df_raw %>%
    group_by(across(all_of(cat_vars))) %>%
    summarise(Freq = n(), .groups = "drop")
  freq_col <- "Freq"
}

# カテゴリカル変数の決定
if (!is.null(cfg$vars)) {
  cat_vars <- cfg$vars
} else {
  cat_vars <- setdiff(names(df_raw), freq_col)
}

message(paste("[INFO] 分析変数:", paste(cat_vars, collapse = ", ")))
message(paste("[INFO] 度数列:", freq_col))

# 文字列型に統一
df_raw[cat_vars] <- lapply(df_raw[cat_vars], as.character)
df_raw[[freq_col]] <- as.numeric(df_raw[[freq_col]])

# NA除去
df <- df_raw %>% filter(!is.na(.data[[freq_col]]), .data[[freq_col]] >= 0)

# -----------------------------------------------------------------------------
# Poisson GLM: 独立モデル（交互作用なし）と飽和モデル
# -----------------------------------------------------------------------------
n_total <- sum(df[[freq_col]])
log_n <- log(n_total)

message(paste("[INFO] 総度数 N =", n_total, "/ log(N) =", round(log_n, 4)))

# 独立モデル: Freq ~ var1 + var2 + ... (主効果のみ)
formula_indep <- as.formula(
  paste(freq_col, "~", paste(cat_vars, collapse = " + "))
)

# 飽和モデル: Freq ~ var1 * var2 * ... (全交互作用)
formula_satur <- as.formula(
  paste(freq_col, "~", paste(cat_vars, collapse = " * "))
)

message("[INFO] Poisson GLM 独立モデルを適合中...")
glm_indep <- glm(formula_indep, data = df, family = poisson(link = "log"))

message("[INFO] Poisson GLM 飽和モデルを適合中...")
glm_satur <- glm(formula_satur, data = df, family = poisson(link = "log"))

# -----------------------------------------------------------------------------
# BIC近似によるベイズファクター計算
# -----------------------------------------------------------------------------
# BIC = -2 * logLik + df * log(N)
bic_indep <- BIC(glm_indep)
bic_satur <- BIC(glm_satur)

delta_bic <- bic_indep - bic_satur # 正 → 独立モデルが悪い → 関連あり
log_bf <- 0.5 * delta_bic # log BF10 ≈ -0.5 * ΔBIC (符号注意)
bf_val <- exp(log_bf)

bf_str <- if (is.infinite(bf_val)) {
  "Inf"
} else if (bf_val > 10000 || bf_val < 0.001) {
  formatC(bf_val, format = "e", digits = 4)
} else {
  as.character(round(bf_val, 4))
}

message(paste("[INFO] BIC(独立) =", round(bic_indep, 2)))
message(paste("[INFO] BIC(飽和) =", round(bic_satur, 2)))
message(paste("[INFO] ΔBIC =", round(delta_bic, 2), "/ log BF =", round(log_bf, 4)))
message(paste("[INFO] BF10 =", bf_str))

# Jeffreys スケール解釈
interpret_bf <- function(bf) {
  if (is.infinite(bf) || bf > 100) {
    return("決定的エビデンス (decisive)")
  }
  if (bf > 30) {
    return("非常に強いエビデンス (very strong)")
  }
  if (bf > 10) {
    return("強いエビデンス (strong)")
  }
  if (bf > 3) {
    return("中程度のエビデンス (moderate)")
  }
  if (bf > 1) {
    return("弱いエビデンス (anecdotal)")
  }
  return("関連なし / 独立仮説を支持")
}
message(paste("[INFO] BF解釈:", interpret_bf(bf_val)))

# -----------------------------------------------------------------------------
# Cramér's V（効果量）算出
# -----------------------------------------------------------------------------
ct <- xtabs(as.formula(paste(freq_col, "~", paste(cat_vars, collapse = " + "))), data = df)
cv_result <- tryCatch(
  {
    if (length(cat_vars) == 2L) {
      effectsize::cramers_v(ct, ci = 0.95)
    } else {
      effectsize::cramers_v(stats::chisq.test(stats::ftable(ct)), ci = 0.95)
    }
  },
  error = function(e) {
    message(paste("[WARN] Cramér's V 算出失敗:", e$message))
    NULL
  }
)

cramers_v_val <- NA_real_
cramers_v_ci_low <- NA_real_
cramers_v_ci_high <- NA_real_
if (!is.null(cv_result)) {
  cramers_v_val <- if ("Cramers_v_adjusted" %in% names(cv_result)) {
    as.numeric(cv_result$Cramers_v_adjusted)
  } else if ("Cramers_v" %in% names(cv_result)) {
    as.numeric(cv_result$Cramers_v)
  } else {
    as.numeric(cv_result[[1L]])
  }
  cramers_v_ci_low <- as.numeric(cv_result$CI_low)
  cramers_v_ci_high <- as.numeric(cv_result$CI_high)
  message(paste(
    "[INFO] Cramér's V =", round(cramers_v_val, 4),
    " [", round(cramers_v_ci_low, 4), ",", round(cramers_v_ci_high, 4), "]"
  ))
}

# -----------------------------------------------------------------------------
# 大規模データモード判定
# -----------------------------------------------------------------------------
large_sample_mode <- n_total > cfg$large_n_threshold
if (large_sample_mode) {
  message(paste("[INFO] 大規模データモード: N =", n_total, ">", cfg$large_n_threshold))
  message("[INFO] → 効果量（Cramér's V）を優先して解釈します。")
}

# -----------------------------------------------------------------------------
# Evidence Score 算出
# -----------------------------------------------------------------------------
threshold <- cfg$threshold_k * log_n

# 標準化ピアソン残差: (観測 - 期待) / sqrt(期待)
df$Expected <- fitted(glm_indep)
df$Residual <- residuals(glm_indep, type = "pearson")
df$Evidence_Score <- df$Residual^2 - threshold

n_positive <- sum(df$Evidence_Score > 0)
n_total_cells <- nrow(df)
message(paste("[INFO] Evidence Score 正値セル数:", n_positive, "/", n_total_cells))
message(paste(
  "[INFO] threshold (k * log_n) =", round(threshold, 4),
  " (k =", cfg$threshold_k, ")"
))

# -----------------------------------------------------------------------------
# 出力ディレクトリ作成
# -----------------------------------------------------------------------------
if (!dir.exists(cfg$output_dir)) {
  dir.create(cfg$output_dir, recursive = TRUE)
  message(paste("[INFO] 出力ディレクトリ作成:", cfg$output_dir))
}

# -----------------------------------------------------------------------------
# evidence_results.json 出力
# -----------------------------------------------------------------------------
# full_data: 全セルデータ（Evidence Score 降順）
full_data <- df %>%
  select(all_of(c(cat_vars, freq_col, "Expected", "Residual", "Evidence_Score"))) %>%
  arrange(desc(Evidence_Score)) %>%
  mutate(
    across(where(is.numeric), ~ round(., 4))
  )

# 列名を統一（度数列を Freq に）
names(full_data)[names(full_data) == freq_col] <- "Freq"

result_list <- list(
  dataset_name       = cfg$dataset_name,
  dimensions         = cat_vars,
  n_total            = n_total,
  bf_independence    = bf_str,
  log_n              = round(log_n, 4),
  threshold          = round(threshold, 4),
  threshold_k        = cfg$threshold_k,
  bic_indep          = round(bic_indep, 4),
  bic_satur          = round(bic_satur, 4),
  delta_bic          = round(delta_bic, 4),
  cramers_v          = round(cramers_v_val, 4),
  cramers_v_ci_low   = round(cramers_v_ci_low, 4),
  cramers_v_ci_high  = round(cramers_v_ci_high, 4),
  large_sample_mode  = large_sample_mode,
  large_n_threshold  = cfg$large_n_threshold,
  n_cells            = n_total_cells,
  n_evidence_cells   = n_positive,
  top_k              = cfg$top_k,
  top_k_data         = head(full_data, cfg$top_k),
  full_data          = full_data
)

json_path <- file.path(cfg$output_dir, "evidence_results.json")
write_json(result_list, json_path, pretty = TRUE, auto_unbox = TRUE)
message(paste("[INFO] JSON出力:", json_path))

# -----------------------------------------------------------------------------
# DT テーブル（列フィルタ付きHTMLウィジェット）
# -----------------------------------------------------------------------------
# 日本語ラベルへ変換
dt_data <- full_data
names(dt_data)[names(dt_data) == "Freq"] <- "\u5ea6\u6570"
names(dt_data)[names(dt_data) == "Expected"] <- "\u671f\u5f85\u5024"
names(dt_data)[names(dt_data) == "Residual"] <- "\u6a19\u6e96\u6b8b\u5dee"
names(dt_data)[names(dt_data) == "Evidence_Score"] <- "\u30a8\u30d3\u30c7\u30f3\u30b9\u30fb\u30b9\u30b3\u30a2"

# Evidence Score の正負で行の色分け（列名は Unicode 変数で参照）
es_col_name <- "\u30a8\u30d3\u30c7\u30f3\u30b9\u30fb\u30b9\u30b3\u30a2"

for (v in cat_vars) {
  if (v %in% names(dt_data)) {
    dt_data[[v]] <- factor(dt_data[[v]], levels = sort(unique(as.character(dt_data[[v]]))))
  }
}

cv_caption <- if (!is.na(cramers_v_val)) {
  paste0(" | Cram\u00e9r's V = ", round(cramers_v_val, 4))
} else {
  ""
}

dt_widget <- datatable(
  dt_data,
  filter = "top",
  rownames = FALSE,
  caption = htmltools::tags$caption(
    style = "caption-side: top; text-align: left; font-size: 14px; font-weight: bold;",
    paste0(
      "\u591a\u6b21\u5143\u30a8\u30d3\u30c7\u30f3\u30b9\u5206\u6790: ",
      paste(cat_vars, collapse = " \u00d7 "),
      " (N = ", format(n_total, big.mark = ","), ")",
      " | BF10 = ", bf_str,
      " | threshold = ", round(threshold, 2),
      cv_caption
    )
  ),
  options = list(
    pageLength = 20,
    scrollX = TRUE,
    language = list(
      url = "https://cdn.datatables.net/plug-ins/1.13.6/i18n/ja.json"
    )
  )
) %>%
  formatStyle(
    es_col_name,
    backgroundColor = styleInterval(0, c("#fff3cd", "#d4edda")),
    fontWeight = "bold"
  ) %>%
  formatStyle(
    "\u6a19\u6e96\u6b8b\u5dee",
    color = styleInterval(0, c("#e74c3c", "#2980b9"))
  ) %>%
  formatRound(
    c("\u671f\u5f85\u5024", "\u6a19\u6e96\u6b8b\u5dee", es_col_name),
    digits = 4
  )

dt_path <- file.path(cfg$output_dir, "dt_table.html")
saveWidget(dt_widget, dt_path, selfcontained = TRUE, libdir = NULL)
message(paste("[INFO] DTテーブル出力:", dt_path))

# -----------------------------------------------------------------------------
# サマリーをコンソールに表示
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat(" vcd-bayesian-evidence-analysis: Pass 1 完了\n")
cat("=================================================================\n")
cat(paste0(" 分析変数    : ", paste(cat_vars, collapse = " × "), "\n"))
cat(paste0(" 総度数 N    : ", format(n_total, big.mark = ","), "\n"))
cat(paste0(" セル数      : ", n_total_cells, "\n"))
cat(paste0(
  " threshold   : ", round(threshold, 4), " (k=", cfg$threshold_k,
  " × log(N)=", round(log_n, 4), ")\n"
))
cat(paste0(" BF10        : ", bf_str, "  (", interpret_bf(bf_val), ")\n"))
if (!is.na(cramers_v_val)) {
  cat(paste0(
    " Cramér's V  : ", round(cramers_v_val, 4),
    " [", round(cramers_v_ci_low, 4), ", ", round(cramers_v_ci_high, 4), "]\n"
  ))
}
if (large_sample_mode) {
  cat(" ** 大規模データモード: 効果量を優先して解釈してください **\n")
}
cat(paste0(
  " 正値セル    : ", n_positive, " / ", n_total_cells,
  " (", round(n_positive / n_total_cells * 100, 1), "%)\n"
))
cat("\n")

BLUE <- "\033[34m"
RED <- "\033[31m"
RESET <- "\033[0m"

topk_data <- head(full_data, cfg$top_k)
cat(paste0(" [Top-", cfg$top_k, " Evidence Score セル]\n"))
for (i in seq_len(nrow(topk_data))) {
  cell_label <- paste(
    sapply(cat_vars, function(v) paste0(v, "=", topk_data[[v]][i])),
    collapse = ", "
  )
  r_val <- topk_data$Residual[i]
  color <- if (r_val >= 0) BLUE else RED
  direction <- if (r_val >= 0) "(+)" else "(-)"
  cat(paste0(
    "  ", i, ". ", color, cell_label,
    "  Score=", round(topk_data$Evidence_Score[i], 2),
    "  r=", round(r_val, 4),
    " ", direction, RESET, "\n"
  ))
}
cat("\n")
cat(" [出力ファイル]\n")
cat(paste0("  - ", json_path, "\n"))
cat(paste0("  - ", dt_path, "\n"))
cat("=================================================================\n")
cat(" 次のステップ: Pass 2 (AI考察) → SKILL.md の指示に従い\n")
cat("               executive_summary.md を生成してください。\n")
cat("=================================================================\n")
