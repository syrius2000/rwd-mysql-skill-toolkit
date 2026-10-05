# anomaly-detection Skill 実用化・スリム化計画

created: 2026-10-05 22:38 (JST)
update: 2026-10-06 01:07 (JST)
author: Codex (GPT-6)

## 1. 背景と目的

[anomaly-detection](../../.agents/skills/anomaly-detection/) は、ルール・robust statistics・複数検出器・score fusionを備える一方、Skillの入口、既定CLIのshared参照、説明と実装の整合、運用資産の範囲、ドメイン固定設定に改善余地がある。

本計画は、OpenSpecのspec-driven Changeを作成し、提案・仕様・設計・タスクを揃えた後、承認された範囲をChangeのタスクに沿って実装・検証できる状態にする。目的は、レビュー優先順位付けの価値を保ちながら、Skillとして小さく確実に使える状態に整えることである。

参照: 直前レビュー（会話）、[Archive/14_anomaly_detection_enhancement](../Archive/14_anomaly_detection_enhancement/summary.md)、[docs/Reference/anomaly-detection/](../Reference/anomaly-detection/)

## 2. OpenSpec実施方式

- Change名（案）: `practicalize-anomaly-detection-skill`
- Schema: リポジトリ既定の `spec-driven`（`openspec/config.yaml`）
- 成果物系列: `proposal` → `specs` / `design` → `tasks`
- 実装時は `openspec-apply-change` により、Changeの未完了タスクを順に実施する。
- Changeの各要求・受入条件は、§3の成功基準と§5の作業項目へ追跡可能にする。Changeのタスクには対象ファイル、変更内容、検証方法を記す。
- OpenSpec成果物の厳格検証は計画・仕様の構造確認であり、実装完了や実行時の正しさの証明とは区別する。
- 初回のOpenSpec成果物を作成した後、仕様・設計・タスクをレビューして実装範囲を確定する。ユーザーの明示承認を得るまで、実装タスクへ進まない。
- Phase A+Bを先行実装し、その検証・差分・残課題を確認する。Phase C+Dは後続段階として、A+Bの結果を踏まえた明示承認後に実施する。Phase Eは各段階の検証と最終統合確認を記録する。
- Changeの完了時は、実装・検証結果と未完了項目を照合する。Archive化は実装完了とレビュー後の別判断とし、自動的に実施しない。

## 3. 成功基準と追跡マトリクス

| ID | 成功基準 | OpenSpec仕様（Requirement） | OpenSpecタスク（tasks.md） | 検証証拠 |
|---|---|---|---|---|
| S1 | `--output` 未指定時に `skill_out/anomaly_detection/run_<id>/` へ隔離出力できる | `CLI 既定出力先と Run 分離` | 1.1, 1.2, 1.3 | CLIスモークと生成ファイル確認（`--run-id` 指定時の非破壊確認含む） |
| S2 | `SKILL.md` からエージェントが最小実行と成果物確認まで進める | `Skill 入口とエージェント手順定義` | 2.1 | 用途・非対象・セットアップ・最小実行・成果物解釈のMarkdown差分レビュー |
| S3 | 説明が実装実態と一致する | `ドキュメントと実装の整合・LLM表記適正化` | 2.2 | README / SKILL / skill.yaml / 関連文書の差分確認（任意レビュー指針明記） |
| - | **Phase A+B 停止ゲート（明示承認必須）** | - | **Gate 1 (2.3)** | S1–S3検証証拠・差分報告と明示承認 |
| S4 | Skill実行に不要な運用資産（`deploy/`・FastAPI）が分離されCIが維持される | `クラウド・Web運用資産の退避と分離`, `保護資産の維持` | 3.1, 3.2, 3.3, 3.4 | ツリー確認、参照検索、`ci.yml` 整合確認 |
| S5 | 既定はrules + MADとし、IForest / LOF / MCDは明示指定時に有効となる（PSI/KSはバッチ要約） | `既定検出モードと設定制御` | 4.1, 4.2, 4.3, 4.4 | 設定確認、設定別テスト、単体テスト（Fusionへの影響なし・PSI/KS分離確認） |
| S6 | 既存・追加テストが通る | `テストスイート整合と回帰防止` | 5.1 | `uv run pytest tests/` の全件合格結果 |
| S7 | seed=42の合成データで既知異常行`row-0`〜`row-5`が検出され、期待ラベル範囲・ルール・説明が返る | `合成データによる推論・説明性検証` | 5.2 | `make synth` 後のCLI infer結果を `record_id` で照合し、`label`・`score`・`triggered_rules`・`model_contributions`・`explanation`を確認 |

