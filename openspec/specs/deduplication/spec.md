# deduplication

## Purpose

重複検出結果（step1 の unique 件数）と DB 投入後の件数を整合させる。現状のパイプラインでは「ユニークのみの CSV ファイル」は出力せず、件数比較により整合性を検証する。

## Requirements

### Requirement: 重複削除の扱いと件数整合

システム SHALL、ステップ 1 で得た total / duplicates / unique を step1_report.json に出力する。ユニーク件数（unique = total − duplicates）はステップ 3 の件数バリデーションで「期待件数」として用いる。重複を含む CSV を LOAD DATA 等で投入する場合、DB 側のユニーク制約・IGNORE 等で重複を防ぐ想定とする。**ユニークなレコードのみの CSV をファイルとして出力する機能は現状提供しない。**

#### Scenario: 件数整合の検証

- **WHEN** ステップ 3 で件数バリデーションを実行する
- **THEN** 期待件数（step1 の unique）と DB 投入後の COUNT を比較し、一致すれば成功・不一致ならレポートに差分を出力する

#### Scenario: レポート上の整合

- **WHEN** 重複検出・件数比較を実行する
- **THEN** step1_report.json の unique と step3_report の投入後件数が一致することを以って整合とする
