# Design

## Context

See proposal.md for motivation.
本スキルは多変量ロバスト統計や分布ドリフト検出などの高度な異常検知機能を持つが、初期スキャフォールド由来の Kubernetes/Grafana 資産および FastAPI Web API の混入、共有契約（`.agents/shared`、`skill_out/` 隔離）とのパス不整合、未実装の LLM 連携記述、既定モードでの重い検出器の過密実行、バイタル特化前提が実用上の課題となっていた。

本設計では、計画書（`docs/Artifacts/implementation_plan_010_1005_2238.md`）の S1–S7 を完全に満たすための具体的アーキテクチャ・設計決定・移行境界を定義する。

## Goals / Non-Goals / Protected Assets

**Goals:**
- CLI 実行時の出力ディレクトリ自動隔離（`skill_out/anomaly_detection/run_<id>/`）をリポジトリ共有契約に基づき標準化する（S1）。
- `SKILL.md` を最小実行と成果物確認導線へ整理し、ドキュメントから未実装 LLM 記述を除去する（S2, S3）。
- Skill 直下からクラウド運用資産（`deploy/`）および FastAPI Web API（`api.py`, `api` extra, 関連文書）を `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避する（S4）。
- 既定の検出器実行を Rules + robust MAD の軽量構成とし、重いモデルは設定ファイルによるオプトイン方式にする。行スコア統合と PSI/KS バッチ要約を明確に分離する（S5）。
- 資産退避・設定変更後も全テストが合格し（S6）、合成データで warning/critical 候補および決定論的説明文が生成されることを確認する（S7）。
- Phase A+B 完了時に強制的な停止ゲート（Gate 1）を設け、ユーザー承認なしに Phase C+D に進まない運用境界を確立する。

**Non-Goals:**
- 自動的な医療判断や SQL クエリ自動発行の機能追加。
- 新たな異常検知アルゴリズムの追加。
- 共通 CI への Skill CI 移管。

**Protected Assets（変更・削除禁止）:**
- Skill 内 CI ワークフロー（`.github/workflows/ci.yml`）。
- 検出器コアの計算ロジック（スコア融合アルゴリズム等）。
- 学習用スクリプト（`scripts/train.py`）。
- `mlops` / `deep` optional dependencies。
- 追跡済みテスト成果物（`outputs/anomaly_results.jsonl`）。
- パッチ資産（`patches/`）。

## Decisions

### 1. CLI 既定出力と共有契約の整合（S1）
- **決定**: `cli.py` におけるリポジトリルート探索および出力先解決を、現行規格 `.agents` および `.agents/shared` に適合させる。`--output` 未指定時は `--output-root`（既定 `./skill_out/anomaly_detection`）配下の `run_<id>/anomaly_results.jsonl` に保存する。明示的に `--run-id` が指定された場合は該当ディレクトリに出力し、既存成果物を破壊・上書きしない。
- **失敗処理**: `.agents/shared` の契約スクリプトが見つからない場合は、探索候補パスと明確なエラーメッセージを出力して速やかに終了する。

### 2. Skill 入口と LLM 表記の適正化（S2, S3）
- **決定**:
  - `SKILL.md`: エージェントが迷わず実行できるよう、①用途、②対象外、③環境セットアップ（`uv run`）、④最小実行手順、⑤成果物パス（`skill_out/...`）と解釈指針、⑥注意点の構成に整理する。
  - `README.md` / `skill.yaml`: 実装されていない「LLM レビュー機能」の記述を削除し、Python コアによるルール＋統計スコア計算であることを明記する。`docs/prompts/` はエージェントが任意に参照する「レビュー観点ガイド」として位置付ける。

### 3. Phase A+B 完了後の停止ゲート（Gate 1）の運用制御
- **決定**: Phase A（CLI 出力）および Phase B（ドキュメント整合）完了後、タスクリスト上で明示的な停止ゲート（Gate 1）を設ける。OpenSpec CLI 自体による機械的検査機構ではなく、エージェントがタスク 2.3 完了後に必ず作業を停止して S1–S3 の検証証拠・差分をユーザーに報告し、Phase C+D への着手承認を明示的に得るまで以降のタスクを実行しない「エージェント運用プロトコル」として厳格に制御する。

### 4. 運用資産および FastAPI の Archive 退避（S4）
- **決定**: Skill 実行に不要な以下の資産を `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避する：
  1. `deploy/`（Dockerfile, k8s/*, grafana/*, prometheus/*）
  2. `src/anomaly_detection/api.py`（FastAPI エンドポイント）
  3. `pyproject.toml` の `[project.optional-dependencies]` 内 `api` extra
  4. `docs/operations.md` および `docs/api_reference.md` のうち FastAPI / デプロイ運用に関する記述
- **CIの位置付け**: Skill 内 `.github/workflows/ci.yml` は、将来の参照用「保存用テンプレート」として維持し、リポジトリルートへの配置および自動実行はスコープ外（非目標）とする。退避に伴うテスト契約の整合（`api` extra を要求しないテスト構成）と構文確認を行う。

### 5. 既定検出モードの軽量化・設定分離・PSI/KS の分離（S5）
- **決定**:
  - `default.yaml` では、ルールベース検証および robust MAD のみを既定有効（ON）とする。
  - Isolation Forest, LOF, MCD, STL は `configs/large-scale.yaml` 等で明示的にオプトイン指定された場合のみ有効とする。無効な検出器の重みは `ScoreFusionEngine` において 0 となり、行スコア統合に一切影響を与えない。
  - **PSI / KS の責務分離**: 行単位の異常スコア融合には混入させず、データセット全体の分布シフト・ドリフト要約指標（バッチ要約）として従来どおり独立して計算・出力可能とする。
  - **設定の一般化**: デモ特化のバイタル列ルール（HR, SBP 等）は `configs/demo-vitals.yaml` へ分離し、既定設定は未知スキーマでも安全に動作する構成（設定された必須列の欠落チェック＋数値列 MAD スコアリング）とする。

### 6. テストスイート検証と合成データ推論（S6, S7）
- **決定**:
  - `tests/` 配下の既存単体テスト（ルール、フュージョン、MCD/STL/PSI等）および新規テスト（CLI出力隔離、設定パース、未知スキーマ）が全件合格することを確認する（S6）。
  - `make synth`（seed=42, n=500）後に既定CLI inferを実行し、`row-0`〜`row-5`を所定ラベル範囲・トリガールールIDで検出し、構造化説明文と統計寄与度を出力することを検証する（S7）。

## S1–S7 追跡マトリクス

| ID | 成功基準 | 対応仕様（Spec Requirement） | 対応タスク（tasks.md） | 主な変更・検証対象 |
| --- | --- | --- | --- | --- |
| S1 | CLI 既定出力先と Run 隔離 | `CLI 既定出力先と Run 分離` | 1.1, 1.2, 1.3 | `cli.py`, CLI スモークテスト, `skill_out/` 確認 |
| S2 | Skill 入口手順と最小実行導線 | `Skill 入口とエージェント手順定義` | 2.1 | `SKILL.md` の構成差分確認 |
| S3 | ドキュメントと実装の整合（LLM表記） | `ドキュメントと実装の整合・LLM表記適正化` | 2.2 | `README.md`, `skill.yaml`, `docs/prompts/` 差分確認 |
| - | **Phase A+B 停止ゲート** | - | **Gate 1 (2.3)** | ユーザーへの S1-S3 証拠報告と明示承認待ち |
| S4 | 運用資産・FastAPI の退避と CI 維持 | `クラウド・Web運用資産の退避と分離`, `保護資産の維持` | 3.1, 3.2, 3.3, 3.4 | `deploy/`, `api.py`, `pyproject.toml`, `.github/workflows/ci.yml` |
| S5 | 既定モード軽量化・PSI/KS分離・設定一般化 | `既定検出モードと設定制御` | 4.1, 4.2, 4.3, 4.4 | `configs/*.yaml`, `rules.py`, `fusion.py`, 単体テスト |
| S6 | 既存・新規テストの全件合格 | `テストスイート整合と回帰防止` | 5.1 | `uv run pytest tests/` |
| S7 | seed=42の合成データでrow-0〜row-5を既知ラベル範囲・ルールで検出 | `合成データによる推論・説明性検証` | 5.2 | `make synth`と既定CLI infer、record_id別のlabel・triggered_rules・model_contributions・explanation |

## Risks / Trade-offs

- **[Risk: 既定モード変更による多変量異常の見落とし]** → ドキュメントおよび `SKILL.md` に「多変量相関や時系列の精査が必要な場合は `configs/large-scale.yaml` を指定すること」を明記する。
- **[Risk: 運用資産退避に伴うテストやインポートの破損]** → `api.py` 退避後、`tests/` 内に `api.py` への暗黙の import がないか確認し、pytest を実行して破損がないことを担保する。
- **[Risk: PSI / KS の行スコア統合混入]** → 単体テストで行スコア統合（fusion）の出力要素を検証し、PSI/KS が混入していないこと、バッチ要約として独立出力されていることを担保する。
