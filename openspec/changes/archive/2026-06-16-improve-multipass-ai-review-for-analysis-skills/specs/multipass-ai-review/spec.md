## ADDED Requirements

### Requirement: AIレビューの標準構成
マルチパス分析のAIレビュー成果物は、結論ファースト、根拠、限界、解釈保留、次アクションを含む標準構成をMUST満たさなければならない。

#### Scenario: executive_summaryが標準構成を満たす
- **WHEN** `vcd-categorical-analysis`または`vcd-bayesian-evidence-analysis`が`executive_summary.md`を生成する
- **THEN** 成果物は主要結論、統計的根拠、実務的意味、解釈上の限界、必要な次アクションを日本語で含む

#### Scenario: レビューがチャットだけで終わらない
- **WHEN** AIレビューが必要な分析スキルを実行する
- **THEN** エージェントは長文チャットのみで代替せず、指定されたrun出力ディレクトリにレビュー成果物を保存する

### Requirement: 統計指標の読み分け
AIレビューは、P値、効果量、残差、Evidence Score、Bayes Factor、サンプルサイズの役割をMUST区別し、単一指標だけで過剰な結論を出してはならない。

#### Scenario: 大標本分析をレビューする
- **WHEN** 大標本または`large_sample_mode`相当の分析結果をレビューする
- **THEN** AIレビューはP値偏重を避け、効果量、Evidence Score、Bayes Factor、セル数またはサンプルサイズに基づく解釈を示す

#### Scenario: Evidence Scoreが負のセルを扱う
- **WHEN** `evidence_results.json`または同等の結果にEvidence Score負値セルが含まれる
- **THEN** AIレビューは負値セルを「有意な関連あり」と表現せず、独立モデルで説明しうる範囲または解釈保留として扱う

#### Scenario: 残差方向を説明する
- **WHEN** 残差または偏りの方向を本文で説明する
- **THEN** AIレビューは観測度数が期待度数より多い方向か少ない方向かを区別し、実務的示唆と過剰解釈の境界を示す

### Requirement: Pass 2.5品質確認
対象分析スキルは、Pass 2で生成したAIレビューに対して、Pass 2.5相当の軽量な品質確認をMUST実施できなければならない。

#### Scenario: 品質確認成果物を生成する
- **WHEN** AIレビュー成果物が生成された後に品質確認を行う
- **THEN** エージェントは`quality_check.md`、`review_notes.md`、またはスキルで定義された同等の成果物に、確認結果と保留事項を保存できる

#### Scenario: 過剰主張を検出する
- **WHEN** AIレビューがP値だけで結論する、因果を断定する、サンプルサイズやセル数の限界を無視する、または図表と矛盾する
- **THEN** 品質確認は該当箇所を指摘し、修正または保留事項として扱う

### Requirement: 既存マルチパス互換
AIレビュー改善は既存のPass順序、主要コマンド、主要成果物を壊さず、追加成果物としてMUST導入されなければならない。

#### Scenario: VCD系の既存成果物を維持する
- **WHEN** VCD系スキルの実行手順を確認する
- **THEN** 既存のR統計計算、`executive_summary.md`、`dashboard.html`または既存HTML成果物は維持され、新しい品質確認は追加成果物として扱われる

#### Scenario: MCPランタイムを要求しない
- **WHEN** AIレビュー改善後のスキルを実行する
- **THEN** 実行はMCP artifact、Reactウィジェット、外部Data Analyticsランタイムを要求しない
