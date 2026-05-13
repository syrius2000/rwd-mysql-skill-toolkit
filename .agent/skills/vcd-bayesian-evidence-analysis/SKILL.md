---
name: vcd-bayesian-evidence-analysis
description: 大標本におけるP値と実質的意義の乖離を、Poisson GLM残差、Evidence Score、BIC近似Bayes Factorで評価する3-Pass分析スキル。analysis.R、AI考察、dashboard.Rmdを連携し、出力は ./skill_out/vcd_bayesian/ に保存する。
license: MIT
metadata:
  version: "1.0"
---

大標本における「P値の罠」を克服し、ベイズファクター（BF）とEvidence Score ($r^2 - \log(N)$) を用いて「統計的有意性」と「実質的意義」を峻別するAI連携型分析パイプライン。

## 3-Pass ワークフロー

このスキルを呼び出した場合、以下の3ステップを順に実行する。途中で要約だけを返して終了せず、生成物を確認してから完了報告する。

1. **Step 1 (Data Aggregation)**: `analysis.R` を実行し、`evidence_results.json` が生成されたことを確認する。
2. **Step 2 (AI Review Generation)**: JSONの中身を読み込み、指定されたプロンプトに従って日本語の考察を作成し、`executive_summary.md` として保存する。
3. **Step 3 (Report Integration)**: `dashboard.Rmd` をレンダリングし、HTMLファイルが生成されたことを確認してから、ユーザーに完了を報告する。

## 入力データの前提

- DB から抽出した分析データセットを使う場合は、可能な限り `sql/validated/` 配下の SQL と `query_note.md` を参照し、抽出条件と粒度を確認する。
- `sql/drafts/` の SQL から得たデータを使う場合は、未検証であることをレポートに明記する。

## 統計的背景

### Evidence Score

$$\text{Evidence Score} = r_{ijk}^2 - \log(N)$$

- $r_{ijk}$: Poisson GLM による標準化ピアソン残差
- $\log(N)$: BIC ペナルティ項（モデル複雑化コスト）
- **正値 → 実質的エビデンス**（統計ノイズを超える真の関連）
- **負値 → ノイズレベル**（独立モデルで説明可能）

### Bayes Factor（BIC近似）

$$\log BF_{10} \approx -\frac{1}{2} \Delta BIC$$

- BF > 100: 決定的エビデンス（Jeffreys スケール）
- BF = Inf: 独立モデルでは到底説明不可能な強固な交互作用

## 前提条件

- `R` (≥ 4.0) および以下のパッケージが導入済みであること：
  - `dplyr`, `tidyr`, `jsonlite`, `DT`, `rmarkdown`
- 入力データは UTF-8 エンコードの CSV または R 組み込みデータセット名を指定

## 実行手順（2-Pass + ダッシュボード）

### Pass 1: R Engine（統計計算）

```bash
Rscript .agent/skills/vcd-bayesian-evidence-analysis/templates/analysis.R \
  --input your_data.csv \
  --output_dir ./skill_out/vcd_bayesian/ \
  --dataset_name mydata \
  --top_k 10 \
  --threshold_k 1 \
  --large_n_threshold 1000
```

| オプション | 既定値 | 説明 |
| :--- | :--- | :--- |
| `--top_k` | 10 | Top-K 表示件数 |
| `--threshold_k` | 1 | 多段階閾値係数（Score > k × log(N)） |
| `--large_n_threshold` | 1000 | 大規模データモード切替閾値 |
| `--help` | - | CLI ヘルプを表示 |
| `--help_stats` | - | 統計指標ガイドを表示 |

※ `--input` が無い場合は R 組み込みの `HairEyeColor` データセットを使用する。
※ `--vars` で分析対象変数を指定可能（省略時は全変数を使用）。
※ `--freq` で度数列名を指定可能（省略時は `Freq`）。

### Pass 2: AI 考察生成（本スキル）

*※注意: Pass 2を開始する前に、必ずPass 1で `evidence_results.json` が生成されているか確認すること。*

