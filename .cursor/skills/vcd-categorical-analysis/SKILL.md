---
name: vcd-categorical-analysis
description: アンケート等の名義カテゴリカル変数（最大 3-way）に対し、クロス表・独立性検定・Pearson 残差（色分け表）・mosaic/assoc 可視化・対数線形モデル適合度を R コードまたは R Markdown テンプレとして生成する。出力は ./skill_out/vcd_categorical/。序数リッカートの扱いは references の高度な分析に誘導する。
license: MIT
metadata:
  author: vcd-categorical-analysis-skill
  version: "1.0"
---

名義カテゴリのクロス表・独立性・**Pearson 残差**・**vcd** 可視化・**Poisson 対数線形（GLM）** を、コピー実行可能な `templates/` と詳細な `references/` で支援する。エージェントは **R を必ず実行しない**前提で、コード／Rmd を生成する。

## スコープ

| 項目 | 内容 |
|------|------|
| **次元** | **3-way まで**（`xtabs(~ A + B + C, data)`）。**4-way 以上は対象外**（ユーザーに明示し、分割・集約を提案）。 |
| **主用途** | 比率・クロス表・独立性からの乖離（Pearson 残差の解釈）。 |
| **可視化** | **主**: `vcd::mosaic(..., shade = TRUE)`。**補**: `vcd::assoc(..., residuals_type = "Pearson", shade = TRUE)`（着色し忘れに注意）。 |
| **残差表** | **既定は `gt`（HTML）**。PDF/LaTeX 主目的は `params$residual_table_pkg: "kableExtra"`（`references/dependencies.md`）。 |
| **対象外** | **Correlogram**（連続変数の相関ヒートマップ等）。多数項目のざっくり関連は `references/literature-and-packages.md` の **Cramer's V 参考**のみ。 |
| **序数・リッカート** | メインは 1 段落。**詳細は** `references/ordinal-likert-advanced.md`。 |

## 出力先

分析例・図表・レンダー結果はプロジェクトルートの **`./skill_out/vcd_categorical/`**（必要に応じて `ordinal/` 等のサブディレクトリ）。

## リソースの使い分け

| パス | 役割 |
|------|------|
| `templates/analysis.R` | 最小の純 R パイプライン。 |
| `templates/report.Rmd` | 推奨。`params` でデータ・変数・出力先・残差表パッケージを指定。 |
| `references/` | ワークフロー、スニペット、GLM/gnm、序数、文献・パッケージ、依存一覧。 |

詳細は **`references/workflow.md`**。パッケージ一覧は **`references/dependencies.md`**（**R Markdown 利用時は `rmarkdown` / `knitr` が実質必須**）。

## モデル（概要）

- **2-way**: `chisq.test` と `glm(count ~ A * B, family = poisson)`（対数線形）を併記。
- **3-way**: 主効果のみ → 2 因子交互作用まで → 飽和、を **`anova(..., test = "Chisq")`** で比較（スニペットは `references/glm-gnm-goodness.md` と `templates/report.Rmd`）。
- **gnm** や対称性モデルは **オプション**（`references/glm-gnm-goodness.md`）。

## 追加リソース（リンクは 1 段まで）

- **`references/literature-and-packages.md`** … vcd / vcdExtra / Agresti / Friendly / Blog 等への誘導を集約。
- **ヘルプ**: `?vcd::mosaic`、`?vcd::assoc`。

## 関連スキル（任意）

DB からの件数・スキーマ確認が先に必要なら、本リポジトリの **`mysql-table-cardinality`**（`.cursor/skills/mysql-table-cardinality/`）を参照。データ取得〜前処理の分担は `references/workflow.md`。

## 配置

- **Cursor**: `.cursor/skills/vcd-categorical-analysis/`
- **Antigravity**: `.agent/skills/vcd-categorical-analysis/`（**同一内容をミラー**）
