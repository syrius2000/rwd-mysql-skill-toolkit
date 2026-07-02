# 対象スキル
vcd-bayesian-evidence-analysis

## 標準プロンプト（コピペ用）
> example/csv/titanic.csv を vcd-bayesian-evidence-analysis で分析してください。Pass 0 の config（example/analysis/titanic/run_demo/）を用い、出力は example/skill_out/vcd_bayesian/titanic/ に保存してください。Pass 1→2→3 の手順に従い、最終的に dashboard.html を出力してください。

## 入出力（example 固定）

- 入力:
  - `example/csv/titanic.csv`
  - `example/analysis/titanic/run_demo/analysis_config.json`
- 出力:
  - `example/skill_out/vcd_bayesian/titanic/run_titanic_demo/evidence_results.json` (統計結果)
  - `example/skill_out/vcd_bayesian/titanic/run_titanic_demo/executive_summary.md` (AI考察レポート)
  - `example/skill_out/vcd_bayesian/titanic/run_titanic_demo/dashboard.html` (ダッシュボード)

## 完了チェックリスト

- [ ] `evidence_results.json` が生成され、ResidualやEvidence Scoreの値が格納されていること
- [ ] `executive_summary.md` が生成され、エビデンスに基づく適正な解釈（日本語）が行われていること
- [ ] `dashboard.html` が生成され、ブラウザで閲覧可能な可視化要素が含まれていること
