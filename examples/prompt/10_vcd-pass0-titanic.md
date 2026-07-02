# 対象スキル
vcd-pass0-consultation

## 標準プロンプト（コピペ用）
> example/csv/titanic.csv を vcd-pass0-consultation スキルで事前検分してください。Class, Sex, Age, Survived 列を分析変数とし、度数として Freq を指定します。run_id は titanic_demo とし、出力は example/analysis/titanic/run_demo/ に保存してください。

## 入出力（example 固定）

- 入力: `example/csv/titanic.csv`
- 出力:
  - `example/analysis/titanic/run_demo/analysis_config.json`
  - `example/analysis/titanic/run_demo/data_analysis_scope.md`
  - `example/analysis/titanic/run_demo/inspection_results.json`

## 完了チェックリスト

- [ ] `example/analysis/titanic/run_demo/analysis_config.json` が生成され、変数定義や度数・出力先が正しいこと
- [ ] `data_analysis_scope.md` が生成され、欠損値・外れ値などのチェック結果や分析目的が記載されていること
- [ ] `inspection_results.json` が生成され、度数分布やクロス集計の初期結果が格納されていること