## 4. 決定済み方針

### 4.1 Skillの位置付け

- 異常の確定や医療判断ではなく、レビュー優先順位付けを行う。
- 実行入口は手順付き `SKILL.md` とCLIを中心にする。
- 本番運用基盤の構築、query自動発行、医療判断の自動化は対象外とする。

### 4.2 既定検出モードと指標の責務分離

| 成分 | 既定 | 方針 |
|---|---|---|
| ルール | ON | 設定可能なデータ品質ルールを行スコア統合に適用 |
| robust MAD | ON | 数値列の汎用的な候補スコアを行スコア統合に適用 |
| IForest / LOF / MCD | OFF | 明示的な設定（`large-scale.yaml`等）で利用可能にする。既定時は重み0 |
| STL | OFF | 適切な時系列列・条件を指定した場合に利用。既定時は重み0 |
| PSI / KS | バッチ要約で利用 | 行単位の融合スコアには一切混ぜず、データセット全体のドリフト監視指標として独立出力 |

`large-scale.yaml` 等に追加検出器を有効化する運用設定を置き、設定名と用途を文書化する。既定モードでも、無効な検出器の重みがFusion結果に影響しないことをテストで確認する。

### 4.3 LLMの表記

- LLM API呼び出しやLLMレビュー機能のコードは追加しない。
- README / SKILL / `skill.yaml` から、LLMレビューが実装機能として組み込まれているような記述を除く。
- `docs/prompts/` はエージェントが任意に参照するレビュー指針として残し、その位置付けを明記する。

### 4.4 設定とドメインルール

- `required_columns`、`value_columns`、ドメインルール対象を設定から指定できるようにする。
- バイタル特化のデモ設定を汎用既定設定から分離する。
- 未知スキーマでは、設定された必須列の欠落警告と利用可能な数値列のMADを基本動作とする。デモ固有の列・閾値を暗黙に要求しない。
- 仕様化の際、現行ルールの挙動・設定形式・欠損時の扱いを確認し、受入条件を決める。根拠のない臨床閾値や新しい臨床ルールは追加しない。

### 4.5 運用資産とCIの位置付け

- `deploy/`（Docker / Kubernetes / Grafana / Prometheus）とFastAPI APIは、再利用できる形で `docs/Archive/` に退避する。Skill実行時の必須資産から外す。
- FastAPIコード・optional `api` extra・運用文書の参照は、退避単位と整合させる。共有依存があれば設計段階で移動範囲を確定する。
- **CIの位置付け**: Skill内 `.github/workflows/ci.yml` は、将来の単独パッケージ化や共通CI設計時の参考となる「保存用テンプレート」として維持する。GitHub Actions の仕様上、リポジトリルート（`.github/workflows/`）に置かれない本ファイルは自動実行されないが、リポジトリ全体へのCI配備・自動実行は今回のスコープ外（非目標）とする。Phase CではSkillのセットアップ・テスト契約（`api` extraに依存しない構成）との構文・整合確認のみを行う。
- `scripts/train.py`、`mlops` / `deep` extras、追跡済み `outputs/anomaly_results.jsonl`、`patches/` は削除候補にしない。参照・利用実態をOpenSpec設計で調べ、Skill必須範囲から外す必要があれば退避方針を明記する。データ成果物の削除や追跡解除は、本計画で明示された承認範囲を超えるため行わない。

## 5. OpenSpec Changeの実装タスク対応

