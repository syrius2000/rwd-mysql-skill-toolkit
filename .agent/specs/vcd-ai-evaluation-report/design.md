# Technical Design: vcd-ai-evaluation-report

## 1. アーキテクチャ概要 (Architecture Overview)
従来の RMarkdown / R スクリプトによる**モノリシックなHTML一気通貫フロー**から、**小粒データ出力＋AI解釈パイプライン**へとアーキテクチャをアップデートする。

- **Layer 1: データ前処理＆モデリング (R)**
  -  Rスクリプトは、カテゴリのカウントやクロス表作成、カイ二乗検定、Poisson対数線形モデルなどの計算を担当。
  - 計算後、AIが機械的にパースしやすい `summary.json` と `residuals.csv`、および可視化用の `PNG画像` を `./skill_out/vcd_categorical/` に吐き出す。
- **Layer 2: 分析と解釈 (AI Agent)**
  -  出力されたJSON等の小結果をAIがプロンプトコンテキストとして読み込み、ビジネスインサイトや統計的な妥当性を記述した「評価レポート」を生成する。

## 2. コンポーネント設計 (Component Details)

### 2.1. `templates/analysis.R`
- **JSON出力定義**: `jsonlite` を利用。出力ファイルは `summary_{データ名}.json` とする。（`stats::chisq.test` のように `namespace::function` の記述を徹底する）
- **CSV出力定義**: 残差のリストを `residuals_{データ名}.csv` として保存する。水準数（セルの組み合わせ）が多い場合は、絶対値 `abs_pearson_res >= 1.96` を満たす有意なセルのみに絞り込んだコンパクトなCSVを主要コンテキストとして提供し、全体の生データは別名（`residuals_raw.csv`）で保存する。
- **モデリング方針 (専門性重視の2段階評価への対応)**:
  - 3-way以上の解析において「主効果モデル (`A+B+C`)」と「全2-way交互作用モデル (`(A+B+C)^2`)」の**2つの対数線形 (Poisson) モデルの両方**を適合（fit）させ、それぞれの逸脱度、自由度、最大残差をJSONへ格納する。
  - 残差CSVにも、主効果モデル用と2-wayモデル用の両方を出力し、AIが「一般的な相関」と「特有の交互作用」を区別できるようにする。

### 2.2. スキル定義ドキュメント (`SKILL.md` / `workflow.md`)
- **生成プロンプト指示 (AIの振る舞い)**: AIエージェントに、単なる結果の羅列ではなく「統計の専門家としてのインサイト」を強く求める記述を追加する。
  - **第1段階の解釈**: 主効果モデルの残差から「データの全体的な強い相関構造（当たり前の関係性）」を暴く。
  - **第2段階の解釈**: 2-way交互作用モデルの残差から「相関を加味した上でなお残る、3要因ならではの特異な偏り（Simpsonのパラドックスや潜在的な相互作用）」を鋭く指摘し、「素人を唸らせる」ほどの深いビジネスインサイトを提示する。
- **美しさの追求**: 出力されるArtifactは、Mermaid図やGithub Flavored MarkdownにおけるNote/Warningバッジ（`> [!NOTE]`等）を駆使し、プロフェッショナルで説得力のある美しいデザインとすること。

## 3. データスキーマ (Data Schemas)

### サマリー用JSON (`summary.json`)
```json
{
  "test_used": "stats::anova / stats::chisq.test",
  "models_tested": ["Main Effects (A+B+C)", "All 2-way Interactions ((A+B+C)^2)"],
  "deviance_main": 166.3001,
  "deviance_2way": 0.0,
  "cramers_v_marginal": 0.294,
  "top_residual_main_effects": {"cell": "Blond:Blue:Female", "res": 8.02},
  "top_residual_2way_interactions": {"cell": "None", "res": 0.0}
}
```

### 残差用コンパクトCSV (`residuals_significant.csv`)
| model_type | Var1 | Var2 | Var3   | pearson_res | abs_pearson_res |
|------------|------|------|--------|-------------|-----------------|
| Main       | 1st  | Yes  | Male   | 8.02        | 8.02            |
| Main       | 3rd  | No   | Female | -4.11       | 4.11            |
| 2-Way      | 1st  | Yes  | Female | 2.15        | 2.15            |

## 4. 依存ライブラリと制約 (Dependencies & Restrictions)
- **Rパッケージ**: `datasets`, `vcd`, `gt`, `ggplot2`, および `jsonlite`
- `pacman::p_load` で全パッケージをロードさせる。
- namespace::function のような、名前空間＋シグネチャーの形式で記載する。
- JSONおよびCSVはパース時の負荷軽減のため、行数を妥当な範囲（残差であれば上位20行程度など必要十分なサイズ）に出力側で絞らない。AIコンテキスト長を使いすぎないよう工夫しつつも、構造はシンプルに保つ。

エラーハンドリング: 3-way 以上の解析でデータが極端にスパース（0が多い）な場合、stats::anova 等が不安定になる可能性があるため、実装フェーズ（Tasks）では「フォールバック処理（不適合時の安全なスキップ）」を考慮すること
