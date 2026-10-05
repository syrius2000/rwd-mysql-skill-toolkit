# Spec Delta

## Purpose

EDC/RWD 異常検知スキルにおける CLI 既定実行、成果物隔離、検出器モード制御、外部依存分離、テスト合格、および説明性検証に関する実行仕様を定義する。

## ADDED Requirements

### Requirement: CLI 既定出力先と Run 分離（S1）
CLI 実行時に `--output` が指定されない場合、システムはリポジトリ共有契約に基づき `skill_out/anomaly_detection/run_<id>/` 配下に成果物を自動隔離して保存しなければならない（SHALL）。

#### Scenario: output未指定でのCLI実行
- **WHEN** エージェントが `--output` オプションを指定せずに CLI を実行する
- **THEN** システムは決定論的またはタイムスタンプ付きの `run_<id>` ディレクトリを生成し、その配下に `anomaly_results.jsonl` を保存する

#### Scenario: run_id 指定時の出力
- **WHEN** エージェントが明示的に `--run-id` を指定して実行する
- **THEN** システムは指定された run ID のディレクトリ配下に出力し、既存成果物を破壊・上書きしない

#### Scenario: shared 資産参照エラー時の適切な報告
- **WHEN** `.agents/shared` 配下の共有契約・スクリプトが見つからない環境で CLI を実行する
- **THEN** システムは原因となったパスと探索失敗理由を明確に報告して終了する

### Requirement: Skill 入口とエージェント手順定義（S2）
`SKILL.md` は、エージェントが自律的に最小実行と成果物確認を行えるよう、用途・非対象・前提セットアップ・最小実行手順・成果物パスと解釈・注意点を網羅しなければならない（SHALL）。

#### Scenario: SKILL.md からの最小実行導線
- **WHEN** エージェントが `SKILL.md` を読み取って異常検知を実行する
- **THEN** 迷うことなく依存セットアップ、最小 CLI 実行コマンド、および出力成果物の確認・解釈手順を完遂できる

### Requirement: ドキュメントと実装の整合・LLM表記適正化（S3）
本スキルは自動医療判断や LLM API 呼び出しを行わず、ドキュメントおよび設定から未実装の LLM 連携表現を排除し、プロンプトテンプレートを任意レビュー指針として位置付けなければならない（SHALL）。

#### Scenario: 未実装LLM機能の排除
- **WHEN** ユーザーやエージェントが `README.md`、`SKILL.md`、`skill.yaml` を参照する
- **THEN** LLM レビューが自動組み込み機能として記述されておらず、Python コアによる統計・ルール処理であることが明示されている

#### Scenario: 任意レビュー指針としてのプロンプト位置付け
- **WHEN** エージェントが `docs/prompts/` を参照する
- **THEN** それがエージェント自身の推論コンテキストで参照する任意のレビュー指針（ガイド）として説明されている

### Requirement: クラウド・Web運用資産の退避と分離（S4）
Skill 本体はローカル実行に必要な Python コード・テスト・設定のみで構成され、クラウド運用資産（`deploy/`）および FastAPI Web API（`api.py`、`api` extra）を Skill 必須資産から `docs/Archive/` へ退避・分離しなければならない（SHALL）。

#### Scenario: ローカル実行環境での自己完結
- **WHEN** エージェントが Skill 直下で `uv run` を用いて環境構築・推論を実行する
- **THEN** 外部の Docker デーモン、Kubernetes クラスタ、Web サーバーを要求することなく、ローカル Python 環境のみで実行が完結する

