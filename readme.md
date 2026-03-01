# スキルをIDE用に用意する

- MySQLデータインポートSkill
  - MySQLデータエンコーディング検証Skill
  - MySQLデータ重複除去Skill
  - MySQLデータバリデーションSkill
  - MySQLデータ件数比較Skill

スキル正本は `.cursor/skills`。`.agent/skills`（Antigravity 用）との同期ルールは [docs/Artifacts/Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md](docs/Artifacts/Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md) を参照。

## 参考にすべきコード

- AnotherPJ/sample-template/CH_t05_covid_vaccine.txtImport.sql
- AnotherPJ/sample-template/SQLDistinct.prompt.md
- AnotherPJ/sample-template/SQLInsert.prompt.md

## Openspec によるSDD開発手順について

### 最初の作業

`openspec init` でターミナルからProjectフォルダに初期設定を行う。IDEを複数えらべる。

## Project start workflow

1. /opsx-new
2. /opsx:ff（2.1）
3. /opsx:continue（2.2）

/opsx:new
/opsx:ff        design.md, proposal.md, task.mdを一括生成する
/opsx:continue  design.md, proposal.md, task.mdを順序立てて作成する

``` bash
┌────────────────────┐
│ Start a Change               │  /opsx:new
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Create Artifacts             │  /opsx:ff or /opsx:continue
│ (proposal, specs,            │
│  design, tasks)              │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Implement Tasks              │  /opsx:apply
│ (AI writes code)             │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Archive & Merge              │  /opsx:archive
│ (Specs, Tasks)               │
└────────────────────┘
```
