---
name: mysql-er-diagram
description: 指定した MySQL データベースのテーブルのみを抽出し、Draw.io互換XMLおよびPlantUMLのER図を生成する。辞書CSVは都度フル再生成。Cursor および Antigravity（.agent）で利用可能。
license: MIT
metadata:
  author: mysql-er-diagram-skill
  version: "2.0"
---

指定されたMySQLデータベースの**テーブル一覧**（View等を除く BASE TABLE のみ）と**各テーブルのカラム一覧**を取得し、ER図（**Draw.io 互換 XML** と **PlantUML**）の**両方**を常に生成する。辞書（`[DB名]_dictionary.csv`）は毎回DBから再取得してフル再生成し、既存CSVは読み込まない。Draw.io XML の色・スタイルはスクリプト内で固定されており、環境差で崩れない。

## 概要（動作イメージ）

1. **DB名指定** → スクリプトを実行する。
2. **スキーマ取得** → DBから **TABLE_TYPE = 'BASE TABLE'** のテーブルのみとカラム情報を取得。共通キー名（PATIENTNO 等）から参照先を推論し、辞書行を組み立てる。
3. **辞書・ER図出力** → `[DB名]_dictionary.csv` を全件上書き出力し、続けて **Draw.io XML**（`[DB名]_er_MMDD_HHMM.xml`）と **PlantUML**（`[DB名]_er_MMDD_HHMM.md`）の両方を生成する。

## トリガー

- 「◯◯ DB の ER図を出して」
- 「指定 DB のテーブル一覧から Draw.io のER図を作成したい」

## 入力

- **DB 名**（必須）。
- **出力ディレクトリ**（任意）。未指定時は `./skill_out/`。

## 前提

- テーブルは `TABLE_TYPE = 'BASE TABLE'` で**View 等を除外**すること。

## 認証情報の優先順位

| 優先度 | ソース | 説明 |
|--------|--------|------|
| 1 | `--env` フラグ | 明示的に `.env` ファイルパスを指定 |
| 2 | プロジェクトルートの `.env` | スクリプトから祖先ディレクトリを最大10階層遡って自動探索 |
| 3 | `~/.my.cnf` | mysql CLI が自動的に読み込む |

> [!WARNING]
> `~/.my.cnf` のパーミッションは `600` にすること: `chmod 600 ~/.my.cnf`

## 手順

1. ユーザー指示から対象の **データベース名** を取得する。
2. 以下のコマンドを実行する。
   ```bash
   python3 .agent/skills/mysql-er-diagram/scripts/generate_er.py --db <ターゲットDB名>
   ```
   **オプション:**
   - `--out <出力ディレクトリ>`: 出力先（デフォルト: `./skill_out/`）
   - `--env <.envファイルパス>`: 認証用 .env を明示指定
3. 生成された `[DB名]_dictionary.csv`、`[DB名]_er_MMDD_HHMM.xml`、`[DB名]_er_MMDD_HHMM.md` を確認し、ユーザーに報告する。

## Cursor / Antigravity の違い

- 正本は `.agent/skills/mysql-er-diagram/`。変更後は `./scripts/sync-cursor-skills.sh` で `.cursor/skills/` に同期する。実行コマンドのパスは、Cursor では `.cursor/skills/mysql-er-diagram/scripts/generate_er.py`、Antigravity では `.agent/skills/mysql-er-diagram/scripts/generate_er.py` を使う。

## 次のステップ: Query 作成支援

DB構造、テーブル分布、ID所在を確認した後、分析目的に応じた SQL を作る場合は `mysql-create-query-support` を使う。
この支援では、自然文の問いを粒度・JOIN・期間・検証観点に分解し、`sql/drafts/<topic>/main_query.sql`、`validation_query.sql`、`query_note.md` を作成する。
