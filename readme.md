スキルをIDE用に用意する。

DB連携Skill

## Openspec について

## 最初の作業

`openspec init` でターミナルからProjectフォルダに初期設定を行う。IDEを複数えらべる。

## Project

-1- /opsx-new
-2.1- /opsx:ff
-2.2- /opsx:continue

/opsx:new
/opsx:ff        design.md, proposal.md, task.mdを作成する
/opsx:continue  design.md, proposal.md, task.mdを作成する

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
