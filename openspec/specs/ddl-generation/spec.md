# ddl-generation

## Purpose

CP932 CSV のヘッダーとサンプルに基づき、MySQL 8.0 互換の CREATE TABLE および LOAD DATA 用 DDL を生成する。

## Requirements

### Requirement: MySQL 8.0 用 DDL 生成

システム SHALL、CP932 CSV のヘッダーとサンプルに基づき、MySQL 8.0 互換の CREATE TABLE および LOAD DATA 用の DDL を生成する。複数 CSV の場合は CSV ごとに 1 本のサンプル SQL を発生させる。実行は step1_cli.py（Skill: flat-file-mysql-ddl-generation）により行い、出力先は `./skill_output/step1_sample_sql`（既定）とする。

#### Scenario: 数行の DDL 用サンプル SQL の生成

- **WHEN** ステップ 1 で CSV を読み、エンコードを確認した後
- **THEN** 数行の DDL 用サンプル SQL ファイル（`<basename>Import.sql`）を `./skill_output/step1_sample_sql` に出力する

#### Scenario: utf8mb4 および LOAD DATA 対応

- **WHEN** DDL を生成する
- **THEN** 文字セットは utf8mb4 を想定し、LOAD DATA で投入可能な形式とする
