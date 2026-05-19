---
name: vcd-categorical-analysis
description: "【必須3ステップ】1. analysis.R（R 2パス: profile→render）2. executive_summary.md 3. dashboard.Rmd。2-way/3-way 名義カテゴリ。vcd-categorical-reporting は非推奨。"
license: MIT
metadata:
  author: vcd-categorical-analysis-skill
  version: "3.1"
---

名義カテゴリカル変数（クロス表 **2-way / 3-way**）の独立性検定（Poisson GLM）および残差の可視化を行う。**エージェント3ステップ**で集計・AI考察・レポート生成までを一貫して行う。Step 1 の R エンジンは **2パス**（`--profile` → `render_config.json` → `--render`）。

## スコープ

| 項目 | 内容 |
| :--- | :--- |
| **次元** | **3-way まで**。4-way 以上は対象外（分割・集約を提案）。 |
| **出力先** | `./skill_out/vcd_categorical/`（`--run-id` 指定時は `runs/<id>/`） |
| **正本** | `.agent/skills/`。Cursor は `.cursor/skills/` にミラー |

## 必須ワークフロー（実行フェーズ）

ユーザーが **「実行して」** 等で実行フェーズに入った後、**以下3ステップを連続実行**する。Step 1 完了前にチャットで要約して終了しない。

1. **Step 1（Data）**: R **2パス**を完遂し、`summary_*.json`・`categorical_results.json`・残差 CSV/HTML/PNG 等が生成されたことを確認する。
2. **Step 2（AI Review）**: JSON を読み、日本語考察を **`executive_summary.md`** として保存する（チャットへの長文出力のみで代替しない）。詳細が必要な場合は `vcd_analysis_report.md` も可。
3. **Step 3（Report）**: **既定は `dashboard.Rmd`**。`report.Rmd` はレガシー代替。HTML 生成を確認してから完了報告する。

## Step 1: R Engine（2パス）

**IRON LAW**: Pass 2（`--render`）の前に、必ず Pass 1 の `data_profile.json` を確認し、過大セル数・過剰水準に対する `render_config.json` を決める。

### Pass 1: プロファイリング

```bash
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R \
  --profile \
  --data your_data.csv \
  --vars "var1,var2" \
  --freq "Freq" \
  --out ./skill_out/vcd_categorical/ \
  --run-id datasetA_20260417
```

- **`--run-id`（任意）**: 成果物を `<--out>/runs/<id>/` に隔離。`auto` で JST タイムスタンプ ID。
- **`--data` 省略時**: 内蔵 `HairEyeColor` を使用。
- **`--freq` 列が無い場合**: 自動集計し `Freq` として扱う。

### Pass 2: 本生成

`data_profile.json` を読んだうえで `render_config.json` を用意し、本生成を実行する。

```bash
Rscript .agent/skills/vcd-categorical-analysis/templates/analysis.R \
  --render \
  --config render_config.json \
  --data your_data.csv \
  --vars "var1,var2" \
  --freq "Freq" \
  --label "mydata" \
  --out ./skill_out/vcd_categorical/ \
  --run-id datasetA_20260417
```

### Step 1 確認ゲート

- 別データを連続解析する場合は **`--run-id`** でサブフォルダを分ける。
- `--out` が既存の場合、上書き可否を確認する。
- `render_config.json` で `collapse_below_n` 等を使う場合、情報損失の許容可否を確認する。

## Step 2: AI 考察

主に `summary_{label}.json` および `categorical_results.json` を読み、`executive_summary.md` を生成する。

**構成（最低限）**:
- 節1: Cramér's V と Cohen 基準による全体関連
- 節2: `abs_pearson_res` ≥ 1.96 のセル（偏りの方向）
- 節3: 結論と実務的示唆

**禁止**: 英語本文（変数名・数式除く）、P値のみでの結論。

判断ファースト3章の詳細は `vcd-categorical-reporting/references/report-template.md`（非推奨スキル・参照テンプレ）を参照可。

## Step 3: レポート

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

`executive_summary.md` が無いとダッシュボードに警告が出る。Step 2 を省略しない。

### 代替: report.Rmd（レガシー）

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

| 出力 | Step / Pass | 説明 |
| :--- | :--- | :--- |
| `data_profile.json` | Pass 1 | 次元・水準・セル数プロファイル |
| `data_profile_post.json` | Pass 2 | 集約後プロファイル |
| `summary_{label}.json` | Pass 2 | モデル比較・残差統計サマリー |
| `residuals_{label}.csv` 等 | Pass 2 | 残差・gt/DT HTML・PNG |
| `categorical_results.json` | Pass 2 | ダッシュボード連携用 JSON |
| `executive_summary.md` | Step 2 | AI 日本語サマリー |
| `dashboard.html` | Step 3（既定） | 統合ダッシュボード |

## リソース

| パス | 役割 |
| :--- | :--- |
| `templates/analysis.R` | 2パス集計パイプライン |
| `templates/dashboard.Rmd` | **既定** HTML ダッシュボード |
| `templates/report.Rmd` | 代替 Rmd |
| `references/interface.md` | JSON/CSV 契約 |
| `references/workflow.md` | 3ステップ + 2パス図 |
| `tests/verify_skill.sh` | 検証スクリプト |

## 関連スキル

- `vcd-pass0-consultation` … 分析前のデータ検分・次元選定
- `vcd-bayesian-evidence-analysis` … 大標本時の効果量・BIC/BF 視点
- `vcd-categorical-reporting` … **非推奨**（本スキル Step 2 に統合。参照テンプレのみ）
- `mysql-table-cardinality` … DB 探索が先の場合