OpenSpec の `tasks.md` は本計画と 1:1 に同期する。

> **作業ディレクトリに関する実行前提**:
> 本タスクにおける `uv run`、`pytest`、`scripts/` コマンドは、すべて `.agents/skills/anomaly-detection/` をカレント作業ディレクトリとして実行する（またはリポジトリルートから `uv run --directory .agents/skills/anomaly-detection ...` を指定して実行する）。

なお、Gate 1 は OpenSpec CLI による機械的な制約機構ではなく、**エージェントがタスク 2.3 完了後に必ず作業を停止してユーザーに報告し、明示承認を得るまで Phase C 以降を実行しないという「運用手順（プロトコル）上の停止制御」** として厳格に運用する。

### Phase 0 — Change仕様の作成・実装前レビュー
1. `openspec new change practicalize-anomaly-detection-skill` でChangeを作成。
2. S1–S7の要求・シナリオ・受入条件・タスク・検証証拠マトリクスを確定。
3. `proposal`、`specs`、`design`、`tasks` を依存順に作成・整合。
4. `openspec validate practicalize-anomaly-detection-skill --strict` で整合性を検証。
5. 実装前にユーザーレビューを実施し、Phase A+B の実装承認を得る。

### Phase A — CLI既定出力の修正（S1）
- [ ] 1.1 `cli.py` のリポジトリルート探索を `.agents` を含む現行構成に対応させ、パス解決テストで検証する
- [ ] 1.2 shared資産参照を `.agents/shared` 正本に合わせ、参照先不在時の明確なエラー通知を実装・検証する
- [ ] 1.3 `--output` 未指定時の出力先を `skill_out/anomaly_detection/run_<id>/` に修正し、CLI スモークテストで run 隔離出力を検証する（`--run-id` 指定時の既存成果物非破壊を含む）

### Phase B — Skill入口とドキュメントの整合（S2, S3）
- [ ] 2.1 `SKILL.md` の手順を用途・非対象・セットアップ（`uv run`）・最小実行・成果物パスと解釈・注意点へ再編し、Markdown 差分で検証する (S2)
- [ ] 2.2 `README.md` および `skill.yaml` から未実装の LLM 連携記述を除去し、`docs/prompts/` の任意レビュー指針としての位置付けを明文化して差分検証する (S3)

### Gate 1 — Phase A+B 完了・停止ゲート（手順上の明示承認必須）
- [ ] 2.3 Phase A+B の検証証拠（S1–S3）、差分、残課題をまとめ、ユーザーに報告して停止する（ユーザーから明示的な Phase C+D 着手承認を得るまで後続タスクは実行不可）

