## Context

本変更は、`.agent/skills`配下の分析系スキルに対して、既存のR統計計算パイプラインを壊さずにAIレビューと成果物品質を底上げするための設計である。対象は主に`vcd-pass0-consultation`、`vcd-categorical-analysis`、`vcd-bayesian-evidence-analysis`、`questionnaire-batch-analysis`である。

現状のVCD系スキルは、Pass 0による検分、Rによる統計計算、`executive_summary.md`、HTMLダッシュボード生成というマルチパスの骨格を持っている。`questionnaire-batch-analysis`も、設問設定CSVに基づく一括実行、`summary.csv`、設問別`report.html`の生成を持っている。一方で、AIレビューの構成、過剰解釈チェック、図表と本文の整合、複数設問の横断総括はスキルごとに分散している。

Data Analyticsプラグイン由来の考え方は、MCPやウィジェットのランタイムではなく、以下の設計原則として取り込む。

- 先に分析問いと読み手に必要な結論を定義する。
- 主要な主張には根拠、限界、解釈保留、次アクションを添える。
- 図表は装飾ではなく、特定の主張を支える証拠として扱う。
- 成果物は生成しただけで完了とせず、実際に読める状態かを確認する。

## Goals / Non-Goals

**Goals:**

- 既存のマルチパス構造を維持したまま、AIレビューの品質を標準化する。
- VCD系とquestionnaire系に共通する分析品質契約を導入し、データ品質、分析スコープ、可視化QA、成果物確認の観点を共有する。
- `executive_summary.md`を、結論ファースト、根拠、限界、保留すべき解釈、次アクションを含む成果物へ改善する。
- 必要に応じてPass 2.5相当のレビュー品質確認を導入し、過剰主張、P値偏重、大標本効果の見落とし、本文と図表の不整合を検出する。
- `questionnaire-batch-analysis`に、複数設問を横断して重要設問、解釈保留、実務的示唆を整理する総括機能を追加できる設計にする。
- 既存コマンド、主要出力パス、R統計エンジンの主要計算ロジックは後方互換を維持する。

**Non-Goals:**

- MCP artifact、Reactウィジェット、Data Analyticsプラグインのランタイムを移植しない。
- R統計モデルの主要ロジックを全面的に置き換えない。
- 既存の`summary.csv`、`executive_summary.md`、`dashboard.html`、設問別`report.html`を削除または必須パス変更しない。
- 実行時に外部ネットワークや新しい外部サービスへ依存しない。
- すべての分析を自動で最終判断まで行うのではなく、解釈保留や追加確認が必要な場合は明示する。

## Decisions

### 1. 共通品質契約を参照文書として導入する

`analysis-quality-contract`は、各スキルの`SKILL.md`へ大きな重複文を埋め込むのではなく、共通参照として定義する。候補パスは`.agent/skills/<skill>/references/`配下への個別配置、または`.agent/shared/`配下の共有文書である。

推奨は、実装フェーズで影響範囲を確認したうえで、まず各対象スキルから参照できる共通文書を1つ作り、各`SKILL.md`には「いつ読むか」「どの成果物で満たすか」だけを書く方式である。

代替案として、各スキルに完全な品質チェックリストを直接書く方法がある。これは読みやすいが、VCD系とquestionnaire系で内容がずれやすく、将来の保守負荷が高い。

### 2. AIレビューはPass 2を厚くし、Pass 2.5は軽量な品質確認として扱う

AIレビュー改善の中心はPass 2である。Pass 2は、統計結果JSONや`summary.csv`を読み、結論ファーストの`executive_summary.md`または総括Markdownを生成する。

Pass 2.5は新しい重い実行フェーズではなく、生成済みAIレビューを検査する軽量ゲートとして設計する。成果物候補は`quality_check.md`または`review_notes.md`であり、以下を確認する。

- P値だけで結論していないか。
- 効果量、残差、Evidence Score、サンプルサイズを区別して説明しているか。
- 大標本効果、スパースセル、過剰水準、欠損、集約による情報損失を必要に応じて明示しているか。
- 図表や表が本文の主張を支えているか。
- 解釈保留、追加確認、実務的次アクションが必要な場合に隠していないか。

代替案として、Pass 3後にHTMLだけをレビューする方法がある。これは完成物の見た目確認には有効だが、AIレビュー本文の過剰主張を早く止めにくい。

### 3. 既存コマンド互換を最優先する

