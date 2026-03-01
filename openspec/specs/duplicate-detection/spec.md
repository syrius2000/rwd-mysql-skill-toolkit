# duplicate-detection

## Purpose

フラットファイル内の重複レコードを検出し、レポートを出力する。複数 CSV に対応する。現状はステップ 1（step1_cli.py）の一環で実施する。

## Requirements

### Requirement: 重複レコードの検出

システム SHALL、フラットファイル内の重複レコードを検出し、レポートを出力する。重複の定義は現状**全カラム一致**とする（キーカラム指定は将来拡張）。複数 CSV に対応し、step1_report.json に total / duplicates / unique をファイルごとに出力する。

#### Scenario: 重複がある場合

- **WHEN** CSV に同一内容の行（全カラム一致）が複数存在する
- **THEN** 重複件数（duplicates）とユニーク件数（unique = total − duplicates）を step1_report.json に出力する

#### Scenario: 重複がない場合

- **WHEN** 全行がユニークである
- **THEN** 重複件数 0、unique = total と報告する

#### Scenario: 複数 CSV に対する重複検出

- **WHEN** 複数の CSV ファイルを対象にステップ 1 を実行する
- **THEN** ファイルごとに path / total / duplicates / unique を step1_report.json に出力する