### Phase C — Skill外の運用資産および FastAPI の退避（S4）
- [ ] 3.1 `deploy/`（Dockerfile, k8s, Grafana, Prometheus）および `src/anomaly_detection/api.py` を `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避する (S4)
- [ ] 3.2 `pyproject.toml` の `api` extra を整理し、`docs/operations.md` / `docs/api_reference.md` の FastAPI 記述を退避先へ移動または整理する (S4)
- [ ] 3.3 Skill 内 CI テンプレート（`.github/workflows/ci.yml`）を維持し、退避後の構成との整合・構文を確認する（保存用テンプレートとしての維持、ルート実行は対象外） (S4)
- [ ] 3.4 退避後の Skill ツリー確認および内部コードからの import 参照検索を実行し、壊れた依存がないことを検証する (S4)

### Phase D — 既定検出モードと設定の一般化（S5）
- [ ] 4.1 `default.yaml` でルール検証および robust MAD のみを既定有効（ON）とし、無効検出器（IForest, LOF, MCD, STL）の重みがスコア統合（ScoreFusionEngine）に影響しないことを単体テストで検証する (S5)
- [ ] 4.2 PSI / KS を行スコア統合から除外し、データセット全体のドリフト監視指標（バッチ要約）として独立して計算・出力されることをテストで検証する (S5)
- [ ] 4.3 デモ特化のバイタル列ルール（HR, SBP等）を `configs/demo-vitals.yaml` へ分離し、既定設定を未知スキーマ対応（必須列欠落警告＋数値列MAD）に一般化する (S5)
- [ ] 4.4 `configs/large-scale.yaml` 等に重いモデル（IForest, LOF, MCD, STL）のオプトイン設定をまとめ、設定別テストで検証する (S5)

### Phase E — 段階別統合検証と完了記録（S6, S7）
- [ ] 5.1 `uv run pytest tests/` を実行し、既存および新規テストが全件合格することを検証する (S6)
- [ ] 5.2 作業ディレクトリから `make synth`（n=500, seed=42）を実行し、続けて `uv run python -m anomaly_detection.cli --input data/synthetic_edc.csv` で既定CLI推論を行う。`anomaly_results.jsonl`を`record_id`で照合し、`row-0`はcritical（`negative_age`）、`row-1`はcritical（`implausible_bp`）、`row-2`はwarningまたはcritical（`temporal_inconsistency`）、`row-3`はwarningまたはcritical（`missing_required_value`）、`row-4`と`row-5`はwarningまたはcritical（両方に`duplicate_entity_key`）となり、正常（normal）にならないことを確認する。全対象に`score`、`triggered_rules`、`model_contributions`、決定論的な`explanation`が記録されることを検証する (S7)
- [ ] 5.3 `scripts/check_health.py` の実行および `docs/Reference/anomaly-detection/` のリンク整合を確認し、S1–S7 の達成状況を完了記録としてまとめる

## 6. 主な変更対象

### A+B
- `.agents/skills/anomaly-detection/src/anomaly_detection/cli.py`
- `.agents/skills/anomaly-detection/SKILL.md`
- `.agents/skills/anomaly-detection/README.md`
- `.agents/skills/anomaly-detection/skill.yaml`
- `.agents/skills/anomaly-detection/docs/prompts/*`（位置付け説明）
- 対応するテスト（`tests/test_cli.py` 等）

### C+D（Gate 1 停止ゲートでの再承認後）
- `.agents/skills/anomaly-detection/deploy/**` → `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避
- `.agents/skills/anomaly-detection/src/anomaly_detection/api.py` → `docs/Archive/17_anomaly_detection_deploy_assets/` へ退避
- `.agents/skills/anomaly-detection/pyproject.toml`（`api` extra 整理）
- `.agents/skills/anomaly-detection/configs/*.yaml`（`default.yaml`, `demo-vitals.yaml`, `large-scale.yaml`）
- `.agents/skills/anomaly-detection/src/anomaly_detection/rules.py`
- `.agents/skills/anomaly-detection/src/anomaly_detection/fusion.py`
- `.agents/skills/anomaly-detection/tests/*`
- 関連する運用ドキュメント（FastAPI退避の反映）

### 維持・保護する対象
- Skill内 `.github/workflows/ci.yml`（CIテンプレート維持）
- 検出器コアの数式・融合アルゴリズム（必要なバグ修正を除く）
- 他Skill、`.agents/shared` の契約（参照修正を除く）
- `scripts/train.py`、`mlops` / `deep` extras
- 追跡済みテスト成果物（`outputs/anomaly_results.jsonl`）
- パッチ資産（`patches/`）
- ルート `AGENTS.md`

## 7. リスクと対応

| リスク | 影響 | 対応 |
|---|---|---|
| 既定から追加検出器を外すと検出範囲が変わる | 利用者の期待差 | 明示的な拡張設定（`large-scale.yaml`）を用意し、既定・拡張モードを文書化する |
| 運用資産を退避すると旧手順のリンクが切れる | Archive後に手順を参照できない | 参照検索を行い、保存先と移動対応を記録する |
| ルール一般化で既存のデモ挙動が変わる | テスト・説明の不整合 | デモ設定（`demo-vitals.yaml`）を保持し、設定別テストで確認する |
| OpenSpec成果物が実装内容とずれる | タスク漏れ・過剰実装 | 実装前レビューと Gate 1 停止ゲートで差分・受入条件を確認する |
| strict validationを実装証明と誤認する | 完了状態の誤報 | artifact検証、テスト、CLI実行、レビュー状態を分けて報告する |

## 8. 決定事項

1. `deploy/` と FastAPI 関連資産（`api.py`, `api` extra, 運用文書）は削除せず、`docs/Archive/17_anomaly_detection_deploy_assets/` へ退避する。
2. 既定モードは rules + robust MAD とし、IForest / LOF / MCD / STL は明示的な拡張設定で利用可能にする。無効な検出器の重みは 0 とする。
3. PSI / KS は行スコア統合から除外し、データセット全体のドリフト監視指標（バッチ要約）として維持する。
4. LLM 機能の実装済み表現は除き、`docs/prompts/` はエージェント任意のレビュー指針として残す。
5. Skill 内 CI テンプレート（`.github/workflows/ci.yml`）および `train.py`・extras・`outputs/`・`patches/` は保護対象として維持する。
6. Phase A+B を先行する。Phase C+D は A+B の結果確認と Gate 1 停止ゲートでの明示承認後に着手する。

## 9. 承認・実施境界

- 本計画の作成・更新、読み取り専用調査、OpenSpec成果物のレビューは実装承認前に行える。
- OpenSpec Changeの作成・仕様化は計画承認後に行う。Change作成それ自体はコード実装の承認を意味しない。
- A+Bのコード・テスト・文書変更は、A+Bを対象とする明示承認後に開始する。
- C+Dのコード変更、資産の移動、依存設定の変更は、Gate 1 停止ゲート後に対象範囲を明示した再承認を得てから開始する。
- テストやCLIスモークなど実行フェーズは、該当段階の承認後に実施する。
- commit、OpenSpec archive、remote pushは本計画の承認に含まれない。特にremote pushは別途明示指示があるまで行わない。

## 10. 実施チェックリスト

- [ ] 本計画の方針・A+B範囲の承認（ユーザーの明示承認待ち）
- [x] OpenSpec Change作成とstatus/instructions確認
- [x] proposal、specs、design、tasksを作成
- [x] S1–S7と仕様・タスク・検証証拠の対応をマトリクスとして整合確認
- [x] Phase C/D順序統一、Gate 1停止ゲート、FastAPI退避、PSI/KS分離、CI保護をOpenSpec成果物に反映
- [x] strict validationと実装前レビュー完了（`openspec validate --strict` PASS）
- [ ] Phase A+B を実装・検証し、Gate 1 停止ゲートで報告（**承認待ち**）
- [ ] Phase C+D の対象範囲を確認して再承認
- [ ] Phase C+D を実装・検証
- [ ] Phase E の最終検証と完了記録
- [ ] OpenSpec成果物完了・実装証拠・レビュー状態を区別して報告

---

## 変更履歴

| 日時 (JST) | 内容 |
|---|---|
| 2026-10-05 22:38 | 初版（レビュー指摘を計画化） |
| 2026-10-05 22:43 | OpenSpec実装フロー、決定事項、A+B先行とC+D停止ゲートを反映 |
| 2026-10-05 22:54 | OpenSpec Change作成・全成果物策定 (proposal, specs, design, tasks) および strict validation 完了 |
| 2026-10-05 23:18 | 指摘に基づき S1–S7 追跡マトリクス、Gate 1 停止ゲート、Phase C/D 順序統一、FastAPI 退避、PSI/KS 分離、CI 保護を全成果物に完全同期 |
| 2026-10-06 00:35 | 再レビュー指摘に基づき §5 重複見出し削除、CI テンプレート位置付け（ルート実行非対象）明記、Gate 1 手順上制約明文化、ヘッダー日時整合 |
| 2026-10-06 00:45 | 承認チェック状態を「承認待ち」に見直し、タスク実行作業ディレクトリおよび S7 既知異常行（row-0〜row-4）受入条件を具体化 |
| 2026-10-06 01:07 | S7の対象を生成器が作るrow-0〜row-5へ統一し、期待ラベル範囲・ルールID・成果物フィールドと再現コマンドを明記 |
