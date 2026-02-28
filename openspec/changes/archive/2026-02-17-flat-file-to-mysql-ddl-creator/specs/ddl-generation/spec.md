## ADDED Requirements

### Requirement: MySQL 8.0 用 DDL 生成

システム SHALL、CP932 CSV のヘッダーとサンプルに基づき、MySQL 8.0 互換の CREATE TABLE および LOAD DATA 用の DDL を生成する。複数 CSV の場合は CSV ごとに 1 本のサンプル SQL を発生させる。

#### Scenario: 数行の DDL 用サンプル SQL の生成

- **WHEN** ステップ 1 で CSV を読み、エンコードを確認した後
- **THEN** 数行の DDL 用サンプル SQL ファイル（CH_t01 / CH_t05 形式を参考）を出力する

#### Scenario: utf8mb4 および LOAD DATA 対応

- **WHEN** DDL を生成する
- **THEN** 文字セットは utf8mb4 を想定し、LOAD DATA で投入可能な形式とする
