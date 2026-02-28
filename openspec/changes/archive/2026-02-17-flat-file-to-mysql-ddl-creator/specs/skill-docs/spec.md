## ADDED Requirements

### Requirement: 2 分割 Skill とオーバービュー

システム SHALL、CP932 CSV から MySQL 8.0 互換 DDL を生成し投入するための Skill を 2 分割（Skill B: DDL 生成 / Skill C: 投入・バリデーション）で提供し、B→C の一連の流れ（ステップ 1→2→3）を説明するオーバービュー（README または親 Skill.md）を提供する。Skill は当リポジトリに配置する。

#### Scenario: Skill B の存在

- **WHEN** ユーザーが DDL 生成用の Skill を参照する
- **THEN** Skill B が存在し、CSV→数行サンプル SQL＋レポート（複数 CSV 対応）、CREATE TABLE / LOAD DATA 用の手順が記載されている

#### Scenario: Skill C の存在

- **WHEN** ユーザーが投入・バリデーション用の Skill を参照する
- **THEN** Skill C が存在し、完成版 SQL 作成支援・DB 名指定・指定 DB への実行・件数比較の手順が記載されている

#### Scenario: オーバービューの存在

- **WHEN** ユーザーが一連の流れを確認する
- **THEN** ステップ 1（サンプル SQL＋レポート）→ ステップ 2（完成版 SQL、DB 名指定）→ ステップ 3（対象 DB へ実行）が説明されている
