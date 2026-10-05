# Tasks

> **作業ディレクトリに関する実行前提**:
> 本タスクにおける `uv run`、`pytest`、`scripts/` コマンドは、すべて `.agents/skills/anomaly-detection/` をカレント作業ディレクトリとして実行する（またはリポジトリルートから `uv run --directory .agents/skills/anomaly-detection ...` を指定して実行する）。

## 1. Phase A: CLI 既定出力の修正 (S1)

- [ ] 1.1 `cli.py` のリポジトリルート探索を `.agents` を含む現行構成に対応させ、パス解決テストで検証する
- [ ] 1.2 shared資産参照を `.agents/shared` 正本に合わせ、参照先不在時の明確なエラー通知を実装・検証する
- [ ] 1.3 `--output` 未指定時の出力先を `skill_out/anomaly_detection/run_<id>/` に修正し、CLI スモークテストで run 隔離出力を検証する（`--run-id` 指定時の既存成果物非破壊を含む）

## 2. Phase B: Skill 入口とドキュメントの整合 (S2, S3)

- [ ] 2.1 `SKILL.md` の手順を用途・非対象・セットアップ（`uv run`）・最小実行・成果物パスと解釈・注意点へ再編し、Markdown 差分で検証する (S2)
- [ ] 2.2 `README.md` および `skill.yaml` から未実装の LLM 連携記述を除去し、`docs/prompts/` の任意レビュー指針としての位置付けを明文化して差分検証する (S3)

## Gate 1: Phase A+B 完了・停止ゲート（手順上の明示承認必須）

- [ ] 2.3 Phase A+B の検証証拠（S1–S3）、差分、残課題をまとめ、ユーザーに報告して停止する（エージェント運用プロトコルとして、ユーザーから明示的な Phase C+D 着手承認を得るまで後続タスクは実行不可）

## 3. Phase C: Skill外の運用資産および FastAPI の退避 (S4)

- [ ] 3.1 `deploy/`（Dockerfile, k8s, Grafana, Prometheus）および `src/anomaly_detection/api.py` を `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避する (S4)
- [ ] 3.2 `pyproject.toml` の `api` extra を整理し、`docs/operations.md` / `docs/api_reference.md` の FastAPI 記述を退避先へ移動または整理する (S4)
- [ ] 3.3 Skill 内 CI テンプレート（`.github/workflows/ci.yml`）を維持し、退避後の構成との整合・構文を確認する（保存用テンプレートとしての維持、ルート実行は対象外） (S4)
- [ ] 3.4 退避後の Skill ツリー確認および内部コードからの import 参照検索を実行し、壊れた依存がないことを検証する (S4)

## 4. Phase D: 既定検出モードと設定の一般化 (S5)

- [ ] 4.1 `default.yaml` でルール検証および robust MAD のみを既定有効（ON）とし、無効検出器（IForest, LOF, MCD, STL）の重みがスコア統合（ScoreFusionEngine）に影響しないことを単体テストで検証する (S5)
- [ ] 4.2 PSI / KS を行スコア統合から除外し、データセット全体のドリフト監視指標（バッチ要約）として独立して計算・出力されることをテストで検証する (S5)
- [ ] 4.3 デモ特化のバイタル列ルール（HR, SBP等）を `configs/demo-vitals.yaml` へ分離し、既定設定を未知スキーマ対応（必須列欠落警告＋数値列MAD）に一般化する (S5)
- [ ] 4.4 `configs/large-scale.yaml` 等に重いモデル（IForest, LOF, MCD, STL）のオプトイン設定をまとめ、設定別テストで検証する (S5)

## 5. Phase E: 段階別統合検証と完了記録 (S6, S7)

- [ ] 5.1 `uv run pytest tests/`（作業ディレクトリ: `.agents/skills/anomaly-detection/`）を実行し、既存および新規テストが全件合格することを検証する (S6)
- [ ] 5.2 `make synth`（seed=42, n=500）後に `uv run python -m anomaly_detection.cli --input data/synthetic_edc.csv` を実行する。出力を`record_id`で照合し、`row-0`（age=-1）は`critical`かつ`negative_age`、`row-1`（sbp=320）は`critical`かつ`implausible_bp`、`row-2`（recorded_at < visit_date）は`warning`または`critical`かつ`temporal_inconsistency`、`row-3`（site_id欠損）は`warning`または`critical`かつ`missing_required_value`、`row-4`と`row-5`（重複entity key）は両方`warning`または`critical`かつ`duplicate_entity_key`を含み、いずれも`normal`でないことを検証する。各対象レコードに`score`、`model_contributions`、決定論的な`explanation`が存在し、既定出力先の`anomaly_results.jsonl`に保存されることを確認する (S7)
- [ ] 5.3 `scripts/check_health.py` の実行および `docs/Reference/anomaly-detection/` のリンク整合を確認し、S1–S7 の達成状況を完了記録としてまとめる
