# Skill 出力の上書きリスク: 残タスク改定計画

created: 2026-07-03 13:15 (JST)
author: AI Agent (Claude)
status: draft

> 実行条件: 自宅の Python / MySQL 起動環境で作業する前提。DB 接続・SQL 実行・commit / push は、着手時に本メモの手順で進める。テスト済み仕様と SKILL.md の文書化済みファイル名契約は変更しない。

## 背景

`code-reviewer` によるレビューで、各 Skill の実行スクリプトに「出力ディレクトリの一意化不足・既存成果物の上書き」リスクが複数見つかった。
このうち、下流契約（`SKILL.md` の固定ファイル名）やテスト済み仕様を壊さずに安全に直せる2件は PR #6 で対応済み。

### PR #6 で対応済み（`cursor/fix-run-output-overwrite-2961`）
- `.agent/shared/inspect_data.R`: `--out-dir`（または第2位置引数）で出力先を指定可能に。ファイル名 `inspection_results.json` は維持、未指定時は CWD（後方互換）。
- `.agent/skills/questionnaire-batch-analysis/templates/batch_runner.R`: 同一 config 内の重複 `output_slug` を実行前に検出し即停止（exit 1、成果物書き込み前）。

## 変更しない（根拠つき・触らない）

| 対象 | 根拠 |
|---|---|
| `run_scope.R` の `run_id_short16`（16文字切り詰め） | `tests/test_vcd_bayesian_run_id.R:26` のテスト済み仕様 |
| `step1_report.json` / `step3_report.json` / `<db>_<table>_report.json` の固定ファイル名 | 各 `SKILL.md` に出力ファイル名が契約として明記。ファイル名変更は下流契約に影響 |
| `inspection_results.json` のファイル名 | `vcd-pass0-consultation/SKILL.md` が名前で参照 |

## 残タスク（自宅の Python + MySQL 環境で実施）

各項目は「ファイル名契約は維持」を原則とし、`--out-dir` / `--report-dir` / `--run-id` 等で **ディレクトリ単位に隔離できる設計** へ寄せる方針。ファイル名の一意化は SKILL.md の契約更新とセットでのみ行う。

### 残タスク一覧（チェックリスト）

| ID | 対象ファイル | 優先度 | MySQL要否 | 一言でいう修正 | 完了(受け入れ)基準 |
|---|---|---|---|---|---|
| [ ] T1 | `flat-file-mysql-load-validation/scripts/step3_cli.py` | 高 | 要（成功パス）／エラーパスは不要 | `--report-dir` を run 単位に隔離（ファイル名据え置き） | 異なる DB/SQL で2回実行し両レポートが残る |
| [ ] T2 | `mysql-table-cardinality/scripts/get_cardinality_cli.py` | 中 | 要 | `--out-dir` の run 隔離オプション追加 | 同一 db.table を2回実行し両方残る |
| [ ] T3 | `mysql-er-diagram/scripts/generate_er.py` | 中 | 不要（`--sqlite` で検証可） | 辞書CSVの docstring/実装乖離を解消＋timestampに年・秒 | 同一分内2回実行で衝突しない／docstring と実装が一致 |
| [ ] T4 | `mysql-entity-matrix/scripts/generate_matrix_sql.py` | 中 | 要 | timestampに年・秒付与 or `--run-id` 受理 | 同一分・同一DBの連続実行で衝突しない |
| [ ] T5 | `flat-file-mysql-ddl-generation/scripts/step1_cli.py` | 低 | 不要 | レポートのみ `--out-dir` run 隔離（SQL名は据え置き） | `test_step1_e2e.py` が緑のまま／再実行でレポート衝突しない |
| [ ] T6 | `anomaly-detection`（`io.py` 他） | 低 | 不要 | 運用ガイド追記 or `--run-id` オプション検討 | 方針決定（当面は運用ガイドで可） |
| [ ] T7 | `vcd-categorical-analysis/templates/analysis.R` | 低 | 不要 | run-id 未指定時も入力ハッシュで自動隔離を検討 | 挙動変更がテストに影響しないことを確認 |

> 共通の完了基準: 修正後も回帰テストが baseline と同数（`pytest` 14 passed / 5 failed、R 5 passed / 8 failed）から悪化しないこと。ファイル名契約を変える場合は該当 `SKILL.md` を同一コミットで更新すること。

### T1. `flat-file-mysql-load-validation/scripts/step3_cli.py`（優先度: 高）
- 現状: DB / SQL が違っても常に同一 `step3_report.json` に上書き（`step3_cli.py:148,178`）。
- 案A（契約維持・推奨）: `--report-dir` の既定を run 単位（例: `--run-id` かタイムスタンプ由来のサブディレクトリ）に分離。ファイル名は据え置き。
- 案B（契約更新が必要）: ファイル名に `db` / `sql stem` / timestamp を付与。→ `SKILL.md:47` の記述も更新。
- 検証: MySQL 起動後、異なる DB/SQL で2回実行し、両レポートが残ることを確認。mysql 不在時のエラーパスは本環境でも検証可能。

