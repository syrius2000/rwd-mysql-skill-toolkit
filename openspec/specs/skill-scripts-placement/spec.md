# skill-scripts-placement

## Purpose

ステップ 1・3 用 CLI とステップ 2 用プロンプトを各スキルディレクトリ配下に配置し、実行 cwd と出力先を統一する。

## Requirements

### Requirement: Step1 CLI under ddl-generation skill
ステップ 1 用のスタンドアロン CLI は `.cursor/skills/flat-file-mysql-ddl-generation/scripts/` に配置する。ファイル名は `step1_cli.py` とする。

#### Scenario: Step1 script exists in skill dir
- **WHEN** リポジトリまたはスキルディレクトリをクローン/コピーした利用者が、当該スキル配下の scripts を参照する
- **THEN** `scripts/step1_cli.py` が存在し、`python3 scripts/step1_cli.py csv_path [csv_path ...] -o out_dir` で実行可能である

### Requirement: Step3 CLI and step2 prompt under load-validation skill
ステップ 3 用のスタンドアロン CLI は `.cursor/skills/flat-file-mysql-load-validation/scripts/step3_cli.py` に、ステップ 2 用プロンプトは同スキル配下の `prompts/step2-complete-sql.prompt.md` に配置する。

#### Scenario: Step3 script exists in load-validation skill
- **WHEN** 利用者が flat-file-mysql-load-validation スキル配下の scripts を参照する
- **THEN** `scripts/step3_cli.py` が存在し、完成版 SQL の実行およびオプションで件数比較が可能である

#### Scenario: Step2 prompt exists in load-validation skill
- **WHEN** 利用者がステップ 2 用プロンプトを参照する
- **THEN** `prompts/step2-complete-sql.prompt.md` が当該スキル配下に存在し、`{{database_name}}` 等のプレースホルダを含む

### Requirement: Execution from project root and output to skill-output subdirs
スキルが参照するスクリプトの実行は、プロジェクトルートをカレントディレクトリとして行う。出力は `./skill-output` 配下をステップ単位で分ける: `step1_sample_sql/`（サンプル SQL・レポート）、`step2_complete_sql/`（完成版 SQL）、`step3_report/`（実行結果・件数比較）。step1 の `-o` の既定値は `./skill-output/step1_sample_sql` とする。SKILL.md にこの取り決めを明記する。

#### Scenario: SKILL documents cwd and output subdirs
- **WHEN** エージェントまたは利用者が flat-file-mysql 系スキルの SKILL.md を読む
- **THEN** 実行はプロジェクトルートで行い、出力は `./skill-output/step1_sample_sql` 等のサブディレクトリに書く旨が記載されている
