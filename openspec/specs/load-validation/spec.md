# load-validation

## Purpose

フラットファイルの元件数・重複削除後の件数（step1 の unique）・DB 投入後の件数を比較し、整合性を検証する。ステップ 3 で step3_cli.py により実行する。

## Requirements

### Requirement: 件数比較バリデーション

システム SHALL、ステップ 3（step3_cli.py、Skill: flat-file-mysql-load-validation）で、step1 の unique を期待件数として DB 投入後の件数と比較する。レポートは `./skill-output/step3_report` に出力する（例: step3_report.json）。

#### Scenario: 整合が取れている場合

- **WHEN** 期待件数（step1 の unique）= DB 投入件数 である
- **THEN** バリデーションは成功し、サマリをレポートに出力する

#### Scenario: 整合が取れていない場合

- **WHEN** 上記の等式が成立しない
- **THEN** バリデーションは失敗し、各件数と差分をレポートに出力する

#### Scenario: バリデーションレポートの出力

- **WHEN** ステップ 3 のバリデーションを実行する
- **THEN** 期待件数、投入後件数、成功/失敗を `./skill-output/step3_report` に出力する