#### Scenario: 運用資産および FastAPI の Archive 退避
- **WHEN** 運用資産の退避を実施する
- **THEN** `deploy/`、`src/anomaly_detection/api.py`、`pyproject.toml` の `api` extra、および FastAPI 運用手順が `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避され、Skill 直下の依存から安全に除外される

### Requirement: 既定検出モードと設定制御（S5）
既定のパイプライン実行ではルールベース検証および robust MAD のみを有効とし、高負荷または前提の強い検出器は明示指定時のみ実行しなければならない（SHALL）。行スコア統合とバッチ要約の責務を分離する。

#### Scenario: 既定設定での行スコア統合
- **WHEN** 追加設定なし（既定モード）でパイプラインを実行する
- **THEN** ルールベース判定と robust MAD のみが行スコア統合（ScoreFusionEngine）の対象となり、無効化された検出器（IForest, LOF, MCD, STL）の重みは 0 として扱われる

#### Scenario: PSI / KS のバッチ要約実行
- **WHEN** データセット全体の分布ドリフトを評価する
- **THEN** PSI および KS 検定は行スコア統合には混入せず、データセット単位のバッチ要約指標として独立して計算・出力される

#### Scenario: 汎用設定とバイタル設定の分離
- **WHEN** 未知のスキーマまたは汎用データセットに対して既定設定で実行する
- **THEN** デモ固有のバイタル列（HR, SBP等）を暗黙に要求せず、設定された必須列の欠落警告と利用可能な数値列の MAD スコアリングを基本動作とする。バイタル特化ルールは別設定（`demo-vitals.yaml` 等）に分離される

#### Scenario: 拡張設定でのオプトイン実行
- **WHEN** `large-scale.yaml` などの設定を指定して実行する
- **THEN** 指定された検出器（IForest, LOF, MCD, STL等）が有効化され、統合スコアに寄与する

### Requirement: テストスイート整合と回帰防止（S6）
資産退避や設定変更の後も、既存および新規テストスイートが全件合格し、検出器コアの計算ロジックが正常に維持されなければならない（SHALL）。

#### Scenario: pytest 全件合格
- **WHEN** 開発者またはエージェントが `uv run pytest tests/` を実行する
- **THEN** スコア融合、ルール検証、MCD/STL/PSI 各検出器、および CLI 出力テストがすべて PASS する

### Requirement: 合成データによる推論・説明性検証（S7）
seed=42、n=500の合成データを用いた最小CLI実行において、生成器が挿入する既知異常行`row-0`〜`row-5`が所定の最終ラベルとルールIDで検出され、統計モデル寄与度を含む構造化された決定論的説明文が生成されなければならない（SHALL）。

#### Scenario: 最小 CLI 実行でのラベルと説明生成
- **WHEN** Skillディレクトリで `make synth` を実行し、続けて `uv run python -m anomaly_detection.cli --input data/synthetic_edc.csv` を実行する
- **THEN** JSONL出力を`record_id`で照合し、`row-0`（age=-1）は`critical`かつ`negative_age`、`row-1`（sbp=320）は`critical`かつ`implausible_bp`、`row-2`（recorded_at < visit_date）は`warning`または`critical`かつ`temporal_inconsistency`、`row-3`（site_id欠損）は`warning`または`critical`かつ`missing_required_value`、`row-4`と`row-5`（重複entity key）は両方`warning`または`critical`かつ`duplicate_entity_key`を含み、いずれも`normal`でない。各対象レコードに`record_id`、`label`、`score`、`triggered_rules`、`model_contributions`、および説明文（`explanation`）が記録される

### Requirement: 保護資産の維持（非機能制約）
Skill 内 CI テンプレート、学習用スクリプト、追跡済み成果物、パッチ群は本変更で破壊・削除してはならない（SHALL）。なお、CI テンプレート（`.github/workflows/ci.yml`）は将来の参考保存用として維持し、リポジトリルートへの配置および自動実行はスコープ外（非目標）とする。

#### Scenario: CI テンプレートおよび保護資産の確認
- **WHEN** 本変更の適用前後のツリーおよび CI 設定を比較する
- **THEN** `.github/workflows/ci.yml` が保存用テンプレートとして構文整合を保ったまま維持され、`scripts/train.py`、`mlops`/`deep` extras、`outputs/anomaly_results.jsonl`、`patches/` が保持されている
