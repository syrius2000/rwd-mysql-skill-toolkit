# AI 考察文ワークフロー

このリファレンスは、R による統計処理とダッシュボード生成の間に、エージェントが日本語の考察文を作成するための判断順序を示す。現行フローでは **`executive_summary.md`** を考察文の入力として扱い、`dashboard.Rmd` がそれを読み込む。

## 前提

- リポジトリに **API キーを埋め込まない**。
- R/Python から外部 LLM API を呼ぶ **バッチ処理は行わない**。
- 考察文は **エージェント（このチャットの AI）**が、生成済みの統計結果と図表を読んで作る。
- P 値だけで結論を作らず、残差、効果量、層別差、分析設定を合わせて判断する。

## 手順

1. **Step 1: R 2パスで統計処理を完了する**
   `analysis.R --profile` で `data_profile.json` を確認し、過大セル数や過剰水準への対応を `render_config.json` に反映する。その後 `analysis.R --render` を実行し、`summary_*.json`、`categorical_results.json`、残差 CSV、図表、ダッシュボード用素材が生成されたことを確認する。

2. **Step 2: AI が `executive_summary.md` を作成する**
   `summary_*.json`、`categorical_results.json`、残差 CSV、プロット、`render_config.json`、生成済みダッシュボード素材を読み、`skill_out/vcd_categorical/` または `--run-id` 配下に `executive_summary.md` を保存する。チャット本文だけで代替しない。

3. **Step 3: `dashboard.Rmd` をレンダリングする**
   `templates/dashboard.Rmd` は出力先の `executive_summary.md` を読み込み、統計結果と考察文を統合する。レンダリング後、HTML 内に考察文が反映されていることを確認する。

## 考察文の判断順序

1. **全体関連**
   Cramér's V と Cohen 基準で関連の強さを述べる。統計的有意性があっても効果量が小さい場合は、実務上の意味を控えめに扱う。

2. **残差の方向**
   `abs_pearson_res` が大きいセルを優先し、「期待より多い」「期待より少ない」を明確に分ける。セル数が多い場合は上位2〜3個に絞り、網羅的な列挙にしない。

3. **層別差とモデル設定**
   3-way や層別変数がある場合、周辺集計だけで断定しない。`render_config.json` で水準集約や除外を行った場合は、解釈の前提として短く明記する。

4. **過剰主張の抑制**
   観察データから因果を断定しない。残差は「偏りの候補」であり、業務判断にはデータ収集条件、サンプルサイズ、未観測交絡、カテゴリ定義の確認が必要であることを必要に応じて添える。

## `executive_summary.md` の推奨構成

- **結論**: 主要な関連と実務的示唆を1〜2段落で述べる。
- **偏りのあるセル**: 期待より多い/少ないセルを残差の方向つきで説明する。
- **効果量**: Cramér's V と small/medium/large 等のラベルを併記する。
- **層別・注意点**: 層別差、集約設定、過剰主張を避けるための留意点を書く。

## エージェントへの依頼例

「`summary_*.json`、`categorical_results.json`、残差 CSV、図表、`render_config.json` を読んで、`executive_summary.md` を日本語で作成して。Cramér's V、残差の上位セル、層別差、集約設定の影響を順に扱い、因果や実務影響を過剰主張しない表現にしてください。」
