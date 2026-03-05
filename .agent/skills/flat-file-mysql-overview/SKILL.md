---
name: flat-file-mysql-overview
description: CP932 CSV を MySQL に投入する一連の流れ（ステップ 1→2→3）のオーバービュー。Skill B と Skill C の使い分け。Antigravity 用。
license: MIT
metadata:
  author: flat-file-to-mysql-ddl-creator
  version: "1.0"
---

CP932 の CSV を MySQL 8.0 に投入するまでの 3 ステップの流れと、各ステップで利用する Skill の概要。

## 実行前提・注意

- 実行 cwd は **プロジェクトルート**。
- 出力は `./skill_output` 配下のサブディレクトリで管理する。
  - `./skill_output/step1_sample_sql`
  - `./skill_output/step2_complete_sql`
  - `./skill_output/step3_report`
- 実行前に前提条件（DB 名、mysql コマンド可用性、対象 CSV）をユーザーに示して確認する。
- Step 1 で不具合を見つけた場合は Step 1 から再実行し、Step 2・Step 3 も再実行する。
- 再実行時は出力が上書きされる。必要なら事前にバックアップする。
- 大容量 CSV では件数バリデーション（ステップ 3）をスキップできる。エージェントが確認する。

## フロー概要

```
ステップ 1: サンプル SQL + レポート  →  ステップ 2: 完成版 SQL（DB 名指定）  →  ステップ 3: 対象 DB へ実行
        Skill B + CLI                       エージェント + プロンプト                  Skill C + CLI
```

1. **ステップ 1**: CSV を読み、エンコードを確認し、数行の DDL 用サンプル SQL を作成。レコード数・重複数・ユニーク数をレポート（total / duplicates / unique。複数 CSV 対応）。**Skill B**（flat-file-mysql-ddl-generation）に従い、`python3 .agent/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py ... -o ./skill_output/step1_sample_sql` を実行する。
2. **ステップ 2**: ステップ 1 の出力と保存プロンプト（`{{database_name}}` 指定可能）に従い、完成版インポート SQL を生成。**DB 名が未指定の場合はここでストップ**し、「DB名を明示してから実行してください」と表示。完成版 SQL は `./skill_output/step2_complete_sql` に保存する。
3. **ステップ 3**: 完成した SQL を指定した対象 DB へ実行。ステップ 3 は任意。エージェントが件数バリデーションの実施有無をユーザーに確認し、『はい』の場合のみ **Skill C**（flat-file-mysql-load-validation）に従い `python3 .agent/skills/flat-file-mysql-load-validation/scripts/step3_cli.py ... --report-dir ./skill_output/step3_report` を実行し、件数比較レポートを出力する。

## 関連 Skill

| Skill | 役割 |
|-------|------|
| flat-file-mysql-ddl-generation | ステップ 1: サンプル SQL 生成＋レポート（CLI 呼び出し） |
| flat-file-mysql-load-validation | ステップ 2 の DB 名確認・完成版 SQL 生成、ステップ 3: 投入・件数比較（CLI 呼び出し） |

## プロンプト

- ステップ 2 用: `.agent/skills/flat-file-mysql-load-validation/prompts/step2-complete-sql.prompt.md`（DB 名は `{{database_name}}`）
