---
name: vcd-categorical-analysis
description: "【必須3ステップ】1. analysis.Rで集計 2. executive_summary.mdを保存 3. dashboard.Rmd（既定）またはreport.RmdでHTML化。AI考察は本スキル内で完結（vcd-categorical-reportingは非推奨）。"
license: MIT
metadata:
  author: vcd-categorical-analysis-skill
  version: "3.0"
---

名義カテゴリカル変数（最大 3-way）の独立性検定（Poisson GLM）および残差の可視化を行う。**3ステップ方式**で集計・AI考察・レポート生成までを一貫して行う。

## スコープ

| 項目 | 内容 |
| :--- | :--- |
| **次元** | **3-way まで**。4-way 以上は対象外（分割・集約を提案）。 |
| **出力先** | `./skill_out/vcd_categorical/` |
| **配置** | 正本 `.agent/skills/`、Cursor は `.cursor/skills/` にミラー |

## 必須ワークフロー（実行フェーズ）

ユーザーが **「実行して」** 等で実行フェーズに入った後、本スキル呼び出し時は **以下3ステップを連続実行**する。Step 1 完了前にチャットで要約して終了しない。

1. **Step 1（Data）**: `analysis.R` を実行し、`categorical_results.json`（および `summary_*.json` 等）が生成されたことを確認する。
2. **Step 2（AI Review）**: JSON を読み、日本語考察を **`executive_summary.md`** として保存する（チャットへの長文出力のみで代替しない）。判断ファーストの詳細が必要な場合は同ディレクトリに `vcd_analysis_report.md` も可。
3. **Step 3（Report）**: **既定は `dashboard.Rmd`**。`--template report` 指定時は `report.Rmd` をレンダリングする。HTML 生成を確認してから完了報告する。

## Step 1: R Engine

```bash
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R \
  --render \
  --data your_data.csv \
  --vars "var1,var2" \
  --freq "Freq" \
  --label "mydata" \
  --out ./skill_out/vcd_categorical/
```

任意: 表示パラメータを調整する場合は先に `--profile` で `data_profile.json` を確認し、`render_config.json` を用意して `--config render_config.json` を付与する。

`--data` 省略時は内蔵 `HairEyeColor` を使用。

## Step 2: AI 考察

`categorical_results.json` を読み、`executive_summary.md` を生成する。

**構成（最低限）**:
- 節1: Cramér's V と Cohen 基準による全体関連
- 節2: `abs_pearson_res` ≥ 1.96 のセル（偏りの方向）
- 節3: 結論と実務的示唆

**禁止**: 英語本文（変数名・数式除く）、P値のみでの結論。

詳細な判断ファースト3章構成は、旧 `vcd-categorical-reporting/references/report-template.md` を参照可。

## Step 3: レポート（テンプレ選択）

### 既定: dashboard.Rmd

```bash
Rscript -e "rmarkdown::render(
  '.agent/skills/vcd-categorical-analysis/templates/dashboard.Rmd',
  output_file = 'dashboard.html',
  output_dir = './skill_out/vcd_categorical/',
  params = list(output_dir = './skill_out/vcd_categorical/'),
  knit_root_dir = getwd()
)"
```

### 代替: report.Rmd（レガシー・gt/DT 中心）

```bash
Rscript -e "rmarkdown::render(
  '.agent/skills/vcd-categorical-analysis/templates/report.Rmd',
  output_file = 'report.html',
  output_dir = './skill_out/vcd_categorical/',
  params = list(output_dir = './skill_out/vcd_categorical/'),
  knit_root_dir = getwd()
)"
```

## 生成ファイル

| 出力 | Step | 説明 |
| :--- | :--- | :--- |
| `categorical_results.json` | 1 | Cramér's V、全セル残差 |
| `summary_*.json`, `residuals_*.csv` | 1 | 詳細統計（config 使用時） |
| `executive_summary.md` | 2 | AI 日本語サマリー |
| `dashboard.html` | 3（既定） | 統合ダッシュボード |
| `report.html` | 3（代替） | レガシー Rmd レポート |

## リソース

| パス | 役割 |
| :--- | :--- |
| `templates/analysis.R` | 集計パイプライン |
| `templates/dashboard.Rmd` | **既定** HTML ダッシュボード |
| `templates/report.Rmd` | 代替 Rmd（v2.x 互換） |
| `references/interface.md` | JSON/CSV 契約 |
| `references/dependencies.md` | R パッケージ |
| `references/workflow.md` | 3ステップ図 |
| `tests/verify_skill.sh` | 検証スクリプト |

## 関連スキル

- `vcd-bayesian-evidence-analysis` … 大標本時の効果量・BIC/BF 視点
- `vcd-categorical-reporting` … **非推奨**（本スキル Step 2 に統合）
- `mysql-table-cardinality` … DB 探索が先の場合
