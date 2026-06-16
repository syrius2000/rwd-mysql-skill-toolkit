## Why

VCD系およびquestionnaire-batch-analysisは、Rによる統計計算とHTML生成の流れは整理されている一方で、AIレビューの品質、過剰解釈の抑制、設問横断の総括、成果物の読み筋がスキルごとに分散している。
Data Analyticsプラグイン由来のレポート品質・可視化QA・分析検証の考え方を、MCPやウィジェットを導入せずに既存のマルチパス構造へ取り込むことで、従来の使いやすさを維持したまま分析成果物の判断品質を上げる。

## What Changes

- `vcd-pass0-consultation`、`vcd-categorical-analysis`、`vcd-bayesian-evidence-analysis`、`questionnaire-batch-analysis`に共通する分析品質契約を追加する。
- 既存のPass 0 / Pass 1 / Pass 2 / Pass 3の流れを維持しつつ、AIレビューを「結論ファースト」「根拠」「限界」「保留すべき解釈」「次アクション」に整理する。
- 必要に応じてPass 2.5相当のセルフレビューまたは品質確認成果物を導入し、`executive_summary.md`の過剰主張、P値偏重、大標本バイアス、図表と本文の不整合を検出できるようにする。
- `questionnaire-batch-analysis`では、設問別レポートに加えて、複数設問の横断的な総括、優先順位付け、解釈保留事項を扱えるようにする。
- 既存コマンド、既存出力の基本パス、既存R統計エンジンの主要ロジックは維持する。
- MCP、Reactウィジェット、Data Analyticsプラグインのランタイム移植は対象外とする。
- **BREAKING**: なし。既存の実行コマンドと主要成果物は後方互換を維持する。

## Capabilities

### New Capabilities

- `analysis-quality-contract`: VCD系およびquestionnaire系スキルに共通するデータ品質、分析スコープ、可視化QA、レポート検証、成果物確認の契約を定義する。
- `multipass-ai-review`: マルチパス分析におけるAIレビューの構造、必須観点、禁止表現、セルフレビュー、レビュー成果物の保存要件を定義する。
- `questionnaire-cross-question-synthesis`: questionnaire-batch-analysisで複数設問を横断して総括し、重要設問、解釈保留、実務的示唆を整理する要件を定義する。

### Modified Capabilities

- なし。既存のOpenSpec capabilityは未定義のため、本変更では新規capabilityとして契約を追加する。

## Impact

- 影響対象スキル:
  - `.agent/skills/vcd-pass0-consultation/`
  - `.agent/skills/vcd-categorical-analysis/`
  - `.agent/skills/vcd-bayesian-evidence-analysis/`
  - `.agent/skills/questionnaire-batch-analysis/`
- 影響対象になり得る共有資産:
  - `.agent/shared/inspect_data.R`
  - 各スキルの`references/`
  - 各スキルの`templates/`配下のRmdまたはレビュー生成補助
  - 関連テストおよび検証スクリプト
- 依存関係:
  - 新しい外部ランタイム依存は追加しない方針とする。
  - R統計エンジンの主要計算ロジックは原則維持し、必要な変更はレビュー品質・成果物検証・ドキュメント契約に限定する。
- 利用者影響:
  - 既存コマンドの利用者は従来どおり実行できる。
  - 新しいレビュー成果物や品質確認が追加される場合でも、実行手順はマルチパスの自然な延長として案内する。
  - 成果物は日本語で記載し、解釈の根拠と限界を明示する。
