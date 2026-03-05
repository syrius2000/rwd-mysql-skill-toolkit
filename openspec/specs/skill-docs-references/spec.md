# skill-docs-references

## Purpose

flat-file-mysql 系スキルの SKILL.md が参照する CLI・プロンプトをスキル配下に統一し、前提条件・再実行ポリシーを記載する。

## Requirements

### Requirement: ddl-generation SKILL references local script
flat-file-mysql-ddl-generation の SKILL.md は、CLI の参照先を当スキル配下の `scripts/step1_cli.py` とし、AnotherPJ や外部パスを参照しない。

#### Scenario: SKILL describes local script usage
- **WHEN** エージェントまたは利用者が flat-file-mysql-ddl-generation の SKILL.md を読む
- **THEN** 「CLI 呼び出し」はスキル配下の `scripts/step1_cli.py` を実行する手順として記載されている

### Requirement: load-validation SKILL references local script and prompts
flat-file-mysql-load-validation の SKILL.md は、ステップ 3 の CLI を当スキル配下の `scripts/step3_cli.py`、ステップ 2 のプロンプトを当スキル配下の `prompts/step2-complete-sql.prompt.md` として参照する。

#### Scenario: SKILL describes step3 script and step2 prompt paths
- **WHEN** エージェントまたは利用者が flat-file-mysql-load-validation の SKILL.md を読む
- **THEN** ステップ 3 は `scripts/step3_cli.py`、ステップ 2 のプロンプトは `prompts/step2-complete-sql.prompt.md` を参照する旨が記載されている

### Requirement: overview SKILL references other skills for CLI and prompt
flat-file-mysql-overview の SKILL.md は、ステップ 1 の CLI を flat-file-mysql-ddl-generation スキル配下、ステップ 2 のプロンプトおよびステップ 3 の CLI を flat-file-mysql-load-validation スキル配下として参照する。openspec の archive 絶対パスは使用しない。

#### Scenario: Overview points to skill-local paths
- **WHEN** エージェントまたは利用者が flat-file-mysql-overview の SKILL.md を読む
- **THEN** プロンプトおよび CLI の参照が、flat-file-mysql-ddl-generation / flat-file-mysql-load-validation のスキル配下パスで記載されている

### Requirement: SKILL shows prerequisites and cautions to user before or when running
flat-file-mysql 系スキル（ddl-generation, load-validation, overview）の SKILL.md には、スキル実行前または実行時にユーザーに示す **前提条件・注意・確認事項** を記載する。エージェントはスクリプトを実行する前に、これらの内容をユーザーに提示するか確認する。

#### Scenario: Prerequisites and cautions are documented
- **WHEN** 利用者が各スキルの SKILL.md を読む
- **THEN** 実行前の前提条件（例: mysql が PATH にある、DB 名を確認した）および注意・確認事項がセクションとして存在する

#### Scenario: Agent surfaces prerequisites when invoking skill
- **WHEN** エージェントが当該スキルに従ってスクリプトを実行する直前
- **THEN** エージェントは SKILL に記載された前提条件・注意・確認事項をユーザーに示すか、確認を求める

### Requirement: SKILL documents re-run and overwrite policy when problem at step 1
flat-file-mysql 系スキルの SKILL.md には、Step 1 で不具合を見つけた場合の運用を記載する。内容: 原因を修正したうえで Step 1 から再実行し、Step 2・3 も再実行すること。再実行時は `./skill_output` 配下が上書きされるため、前の結果を残したい場合は事前にバックアップすること。

#### Scenario: Re-run and overwrite policy is documented
- **WHEN** 利用者が各スキルの SKILL.md を読む
- **THEN** 「不具合時は Step 1 からやり直し、Step 2・3 も再実行する」「再実行で出力は上書きされる。必要なら事前にバックアップする」旨が記載されている
