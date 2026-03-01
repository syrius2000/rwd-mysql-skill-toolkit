# skill-scripts-stdlib

## ADDED Requirements

### Requirement: Python scripts use standard library only
スキルで参照する Python スクリプトは、標準ライブラリ以外の import を使用してはならない。仮想環境や pip のインストールを前提としない。

#### Scenario: Step1 CLI runs without venv
- **WHEN** ユーザーが `.cursor/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py` を `python3 scripts/step1_cli.py csv.csv -o ./out` で実行する
- **THEN** 追加のパッケージがなくても正常にサンプル SQL とレポートが出力される

#### Scenario: Step3 CLI uses mysql client via subprocess
- **WHEN** ユーザーが `.cursor/skills/flat-file-mysql-load-validation/scripts/step3_cli.py` で SQL 実行または件数取得を行う
- **THEN** スクリプトは `mysql` コマンドを subprocess で呼び出し、mysql.connector 等の Python ドライバを使用しない

### Requirement: Step3 SQL execution and count via mysql CLI
ステップ 3 の SQL ファイル実行およびテーブル件数取得は、`mysql` クライアントを subprocess で起動して行う。実行環境の PATH に `mysql` が存在することを前提とする。

#### Scenario: Run SQL file
- **WHEN** step3_cli に SQL ファイルパスと DB 名・接続情報が渡される
- **THEN** システムは `mysql -h ... -P ... -u ... -p... database_name < sql_file` と等価な subprocess を実行し、成功時は終了コード 0、失敗時はエラーメッセージを返す

#### Scenario: Get table count
- **WHEN** step3_cli にテーブル名（およびオプションで期待件数）が渡される
- **THEN** システムは `mysql ... -e "SELECT COUNT(*) FROM \`table\`"` を実行し、stdout をパースして件数を返す
