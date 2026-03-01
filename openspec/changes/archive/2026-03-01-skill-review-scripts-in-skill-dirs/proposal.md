## Why

スキルがプロジェクト外にコピーしても単体で再現可能になるよう、必要な Python スクリプトを各スキルディレクトリ内に置き、仮想環境や pip に依存しない標準ライブラリのみの実装に統一する。現状はスクリプトがリポジトリルートの `flat_file_mysql/` にあり、ステップ 3 が `mysql.connector` に依存しているため、ポータビリティと運用の簡素化を実現する。

## What Changes

- **標準ライブラリ化**: ステップ 3 の DB 実行を `mysql.connector` から廃止し、`subprocess` で `mysql` クライアントを呼ぶ実装に変更する。Python は標準ライブラリのみ使用し、仮想環境・pip 不要とする。
- **スクリプトのスキル配下設置**: flat-file-mysql-ddl-generation にステップ 1 用スタンドアロン CLI（`scripts/step1_cli.py`）、flat-file-mysql-load-validation にステップ 3 用スタンドアロン CLI（`scripts/step3_cli.py`）を配置する。
- **プロンプトのスキル配下配置**: ステップ 2 用プロンプトを flat-file-mysql-load-validation の `prompts/` にコピーし、参照をスキル内に閉じる。
- **SKILL.md の参照統一**: 各スキルの「参照」を AnotherPJ や archive 絶対パスから、当スキル配下の `scripts/` および他スキル配下の `prompts/` に変更する。
- **実行 cwd と出力の統一**: スクリプトはプロジェクトルートを cwd として実行し、出力は `./skill-output/step1_sample_sql`、`step2_complete_sql`、`step3_report` のサブディレクトリに分ける。不具合時は Step 1 から再実行し Step 2・3 も再実行、再実行で上書きされる旨を SKILL に記載する。各 SKILL に実行前の前提条件・注意・確認事項を記載し、エージェントがユーザーに示す。
- **既存パッケージ**: `flat_file_mysql/` は互換用に残す場合、execute_sql を stdlib 化する。`requirements.txt` から mysql-connector-python を削除可能にする。

## Capabilities

### New Capabilities

- `skill-scripts-stdlib`: スキルで利用する Python スクリプトは標準ライブラリのみを使用する。ステップ 3 の SQL 実行・件数取得は `mysql` クライアントを subprocess で呼ぶ。
- `skill-scripts-placement`: ステップ 1 用 CLI は `.cursor/skills/flat-file-mysql-ddl-generation/scripts/`、ステップ 3 用 CLI とステップ 2 用プロンプトは `.cursor/skills/flat-file-mysql-load-validation/scripts/` および `prompts/` に配置する。
- `skill-docs-references`: flat-file-mysql 系 3 スキルの SKILL.md が参照する CLI・プロンプトのパスを、スキル配下の相対パス（または他スキル配下）に統一する。

### Modified Capabilities

- （なし。既存の ddl-generation / load-validation 等の要件は変えず、配置と参照先のみ変更する。）

## Impact

- **コード**: `flat_file_mysql/execute_sql.py` の実装変更（mysql.connector → subprocess）、新規 `.cursor/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py`、`.cursor/skills/flat-file-mysql-load-validation/scripts/step3_cli.py`、同 `prompts/step2-complete-sql.prompt.md`。
- **ドキュメント**: `.cursor/skills/flat-file-mysql-ddl-generation/SKILL.md`、`flat-file-mysql-load-validation/SKILL.md`、`flat-file-mysql-overview/SKILL.md` の参照・手順記載。
- **依存**: `requirements.txt` から mysql-connector-python 削除。実行環境に `mysql` クライアントが PATH にあることが前提となる。
