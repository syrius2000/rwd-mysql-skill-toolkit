---
name: questionnaire-batch-analysis
description: 複数設問のアンケート結果を CSV 設定ファイルで自動走査し、名義カテゴリと序数リッカートを一括でクロス集計・独立性検定・残差可視化するための R / Rmd テンプレートを生成する。question_config.csv と summary.csv 仕様を固定し、初心者にも分かる ggplot2 のモデル乖離（Pearson 残差）可視化を含む。出力は ./skill_out/questionnaire/。
license: MIT
metadata:
  author: questionnaire-batch-analysis-skill
  version: "1.0"
---

複数設問の分析を `question_config.csv` で制御し、設問ごとの HTML レポートと全体集約 `summary.csv` を生成する。エージェントは R を実行せず、実行可能テンプレートを作成する。

## スコープ

| 項目 | 内容 |
| ---- | ---- |
| 対象 | 名義カテゴリ + 序数リッカート |
| 次元 | 2-way / 3-way |
| 入力 | survey 本体 CSV + question_config.csv |
| 出力 | 設問別 HTML + 図表 + 集約 summary.csv |
| 中核可視化 | ggplot2 による Pearson 残差（モデル乖離） |
| 対象外 | 連続値解析、4-way 以上、Excel 直接読込 |

## ディレクトリ

- `templates/report.Rmd`: 設問単位の分析テンプレート
- `templates/batch_runner.R`: 設問CSVを順次処理して集約を作成
- `examples/question_config_example.csv`: 設定CSVの実例
- `references/survey_prep.md`: 入力CSV準備の要点
- `references/interpretation.md`: レポートの読み方

## question_config.csv 仕様

必須列:

- `survey_id`
- `question_id`
- `analysis_type` (`nominal_2way`, `nominal_3way`, `likert_2way`, `likert_3way`)
- `var1`
- `var2`
- `output_slug`

任意列:

- `var3`
- `question_label`
- `subset_expr`
- `na_policy` (`drop`, `explicit_level`)
- `ordered_levels` (`|` 区切り)
- `reference_note`

## summary.csv 仕様

必須列:

- `run_id`
- `survey_id`
- `question_id`
- `analysis_type`
- `variables`
- `subset_expr_applied`
- `na_policy`
- `n_total`
- `n_used`
- `n_missing`
- `model_name`
- `statistic_name`
- `statistic_value`
- `df`
- `p_value`
- `effect_name`
- `effect_value`
- `max_abs_pearson_res`
- `max_residual_cell`
- `residual_plot_path`
- `mosaic_plot_path`
- `assoc_plot_path`
- `report_path`
- `status`
- `error_message`
- `executed_at`

## 実行例

```bash
Rscript .agent/skills/questionnaire-batch-analysis/templates/batch_runner.R \
  --data ./data/survey.csv \
  --config .agent/skills/questionnaire-batch-analysis/examples/question_config_example.csv \
  --out ./skill_out/questionnaire
```

## 注意

- `analysis_type` が `likert_*` の場合、`ordered_levels` をできるだけ指定する。
- 3-way は分かりにくくなりやすいので、残差図で乖離上位セルを確認する。
- `.agent` と `.cursor` で同一内容を維持する。
