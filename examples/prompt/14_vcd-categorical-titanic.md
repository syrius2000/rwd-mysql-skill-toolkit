# 対象スキル
vcd-categorical-analysis

## 標準プロンプト（コピペ用）
> example/csv/titanic.csv を vcd-categorical-analysis で分析してください。入力変数として Class, Sex, Age, Survived、度数として Freq を用い、カイ二乗検定およびモザイクプロットの作成を行ってください。出力は example/skill_out/vcd_categorical/titanic/ に保存し、ダッシュボードとエグゼクティブサマリーを出力してください。

## 入出力（example 固定）

- 入力: `example/csv/titanic.csv`
- 出力:
  - `example/skill_out/vcd_categorical/titanic/executive_summary.md` (カテゴリカル分析考察レポート)
  - `example/skill_out/vcd_categorical/titanic/dashboard.html` (カイ二乗検定結果やモザイクプロットを埋め込んだダッシュボード)

## 完了チェックリスト

- [ ] `executive_summary.md` に統計検定結果と解釈が日本語で記述されていること
- [ ] `dashboard.html` にモザイクプロットなどの可視化要素が含まれていること
