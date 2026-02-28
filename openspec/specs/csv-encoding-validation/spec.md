# csv-encoding-validation

## Purpose

CP932 を想定した CSV のエンコーディング判定・検証。パイプライン内で標準ライブラリにより検証する。

## Requirements

### Requirement: CP932 の判定と検証

システム SHALL、パイプライン内で標準ライブラリ（codecs、TRY_ENCODINGS 方式）を用いて CSV のエンコーディングを CP932 として判定・検証する。専用の .py スクリプトは持たない。

#### Scenario: CP932 として検証成功

- **WHEN** CSV が CP932 でエンコードされている
- **THEN** 検証は成功し、後続のステップ（サンプル SQL 生成等）に進む

#### Scenario: エンコーディング検証失敗

- **WHEN** ファイルが CP932 でない、またはデコードに失敗する
- **THEN** 検証は失敗し、エラーメッセージを報告して処理を停止する
