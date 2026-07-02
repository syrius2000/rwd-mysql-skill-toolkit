# 対象スキル
vcd-pass0-consultation

## 標準プロンプト（コピペ用）
> example/csv/titanic_100x.csv を vcd-pass0-consultation スキルで事前検分してください。Class, Sex, Age, Survived 列を分析変数とし、度数として Freq を指定します。run_id は titanic100x_demo とし、出力は example/analysis/titanic_100x/run_demo/ に保存してください。

## 入出力（example 固定）

- 入力: `example/csv/titanic_100x.csv`
- 出力:
  - `example/analysis/titanic_100x/run_demo/analysis_config.json`
  - `example/analysis/titanic_100x/run_demo/data_analysis_scope.md`
  - `example/analysis/titanic_100x/run_demo/inspection_results.json`

## 完了チェックリスト

- [ ] `example/analysis/titanic_100x/run_demo/analysis_config.json` が生成されていること
- [ ] `data_analysis_scope.md` が生成されていること
- [ ] 大標本（N≈220,000）のデータ規模が検知されていること