Pass 1 が生成した `evidence_results.json` を読み込み、以下の **日本語エグゼクティブ・サマリー** を `executive_summary.md` として生成する。

**AI プロンプト指示**:

あなたは **計量薬理学・医療統計の専門家** です。`evidence_results.json` を入力として受け取り、以下の4節構成で日本語考察を執筆してください。

#### 節1: 全体的な関連性の評価（ベイズファクター）
- `bf_independence` の値を明示し、Jeffreys スケールで解釈
- BF = Inf → 「独立モデルでは到底説明不可能な極めて強固な交互作用」
- 対象次元数と変数名を明記

#### 節2: エビデンス・スコアによる「真の関連」の抽出
- Evidence Score の定義を数式で示す: $r^2 - k \cdot \log(N)$（JSON の `threshold_k` と `log_n` を明示）
- `threshold`（= $k \cdot \log(N)$）の値と意味を説明
- 正値セル数 / 全セル数を集計して記載
- 大標本でのP値の限界（type I error inflation）に言及

#### 節3: 多次元交互作用の解釈（層別エビデンス）
- `top_k_data` に含まれる **上位セル**（Evidence Score 降順）を具体的数値付きで記述
- Evidence Score **下位3セル**（負の絶対値上位）も `full_data` から参照して記述
- 層別変数がある場合、層ごとのスコア差異を比較・考察

#### 節4: 結論と実務的示唆
- 分析全体の要約（2〜3文）
- 実務・学術的に重要な発見の強調

**禁止事項**:
- 英語での考察出力（数式・変数名を除く）
- Evidence Score 負値セルを「有意な関連あり」と表現すること
- P値を主な根拠として使用すること
- 2次元データとして3次元データを解釈すること

#### 大規模データモード（N > 1,000 の場合）
`large_sample_mode` が `true` の場合、以下を必ず考察に含めること：
- Cramér's V の値と Cohen 基準による評価を冒頭に明示
- Evidence Score が多数のセルで正値になっている場合、「大標本効果による飽和の可能性」に言及
- P値ではなく効果量を主な根拠として使用
- `threshold_k` が 1 より大きい場合、その閾値設定の根拠を記述

### Pass 3: ダッシュボード生成

*※注意: Pass 3を開始する前に、必ずPass 2で `executive_summary.md` がディスク上に保存されているか確認すること。*

```bash
Rscript -e "rmarkdown::render(
  '.agent/skills/vcd-bayesian-evidence-analysis/templates/dashboard.Rmd',
  output_file = 'dashboard.html',
  output_dir = './skill_out/vcd_bayesian/',
  params = list(output_dir = './skill_out/vcd_bayesian/'),
  knit_root_dir = getwd()
)"
```

## 生成されるファイル

| 出力 | 説明 |
| :--- | :--- |
| `evidence_results.json` | BF、Evidence Score、Cramér's V、Top-K、全セルデータ（Pass 1） |
| `dt_table.html` | 列フィルタ付きインタラクティブDTテーブル（+青/−赤色分け）（Pass 1） |
| `executive_summary.md` | AI日本語エグゼクティブサマリー（Pass 2） |
| `dashboard.html` | Top-K＋折りたたみ全テーブル＋用語解説統合HTMLダッシュボード（Pass 3） |

## アンチパターン対策

| # | アンチパターン | 対策 |
|---|-------------|------|
| A | 2次元への固執 | 次元数を `dim(table)` で自動判定、常に Poisson GLM を使用 |
| B | レンダリングパス失敗 | `knit_root_dir = getwd()` を明示してプロジェクトルート基準に統一 |
| C | 英語のみ出力 | すべての出力（ラベル・UI・考察）を日本語にデフォルト設定 |

## 連携スキル

- **前処理**: `vcd-categorical-analysis` （残差分析・モザイクプロット）
- **レポート**: `vcd-categorical-reporting` （AI判断レポート生成）
