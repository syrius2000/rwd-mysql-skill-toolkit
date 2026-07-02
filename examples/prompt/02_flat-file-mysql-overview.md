# 対象スキル
flat-file-mysql-overview

## 標準プロンプト（コピペ用）
> example/csv/rwd_sample/ 配下の patients.csv と visits.csv を MySQL にロードするための DDL 作成とデータインポートを実行・設計してください。出力は example/skill_out/flat_file/ 配下に保存してください。

## 入出力（example 固定）

- 入力: `example/csv/rwd_sample/patients.csv`, `example/csv/rwd_sample/visits.csv` (CP932エンコード)
- 出力:
  - `example/skill_out/flat_file/step1_sample_sql/` (DDL案、簡易確認SQL)
  - `example/skill_out/flat_file/step2_complete_sql/` (完成版SQL)
  - `example/skill_out/flat_file/step3_report/` (投入結果・件数検証レポート)

## 完了チェックリスト

- [ ] `example/skill_out/flat_file/step1_sample_sql/` にサンプルDDLとレポートが生成されていること
- [ ] `example/skill_out/flat_file/step2_complete_sql/` に完成版投入SQLが生成されていること
- [ ] `example/skill_out/flat_file/step3_report/` にMySQL実行ログや行数一致検証レポートが存在すること
