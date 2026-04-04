---
name: vcd-categorical-analysis
description: 名義カテゴリカル変数（最大 3-way）のクロス表・独立性・残差分析のための R パイプライン。2パス方式で data_profile.json（Pass 1）と統計成果物（Pass 2）を生成する。AI解釈・レポート構成は `vcd-categorical-reporting` を参照。
license: MIT
metadata:
  author: vcd-categorical-analysis-skill
  version: "2.0"
---

名義カテゴリのクロス表・独立性・**Pearson 残差**・**vcd** 可視化・**Poisson 対数線形（GLM）** を、2パス方式の R パイプラインで支援する。

## スコープ

| 項目 | 内容 |
| :--- | :--- |
| **次元** | **3-way まで**（`xtabs(~ A + B + C, data)`）。**4-way 以上は対象外**（ユーザーに明示し、分割・集約を提案）。 |
| **主用途** | 比率・クロス表・独立性からの乖離（Pearson 残差の解釈）。 |
| **可視化** | Mosaic / Association / Conditional mosaic（PNG）、gt 残差マトリックス（HTML）、DT ソート可能テーブル（HTML） |

## 出力先

分析成果物はプロジェクトルートの **`./skill_out/vcd_categorical/`** に出力する。

## 2パス方式

### Pass 1: プロファイリング（軽量）

```bash
Rscript analysis.R --profile
```

データの次元・水準数・疎密度を `data_profile.json` に出力する。AI はこの情報をもとに表示パラメータ（`render_config.json`）を決定する。

### Pass 2: 本生成（パラメータ付き）

```bash
Rscript analysis.R --render --config render_config.json
```

`render_config.json` に基づき以下を生成する：

| 成果物 | 形式 | 説明 |
| :--- | :--- | :--- |
| `summary_{data}.json` | JSON | モデル比較指標、上位残差、層別統計 |
| `residuals_{data}.csv` | CSV | 全残差データ（Main + 2-Way） |
| `residuals_{data}_significant.csv` | CSV | 上位残差の抽出版 |
| `matrix_marginal_{data}.html` | gt HTML | 周辺残差マトリックス（青赤グラデーション） |
| `matrix_{data}_{layer}.html` | gt HTML | 層別残差マトリックス |
| `dt_residuals_{data}.html` | DT HTML | ソート可能インタラクティブテーブル |
| `mosaic_{data}.png` | PNG | Mosaic プロット |
| `assoc_{data}.png` / `cotab_{data}.png` | PNG | Association / Conditional mosaic |

## R 関数構成

| 関数 | Pass | 役割 |
| :--- | :--- | :--- |
| `generate_profile()` | 1 | データプロファイル出力 |
| `generate_data()` | 2 | GLM フィッティング、残差計算、JSON/CSV 出力 |
| `generate_gt_matrix()` | 2 | gt ピボット残差マトリックス |
| `generate_dt_table()` | 2 | DT ソート可能テーブル |
| `generate_plots()` | 2 | Mosaic / Association PNG |

## モデル（概要）

- **2-way**: `stats::chisq.test` と `glm(count ~ A * B, family = poisson)`。
- **3-way**: 主効果のみ → 2因子交互作用 → 飽和を `stats::anova(..., test = "Chisq")` で比較。
- **gnm** や対称性モデルは **オプション**（`references/glm-gnm-goodness.md`）。

## リソースの使い分け

| パス | 役割 |
| :--- | :--- |
| `templates/analysis.R` | 5関数構成の R パイプライン（2パス対応） |
| `references/interface.md` | 共有契約（JSON/CSVスキーマ、命名規則） |
| `references/workflow.md` | 2パスシーケンス図 |
| `references/dependencies.md` | 依存パッケージ一覧 |
| `references/glm-gnm-goodness.md` | GLM/gnm モデル詳細 |
| `references/ordinal-likert-advanced.md` | 序数リッカート応用 |

## 連携スキル

- **後続**: `vcd-categorical-reporting` が本スキルの出力を読み取り、AI判断レポートを生成する。
- **契約**: `references/interface.md` を参照。

## 関連スキル（任意）

DB からの件数・スキーマ確認が先に必要なら、本リポジトリの **`mysql-table-cardinality`** を参照。

## 配置

- **Cursor**: `.cursor/skills/vcd-categorical-analysis/`
- **Antigravity**: `.agent/skills/vcd-categorical-analysis/`（**同一内容をミラー**）
