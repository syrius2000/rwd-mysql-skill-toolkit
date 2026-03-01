# validation-doc

## Purpose

バリデーション手順・フローを文書化する。実装では flat-file-mysql-overview（Skill）および readme.md でフローを説明する。

## Requirements

### Requirement: バリデーション手順・フローの文書化

システム SHALL、エンコーディング検証から件数比較・報告までのバリデーション手順とフローを、flat-file-mysql-overview（.cursor/skills/flat-file-mysql-overview/SKILL.md）および readme.md の「DB連携Skill（flat-file-mysql）の動き」にて明文化する。change 配下の validation.md は必須としない。

#### Scenario: フロー概要の記述

- **WHEN** ユーザーがオーバービューまたは readme を読む
- **THEN** ステップ 1（サンプル SQL＋レポート）→ ステップ 2（完成版 SQL、DB 名指定）→ ステップ 3（対象 DB へ実行・件数比較）の順が記述されている

#### Scenario: 成功条件の記述

- **WHEN** ユーザーが上記文書を読む
- **THEN** 成功条件「期待件数（step1 の unique）= 投入件数」が明記されている

#### Scenario: 失敗時の報告

- **WHEN** 件数が一致しない場合
- **THEN** エラーとして報告し、期待件数・投入件数・差分を step3_report に出力する旨が記述されている
