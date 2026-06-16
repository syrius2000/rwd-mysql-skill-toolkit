## 1. 共通品質契約の整備

- [x] 1.1 共通分析品質契約の配置先を決定し、対象スキルから参照しやすいMarkdown文書を追加する
- [x] 1.2 共通分析品質契約に、データ品質、分析スコープ、可視化QA、成果物確認、解釈保留の判断基準を記載する
- [x] 1.3 `vcd-pass0-consultation`、`vcd-categorical-analysis`、`vcd-bayesian-evidence-analysis`、`questionnaire-batch-analysis`の`SKILL.md`から共通分析品質契約を参照する
- [x] 1.4 各対象スキルのPassまたは実行チェックリストに、どの成果物または確認手順が品質契約を満たすかを追記する

## 2. VCD系AIレビューの強化

- [x] 2.1 `vcd-categorical-analysis`のAI考察手順を、結論ファースト、根拠、限界、解釈保留、次アクションを含む構成へ更新する
- [x] 2.2 `vcd-bayesian-evidence-analysis`のPass 2指示を、P値偏重回避、効果量、Evidence Score、Bayes Factor、大標本効果の読み分けが明確になるよう更新する
- [x] 2.3 Evidence Score負値セル、残差方向、スパースセル、過剰水準、集約による情報損失の禁止表現または保留表現を参照文書に追加する
- [x] 2.4 Pass 2.5相当の軽量品質確認手順を定義し、`quality_check.md`、`review_notes.md`、または採用する成果物名を確定する
- [x] 2.5 VCD系の完了条件に、AIレビュー成果物と品質確認成果物の存在確認および重大未解決事項の確認を追加する

## 3. questionnaire横断総括の追加

- [x] 3.1 `questionnaire-batch-analysis`の横断総括成果物名、保存先、入力ファイルを決定する
- [x] 3.2 `summary.csv`と設問別成果物から、重要設問、解釈保留、実務的示唆、次アクションを抽出する総括手順を定義する
- [x] 3.3 P値のみのランキングを禁止し、効果量、残差方向、セル数、設問タイプ、エラー状態を合わせて扱うルールを追加する
- [x] 3.4 `nominal_2way`、`likert_2way`、`nominal_3way`の設問タイプ別解釈ルールを参照文書または`SKILL.md`に追加する
- [x] 3.5 完了報告に、`summary.csv`、設問別`report.html`、横断総括Markdown、主要保留事項を含める手順を追加する

## 4. 後方互換と成果物確認

- [x] 4.1 既存コマンド、主要出力パス、既存成果物名が維持されていることを確認する
- [x] 4.2 MCP artifact、Reactウィジェット、外部Data Analyticsランタイムへの依存が追加されていないことを確認する
- [x] 4.3 生成HTML、Markdownレビュー、横断総括の読み取り確認手順を完了ゲートに反映する
- [x] 4.4 出力ファイルが増えた場合でも、主要成果物、補助成果物、確認用成果物の区別が利用者に分かるように案内を整理する

## 5. 検証

- [x] 5.1 OpenSpecのchange状態を確認し、proposal、design、specs、tasksがすべて完了していることを確認する
- [x] 5.2 既存の対象スキル検証スクリプトまたはテストを確認し、必要に応じてレビュー品質契約に対応する検証を追加する
- [x] 5.3 `questionnaire-batch-analysis`の既存出力互換と横断総括追加を検証する
- [x] 5.4 VCD系の既存マルチパス実行手順と追加レビュー成果物の整合を検証する
- [x] 5.5 最終的にOpenSpec仕様、実装差分、検証結果を照合し、未解決の設計判断を報告する
