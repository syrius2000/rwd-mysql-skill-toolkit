created: 2026-02-24 12:30 (JST)
author: AI Agent (LLM Model)

# 用語明文化とレポートへのユニーク件数追加プラン

## 方針

- **用語**: `duplicates` = 重複している**出現回数**（余分な行の数）。**ユニーク行数 = total − duplicates** をコード・スキル文書で明示する。
- **レポート**: ステップ 1 のレポートに `unique` を追加する。`unique = total - duplicates`（既存ロジックのまま、算出して出力に載せる）。

## 変更対象

| 種別  | ファイル                                                                                                                                     | 内容                                       |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| 本体  | flat_file_mysql/sample_sql.py                                                                           | docstring 明文化、レポートに `unique` 追加          |
| 本体  | flat_file_mysql/cli.py                                                                                         | 表示に `unique` 追加、期待値は `r["unique"]` を利用   |
| スキル | .cursor/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py | 関数 docstring・レポートに `unique`・表示に `unique` |
| スキル | .agent/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py   | 上と同内容                                    |
| スキル | .cursor/skills/flat-file-mysql-ddl-generation/SKILL.md                         | 用語 1 文追加                                 |
| スキル | .agent/skills/flat-file-mysql-ddl-generation/SKILL.md                           | 上と同内容                                    |
| スキル | overview 両方                                                                                                                              | 必要なら「レポートに unique を含む」旨 1 行              |
| テスト | tests/test_step1_e2e.py                                                                                       | `r["unique"] == 2` のアサーション追加             |

## 変更内容

### 1. flat_file_mysql/sample_sql.py

- `count_rows_and_duplicates` の docstring: 「(total, duplicates)。duplicates は重複している出現回数（余分な行の数）。ユニーク行数 = total − duplicates。」を追記。
- モジュール先頭 docstring: 「レポートの duplicates は重複出現回数。ユニーク行数 = total − duplicates。」を 1 行追加。
- `run_step1`: 各レポート辞書に `"unique": total - dups` を追加。エラー時は `"unique": 0` を追加。

### 2. flat_file_mysql/cli.py

- step1 の print: `total`, `duplicates` に加え `unique` を表示（例: `レコード数=..., 重複数=..., ユニーク数=...`）。
- pipeline の print: 同様に `unique` を表示。
- pipeline の expected: `sum(r["total"] - r["duplicates"] for r in reports)` を `sum(r["unique"] for r in reports)` に変更（レポートに `unique` がある前提）。

### 3. step1_cli.py（.cursor と .agent の 2 ファイル）

- `_count_rows_and_duplicates` の docstring: 「Returns (total, duplicates). duplicates は重複している出現回数（余分な行の数）。ユニーク行数 = total − duplicates。」
- `run_step1` のレポート辞書: `"unique": total - dup` を追加。
- main の print: `total`, `duplicates` に加え `unique` を出力（例: `total=..., duplicates=..., unique=...`）。
- step1_report.json: 既に reports をそのまま JSON 化しているため、`unique` を辞書に含めれば JSON にも出力される。

### 4. flat-file-mysql-ddl-generation/SKILL.md（.cursor と .agent）

- 「レコード数・重複数をレポート」の近くに 1 文追加: 「重複数（duplicates）は重複している出現回数（余分な行の数）。ユニーク行数 = total − duplicates。レポートには unique（ユニーク件数）も含む。」

### 5. flat-file-mysql-overview/SKILL.md（任意）

- ステップ 1 の説明に「レポートに total / duplicates / unique を含む」と 1 行書いてもよい（スキル ddl-generation に任せても可）。

### 6. tests/test_step1_e2e.py

- `sample_utf8.csv` は total=3, duplicates=1 のため unique=2。
- `assert r["unique"] == 2` を追加。

## データの流れ（変更後）

- レポート: `total`, `duplicates`, `unique`。期待投入件数 = `unique`。
- 既存の「期待値 = total − duplicates」は `unique` と同一のため、step3 の `--expected-count` の意味は変わらない。

## 実施後の作業（承認済み）

- **Artifacts への最終プラン保存**: 本プラン実施後に、最終プランを `docs/Artifacts/Artifact_00X_plan_duplicate_terminology_unique_MMDD_HHMM.md` として保存する。ファイル先頭に作成日時（JST）・作成者を記載し、本プラン本文を収める。連番（00X）は既存 Artifact の次番号とする。

## スキル文書の明文化（任意・承認済み）

- **load-validation**: `.cursor/skills/flat-file-mysql-load-validation/SKILL.md` および `.agent/skills/flat-file-mysql-load-validation/SKILL.md` の「手順（ステップ 3）」または件数比較の説明に 1 行追記する。「バリデーション完了＝ステップ 1 のユニーク数と DB レコード数が一致したとき」と明記する。

## 実施しないこと

- `count_rows_and_duplicates` の戻り値の型変更（tuple の要素追加）は行わない。`unique` は呼び出し元で `total - duplicates` から算出する。
- 重複「種類」数（2重・3重のキー数）の集計は今回の範囲外とする。
