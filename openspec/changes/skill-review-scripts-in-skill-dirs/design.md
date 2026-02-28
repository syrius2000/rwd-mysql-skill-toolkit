## Context

- 現状: `.cursor/skills/` の flat-file-mysql 系 3 スキルは SKILL.md のみ。実行ロジックはルートの `flat_file_mysql/` パッケージにあり、ステップ 3 が mysql.connector に依存している。ddl-generation は AnotherPJ のスクリプト、overview は archive の絶対パスを参照している。
- 制約: Python は標準ライブラリのみ、仮想環境を作らない。macOS (BSD) と Ubuntu (GNU) の両方で動作させる。Cursor の [エージェントスキル](https://cursor.com/ja/docs/context/skills) に従い、スキルは `scripts/`・`references/`・`assets/` 等で自己完結させる。
- ステークホルダー: 同一リポジトリ内のエージェント利用、およびスキルを他プロジェクトへコピーして使う利用者。

## Goals / Non-Goals

**Goals:**
- スキルディレクトリをコピーするだけでステップ 1・3 の CLI が `python3 scripts/xxx.py` で実行可能になること。
- pip / venv に依存せず、`mysql` クライアントが PATH にあればステップ 3 が動くこと。
- SKILL.md の参照がスキル配下または他スキル配下の相対的な位置に統一されること。

**Non-Goals:**
- openspec-* スキルのスクリプト化やリネーム。
- 既存の `flat_file_mysql` パッケージの削除（互換用に残すかは実装時に判断）。

## Decisions

1. **ステップ 3 の DB 実行を subprocess に統一**
   - 選択: `mysql` コマンドを subprocess で実行（`run_sql_file` は `mysql ... db < file`、`get_table_count` は `mysql ... -e "SELECT COUNT(*) FROM ..."` の stdout をパース）。
   - 代替案: mysql.connector を残して requirements.txt で管理 → 仮想環境が必要になり、ポータビリティの目標に反するため不採用。

2. **スクリプトはスキル配下にスタンドアロンで配置**
   - 選択: step1 は encoding + sample_sql のロジックを 1 本の `step1_cli.py` に集約。step3 は SQL 実行・件数取得を 1 本の `step3_cli.py` に集約。いずれも import は stdlib のみ。
   - 代替案: ルートの flat_file_mysql をそのまま参照する → スキル単体でコピーしたときに動かなくなるため不採用。

3. **プロンプトは load-validation スキル配下にコピー**
   - 選択: archive の `step2-complete-sql.prompt.md` を `.cursor/skills/flat-file-mysql-load-validation/prompts/` にコピーし、overview および load-validation の SKILL からは「当スキル配下の prompts/」を参照する。
   - 代替案: openspec の change パスを参照し続ける → アーカイブ移行や別リポジトリでは参照が壊れるため不採用。

4. **既存 flat_file_mysql パッケージ**
   - 選択: execute_sql を stdlib 化し、スキル配下スクリプトと同等の挙動を保つ。requirements.txt から mysql.connector-python を削除。パッケージは互換用に残すか、後で thin ラッパー化するかは実装時に判断。

5. **実行 cwd と出力ディレクトリの統一**
   - 選択: スキルが実行するスクリプトは **プロジェクトルートをカレントディレクトリ** として実行する。出力は **`./skill-output`** 配下をステップ単位で分ける（運用のしやすさのため）:
     - `./skill-output/step1_sample_sql/` … サンプル SQL とレコード数・重複レポート
     - `./skill-output/step2_complete_sql/` … 完成版インポート SQL
     - `./skill-output/step3_report/` … 実行結果・件数比較レポート
   - step1 の `-o` の既定値は `./skill-output/step1_sample_sql` とする。
   - 理由: 再現性と「どのステップの結果か」の一目での判別を確保する。

6. **不具合時の再実行と上書き**
   - 選択: Step 1 で不具合を見つけた場合は、原因を修正したうえで **Step 1 から再実行**し、続けて **Step 2・3 も再実行**する（Step 1 の出力が変わるため Step 2・3 の入力も変わる）。再実行時は **`./skill-output` 配下は上書き**される。前の結果を残したい場合は利用者が事前にバックアップする。
   - SKILL.md に「不具合時は Step 1 からやり直し、Step 2・3 も再実行すること」「再実行で出力は上書きされる。必要なら事前にバックアップすること」を記載する。

## Risks / Trade-offs

- **[Risk] 実行環境に `mysql` クライアントが無い** → Mitigation: SKILL および README で「PATH に mysql があること」を前提として明記する。
- **[Risk] subprocess による SQL 実行でパスワードがプロセス一覧に露出する** → Mitigation: 既存と同様に MYSQL_PASSWORD 環境変数やオプションで渡す運用のまま。本 change では認証方式は変更しない。
- **[Trade-off] スキル配下にスクリプトを二重に持つと、flat_file_mysql との同期が発生しうる** → スキル配下を正とし、flat_file_mysql は同じロジックを import するか subprocess で呼ぶ形に寄せることで一貫性を保つ。
