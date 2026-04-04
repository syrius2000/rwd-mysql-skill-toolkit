# vcd-categorical-analysis 自動テスト実装計画

## 概要

`vcd-categorical-analysis` スキルにおいて、コード改修後のデグレード（デバッグ時のバグ混入）を防ぐため、基準データ（HairEyeColor）を用いた自動検証テストを実装する。

## Proposed Changes

### vcd-categorical-analysis

#### [NEW] [verify_skill.sh](file:///Users/myamaguchi/Programing/OSX_IDE_Skill_management/.agent/skills/vcd-categorical-analysis/tests/verify_skill.sh)
- R がインストールされているか確認。
- `analysis.R --profile` を実行し、`data_profile.json` の存在を確認。
- `analysis.R --render` を実行し、主要な 15 ファイル（HTML, PNG, CSV）が正しく生成されたか検証。

#### [NEW] [test_logic.R](file:///Users/myamaguchi/Programing/OSX_IDE_Skill_management/.agent/skills/vcd-categorical-analysis/tests/test_logic.R)
- 統計計算の期待値検証（オプション）。
- `loglm` が特定のデータで正しく収束するか確認。

### 共通化・ミラーリング

- 修正が完了次第、`.cursor/skills/vcd-categorical-analysis/` にも `tests/` ディレクトリをミラーリング。

## Verification Plan

### 自動テスト
- `bash .agent/skills/vcd-categorical-analysis/tests/verify_skill.sh` を実行し、すべてのチェックが PASS することを確認。

### 手動確認
- 生成された `skill_out/vcd_categorical/` の中身を目視で確認。
