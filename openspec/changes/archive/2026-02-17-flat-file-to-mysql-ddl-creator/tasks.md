## 1. 参照分析・準備

- [x] 1.1 AnotherPJ の参照コード・ドキュメントを分析（make_sample_sql_files.py, readme.md, SQLImportAndDedupe.prompt.md, SQLDistinct.prompt.md, サンプル SQL）
- [x] 1.2 参照一覧を design.md と整合させる

## 2. Skill.md（2 分割 + オーバービュー）

- [x] 2.1 Skill B: DDL 生成（CSV→数行サンプル SQL＋レコード数・重複数レポート。複数 CSV 対応。CREATE TABLE / LOAD DATA 用）。エージェントが CLI を呼ぶ前提で手順を書く
- [x] 2.2 ステップ 2 用プロンプトを新規作成（DB 名を `{{database_name}}` またはエージェント渡しで指定可能。AnotherPJ/SQLImportAndDedupe.prompt.md を参考）
- [x] 2.3 Skill C: 投入とバリデーション（完成版 SQL 作成支援・DB 名指定・指定 DB への実行・件数比較）。エージェントが CLI を呼ぶ前提で手順を書く
- [x] 2.4 オーバービュー: B→C の一連の流れ（ステップ 1→2→3）を説明する README または親 Skill.md

## 3. validation.md

- [x] 3.1 当 change 配下に validation.md を配置（エンコード検証→カウント→重複検出→削除→投入→件数比較→報告）

## 4. CLI・検証・DDL・投入

- [x] 4.1 Python プロジェクト構造（CLI エントリ、モジュール分割）、requirements.txt（pandas, mysql-connector-python 必須。chardet は必要に応じて）、argparse
- [x] 4.2 CP932 検証（標準ライブラリ codecs / TRY_ENCODINGS 方式でパイプライン内に組み込み）
- [x] 4.3 ステップ 1: 数行の DDL 用サンプル SQL 作成、レコード数・重複数レポート（複数 CSV 対応）
- [x] 4.4 ステップ 2: サンプルと保存プロンプトに従う完成版 SQL 生成、DB 名指定対応（エージェント＋プロンプトで実施、CLI 不要）
- [x] 4.5 ステップ 3: 完成版 SQL の指定 DB への実行（INSERT バッチ / LOAD DATA オプション）
- [x] 4.6 件数比較バリデーション（元件数・重複件数・投入件数）とレポート出力

## 5. 統合・テスト

- [x] 5.1 一括パイプライン（エンコード検証 → サンプル SQL＋レポート → 完成版 SQL → 指定 DB へ実行 → 件数比較）の実装
- [x] 5.2 サンプル CSV を用いた E2E テスト