### T2. `mysql-table-cardinality/scripts/get_cardinality_cli.py`（優先度: 中）
- 現状: `<db>_<table>_report.json` / `..._columns_cardinality.csv` を再実行で上書き（`:257,275`）。db.table 名は含むが履歴は残らない。
- 案: `--out-dir` を run 単位に隔離できるオプションを追加（ファイル名据え置き）。
- 検証: 同一 db.table を2回実行し、隔離時に両方残ることを確認（要 MySQL）。

### T3. `mysql-er-diagram/scripts/generate_er.py`（優先度: 中）
- 現状: 辞書 CSV `<db>_dictionary.csv` は固定名で truncate 上書き（`:423-426`、docstring は「マージ」と乖離）。md/xml は `%m%d_%H%M`（年欠落・分粒度）で同一分の再実行が衝突（`:428`）。
- 案: (a) docstring と実装の乖離を解消（実態に合わせるか、追記マージにする）。(b) タイムスタンプに年と秒を含める、または `--run-id` を受ける。
- 検証: `--sqlite` サポートがあるため、SQLite で MySQL なしでも一部検証可能。同一分内2回実行で衝突しないことを確認。

### T4. `mysql-entity-matrix/scripts/generate_matrix_sql.py`（優先度: 中）
- 現状: `matrix_query_<db>_%m%d_%H%M.sql` / `matrix_result_<db>_%m%d_%H%M.csv`（年欠落・分粒度、`:227-236`）。
- 案: タイムスタンプに年・秒を含める、または `--run-id` を受ける。
- 検証: 同一分・同一 DB の連続実行で衝突しないことを確認。

### T5. `flat-file-mysql-ddl-generation/scripts/step1_cli.py`（優先度: 低）
- 現状: `step1_report.json` 固定名（`:214`）、`<stem>Import.sql` は入力 stem 由来（`:173`）。
- 制約: `tests/test_step1_e2e.py` が `<stem>Import.sql`（`sample_utf8Import.sql`）に依存。SQL ファイル名は変更しない。
- 案: レポートのみ `--out-dir` の run 隔離で対応（ファイル名据え置き）。

### T6. `anomaly-detection`（優先度: 低）
- 現状: `--output` / `--model` はユーザー指定必須で `exist_ok=True`。同一パス再実行で上書き（`io.py:18-27` ほか）。
- 評価: 出力先はユーザーが明示する設計のため、当面は運用ガイド（run 単位でパスを分ける）で足りる。必要なら `--run-id` オプションを検討。

### T7. `vcd-categorical-analysis/templates/analysis.R`（優先度: 低）
- 現状: `--run-id` 省略時は `./skill_out/vcd_categorical/` 固定で `categorical_results.json` 等を上書き（opt-in 隔離）。`--label` 未指定だと別データでも同名。
- 案: bayesian と同様に、run-id 未指定時も入力ハッシュ由来で自動隔離するか検討（`run_scope.R` の `resolve_run_id` を利用）。挙動変更を伴うため、テストへの影響を先に確認。

## 作業手順メモ（自宅環境）

```bash
# 1. 最新化（PR #6 が main にマージ済みである前提）
git checkout main && git pull origin main

# 2. 残タスク用ブランチ
git checkout -b cursor/fix-run-output-overwrite-remaining

# 3. Python 依存（初回のみ）
pip install -r requirements.txt   # 環境により --break-system-packages

# 4. 実装 → 検証（例）
#   step3 エラーパス（mysql 不在でも可）
python3 .agent/skills/flat-file-mysql-load-validation/scripts/step3_cli.py <sql> -d <db> --report-dir /tmp/r1
#   MySQL 起動後に本パス・cardinality・entity-matrix を実データで検証
#   er-diagram は --sqlite でも部分検証可

# 5. 回帰確認（baseline と同一であること）
python3 -m pytest tests/
for f in tests/test_*.R; do Rscript "$f"; done
```

- baseline（本メモ作成時点）: `pytest` 14 passed / 5 failed、R テスト 5 passed / 8 failed。失敗は既存の陳腐化テスト（削除済み `.cursor/skills` 参照、`--config` 誤用、構文エラー）で本タスクと無関係。**修正後もこの数が悪化しないこと**を確認する。
- 各修正は「1論理変更 = 1コミット」。ファイル名契約を変える場合は対応する `SKILL.md` を同一コミットで更新する。

## 参考
- レビュー観点の正本: 出力ディレクトリの一意化・上書き回避のみ。
- 関連: `.agent/shared/run_scope.R`（run 隔離ヘルパー: `resolve_run_id`, `run_output_dir_from_root`, `write_run_meta`）。