本変更では、既存ユーザーが従来のコマンドをそのまま使えることを優先する。新しい品質レビュー成果物は、既存出力に追加する形を基本とする。

VCD系では`executive_summary.md`を維持し、必要に応じて`quality_check.md`や`review_notes.md`を同じrun出力ディレクトリに追加する。`vcd-bayesian-evidence-analysis`の`run_<prefix>/`構造や`vcd-categorical-analysis`の`runs/<id>/`構造は、可能な限り維持する。

`questionnaire-batch-analysis`では、設問別`report.html`と`summary.csv`を維持し、横断総括は`cross_question_summary.md`などの追加成果物として扱う。

### 4. Data Analytics由来の要素は「品質原則」として取り込む

取り込む対象は、レポートの読み筋、根拠と限界の配置、図表QA、成果物確認である。取り込まない対象は、MCP app、ウィジェット、React、接続済みデータソース探索、セマンティックレイヤー管理である。

この境界により、既存のR中心・ローカルファイル中心のスキル体系を保ちながら、読者にとって判断可能な成果物へ改善できる。

### 5. questionnaire横断総括は設問別処理の上位成果物にする

`questionnaire-batch-analysis`は、設問別レポートを生成するだけでなく、`summary.csv`と各設問の主要結果をもとに横断総括を生成できるようにする。

横断総括では、以下を優先する。

- 強い関連や実務上重要な偏りがある設問。
- 統計的には目立つが効果量やセル数の面で保留すべき設問。
- Likert、nominal 2-way、nominal 3-wayで解釈方法が異なる点。
- 次に深掘りすべき設問、または集約・再分類が必要な設問。

これは設問別レポートの代替ではなく、分析者が全体像を把握するための上位索引として扱う。

## Risks / Trade-offs

- [Risk] AIレビューのチェック項目を増やしすぎると、従来より使いにくくなる。 → Mitigation: 既存コマンドは維持し、追加成果物は簡潔な定型構成にする。
- [Risk] 共通品質契約が抽象的すぎると、各スキルで実行時に使われない。 → Mitigation: 各スキルのPassごとに、どの成果物で契約を満たすかを明記する。
- [Risk] Pass 2.5が重い別フェーズになると、マルチパスが複雑化する。 → Mitigation: Pass 2.5は軽量なレビューゲートまたは任意成果物として扱い、R再計算を要求しない。
- [Risk] Data Analyticsプラグイン由来の表現をそのまま移すと、このリポジトリのRWD/VCD文脈に合わない。 → Mitigation: MCPやビジネスKPI文脈は移植せず、統計分析成果物に合う品質原則だけを抽出する。
- [Risk] questionnaire横断総括が、設問別の前提差を無視したランキングになる。 → Mitigation: 設問タイプ、効果量、セル数、エラー状態、解釈保留を同時に扱い、単純なP値順位を禁止する。
- [Risk] 出力ファイルが増えて利用者が迷う。 → Mitigation: `SKILL.md`と完了報告で、主要成果物、補助成果物、確認用成果物を明確に分ける。

## Migration Plan

1. OpenSpec specsで、`analysis-quality-contract`、`multipass-ai-review`、`questionnaire-cross-question-synthesis`の要件を定義する。
2. 共通品質契約の参照文書を追加し、対象スキルから参照する。
3. VCD系のPass 2指示を更新し、`executive_summary.md`の必須構成と禁止表現を強化する。
4. 必要に応じて、`quality_check.md`または`review_notes.md`の生成手順を追加する。
5. questionnaire横断総括の入力、出力、解釈ルールを定義し、設問別成果物を壊さずに追加する。
6. 既存検証スクリプトとテストを更新し、主要成果物の存在、後方互換、レビュー品質契約を確認する。

ロールバックは、追加した参照文書と`SKILL.md`の新規指示、追加成果物生成部分を戻すことで行う。既存R統計計算ロジックを大きく変更しないため、ロールバック範囲は限定される想定である。

## Open Questions

- 共通品質契約の正本を`.agent/shared/`に置くか、各スキルの`references/`に置くか。
- Pass 2.5の成果物名を`quality_check.md`、`review_notes.md`、またはスキル別名称にするか。
- questionnaire横断総括の出力名を`cross_question_summary.md`に固定するか、既存のrun識別子に合わせて変えるか。
- AIレビュー品質確認を必須にする範囲を、VCD系全体にするか、大標本・多設問などリスクの高いケースに限定するか。
