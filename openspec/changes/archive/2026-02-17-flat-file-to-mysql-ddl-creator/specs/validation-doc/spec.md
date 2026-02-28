## ADDED Requirements

### Requirement: validation.md による手順・フローの文書化

システム SHALL、当 change 配下に validation.md を配置し、エンコーディング検証から件数比較・報告までのバリデーション手順とフローを明文化する。

#### Scenario: フロー概要の記述

- **WHEN** ユーザーが validation.md を読む
- **THEN** エンコーディング検証→レコード数カウント→重複検出・レポート→重複削除→MySQL 投入→投入後件数カウント→件数比較→報告の順が記述されている

#### Scenario: 成功条件の記述

- **WHEN** ユーザーが validation.md を読む
- **THEN** 成功条件「元件数 − 重複件数 = 投入件数」が明記されている

#### Scenario: 失敗時の報告

- **WHEN** 件数が一致しない場合
- **THEN** エラーとして報告し、元件数・重複件数・投入件数・差分をレポートに出力する旨が記述されている
