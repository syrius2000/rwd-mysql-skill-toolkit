# Proposal

## Why

ローカル Python スキル `anomaly-detection` は、多変量ロバスト統計や分布ドリフト検出などの高度な分析機能を備える一方、以下の課題がある：
1. CLI の既定出力先がリポジトリ共有契約（`.agents/shared`、`skill_out/` 隔離）と乖離している。
2. ドキュメントや設定に未実装の LLM 連携機能が記載され、実態と乖離している。
3. エージェントのローカル実行に不要なクラウド運用資産（Kubernetes, Grafana, Docker）や FastAPI Web API が混入し、Skill の責務が肥大化している。
4. 既定の検出モードで重いモデル（IForest, LOF, MCD, STL）が有効化されており、バイタル特化の前提が暗黙に置かれている。

本変更により、エージェントが迷わず安全に実行できる軽量・自己完結型の分析スキルへと実用化・スリム化を図る。

## What Changes

本変更では、計画書（`docs/Artifacts/implementation_plan_010_1005_2238.md`）の S1–S7 に対応し、以下の改訂を行う：

- **Phase A: CLI既定出力の標準化（S1）**:
  - `--output` 未指定時に、リポジトリ共有契約に基づき `skill_out/anomaly_detection/run_<id>/` 配下へ自動隔離出力するよう修正。
  - `.agents/shared` 正本への参照パス解決およびエラーハンドリングの強化。
- **Phase B: Skill入口とドキュメントの整合（S2, S3）**:
  - `SKILL.md` の手順を用途・非対象・前提・最小実行・成果物解釈の導線へ再編。
  - `README.md`、`skill.yaml` から未実装の LLM レビュー記述を除去し、`docs/prompts/` をエージェント用任意レビュー指針として位置付け。
- **【Gate 1: Phase A+B 停止ゲート（明示承認必須）】**:
  - Phase A+B の検証証拠（S1–S3）を確認し、ユーザー承認を得るまで Phase C+D に進まない。
- **Phase C: 運用資産および Web API の退避・分離（S4）**:
  - Skill 実行に不要な `deploy/`（Dockerfile, k8s, Grafana, Prometheus）、FastAPI コード（`src/anomaly_detection/api.py`）、`pyproject.toml` の `api` extra、FastAPI ドキュメントを `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避。
  - Skill 内 CI テンプレート（`.github/workflows/ci.yml`）の構文・整合を確認・維持（保存用テンプレートとして維持、ルート実行は非目標）。
- **Phase D: 既定検出モードと設定の一般化（S5）**:
  - 既定モード（`default.yaml`）で行スコア統合を Rules + robust MAD の軽量構成とし、重いモデル（IForest, LOF, MCD, STL）は `configs/large-scale.yaml` 等でオプトイン化。
  - PSI / KS は行スコア統合に混入させず、データセット全体のバッチ要約指標として維持。
  - バイタル特化ルールをデモ設定へ分離し、未知スキーマ時の必須列欠落警告と数値列 MAD を基本動作とする。
- **Phase E: 段階別統合検証と完了記録（S6, S7）**:
  - `uv run pytest tests/` による全件合格確認（S6）。
  - `make synth`（seed=42, n=500）後の既定 CLI 実行で、`row-0`〜`row-5`の既知異常、期待ラベル範囲、対応ルールID、決定論的説明文を確認（S7）。

## Capabilities

### New Capabilities
- `anomaly-detection-execution`: EDC/RWD 異常検知スキルにおける CLI 既定実行、成果物隔離、エージェント実行手順、ドキュメント整合、外部依存退避、設定一般化、テスト合格、および説明性検証に関する実行仕様。

### Modified Capabilities
（既存の spec レベルの要件変更はなし）

## Non-Goals & Protected Scope

- **Non-Goals**:
  - 自動的な医療判断やクエリ発行の自動化。
  - 新たな異常検知アルゴリズムの追加。
  - 本番クラウド運用基盤の構築、およびリポジトリルートへの CI 自動実行ワークフロー配備。
- **Protected Scope（変更・削除禁止）**:
  - Skill 内 CI テンプレート（`.github/workflows/ci.yml`）。
  - 検出器コアの計算ロジック（スコア融合アルゴリズム等）。
  - 学習用スクリプト（`scripts/train.py`）。
  - `mlops` / `deep` optional dependencies。
  - 追跡済みテスト成果物（`outputs/anomaly_results.jsonl`）。
  - パッチ資産（`patches/`）。

## Impact

- 対象スキル: `.agents/skills/anomaly-detection/` 配下の CLI、設定ファイル、ドキュメント、テスト
- 退避先: `docs/Archive/17_anomaly_detection_deploy_assets/`
- 外部API / 他スキルへの破壊的変更: なし（`run_scope` 共有契約への適合）
