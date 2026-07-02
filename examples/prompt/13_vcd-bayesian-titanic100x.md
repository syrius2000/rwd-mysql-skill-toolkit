# 対象スキル
vcd-bayesian-evidence-analysis

## 標準プロンプト（コピペ用）
> example/csv/titanic_100x.csv を vcd-bayesian-evidence-analysis で分析してください。Pass 0 の config（example/analysis/titanic_100x/run_demo/）を用い、出力は example/skill_out/vcd_bayesian/titanic_100x/ に保存してください。Pass 1→2→3 の手順に従い、最終的に dashboard.html を出力してください。完了後、titanic（小標本）との N・BF・Evidence Score の違いを説明してください。

## 入出力（example 固定）

- 入力:
  - `example/csv/titanic_100x.csv`
  - `example/analysis/titanic_100x/run_demo/analysis_config.json`
- 出力:
  - `example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/evidence_results.json`
  - `example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/executive_summary.md`
  - `example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/dashboard.html`

## 完了チェックリスト

- [ ] 大標本用（100x）のダッシュボードやサマリーレポートが生成されていること
- [ ] 小標本との対比（P値の呪縛によるBFの巨大化現象など）について、分析的な説明があること
