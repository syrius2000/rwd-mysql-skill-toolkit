## 1. 標準ライブラリ化（ステップ 3）

- [x] 1.1 flat_file_mysql/execute_sql.py を mysql.connector 廃止し、subprocess で mysql クライアントを呼ぶ実装に変更する（run_sql_file, get_table_count）
- [x] 1.2 requirements.txt から mysql.connector-python を削除する（または「# stdlib only」のみ残す）

## 2. ステップ 1 用スクリプトのスキル配下設置

- [x] 2.1 .cursor/skills/flat-file-mysql-ddl-generation/scripts/ を作成し、step1_cli.py を配置する（encoding + sample_sql のロジックを標準ライブラリのみで 1 本に集約）
- [x] 2.2 step1_cli.py の起動例を SKILL に合わせて検証する（csv_paths, -o out_dir）。既定の出力先は ./skill-output/step1_sample_sql、実行 cwd はプロジェクトルートとする

## 3. ステップ 3 用スクリプトとプロンプトのスキル配下設置

- [x] 3.1 .cursor/skills/flat-file-mysql-load-validation/scripts/ を作成し、step3_cli.py を配置する（SQL 実行・件数取得を mysql subprocess で 1 本に集約）
- [x] 3.2 .cursor/skills/flat-file-mysql-load-validation/prompts/ を作成し、archive の step2-complete-sql.prompt.md をコピーする

## 4. SKILL.md の参照更新

- [x] 4.1 flat-file-mysql-ddl-generation/SKILL.md の「参照」および手順を、当スキル配下の scripts/step1_cli.py に統一する
- [x] 4.2 flat-file-mysql-load-validation/SKILL.md のステップ 3 CLI を scripts/step3_cli.py、ステップ 2 プロンプトを prompts/step2-complete-sql.prompt.md に統一する
- [x] 4.3 flat-file-mysql-overview/SKILL.md のプロンプト・CLI 参照を、archive 絶対パスから各スキル配下パスに変更する
- [x] 4.4 各 SKILL.md に「実行はプロジェクトルートを cwd、出力は ./skill-output/step1_sample_sql 等のサブディレクトリ」「実行前の前提条件・注意・確認事項」「不具合時は Step 1 からやり直し Step 2・3 も再実行、再実行で上書きされる旨・必要ならバックアップ」を追加する

## 5. 互換と検証

- [x] 5.1 flat_file_mysql/cli.py の step1/step3 が、変更後の execute_sql および既存 sample_sql と整合することを確認する（必要なら execute_sql を stdlib 化したうえでそのまま利用）
- [x] 5.2 スキル配下の step1_cli.py / step3_cli.py を python3 のみで実行し、macOS または Ubuntu で動作確認する
