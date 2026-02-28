# deduplication

## Purpose

検出された重複レコードを削除し、ユニークなレコードのみの CSV を出力する。

## Requirements

### Requirement: 重複削除処理

システム SHALL、検出された重複レコードを削除し、ユニークなレコードのみの CSV を出力する。重複判定ルールは duplicate-detection と同一とする。

#### Scenario: 重複削除後の出力

- **WHEN** 重複検出済みの CSV に対して重複削除を実行する
- **THEN** ユニークなレコードのみを含む CSV を出力する

#### Scenario: 件数整合

- **WHEN** 重複削除を実行する
- **THEN** 出力件数は「元件数 − 重複件数」と一致する
