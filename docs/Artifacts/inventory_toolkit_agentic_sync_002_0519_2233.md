# toolkit ↔ agentic スキル同期ベースライン

created: 2026-05-19 22:33 (JST)
author: Composer

## 方針

- **正本:** `rwd-mysql-skill-toolkit` の `.agent/skills/`
- **サテライト:** `agentic-evidence-analysis`（同名5スキルを rsync 上書き）

| Skill | toolkit → agentic | agentic → toolkit |
|-------|-------------------|-------------------|
| vcd-pass0-consultation | 上書き | なし |
| questionnaire-batch-analysis | 上書き（既一致） | なし |
| vcd-bayesian-evidence-analysis | 上書き（既一致） | fixtures + test のみ |
| vcd-categorical-analysis | 上書き（v3.1） | なし（verify/report は toolkit 既存） |
| vcd-categorical-reporting | 上書き（deprecated） | なし |

## diff -rq（実施時点）

```
## vcd-pass0-consultation
## vcd-categorical-analysis
Files .agent/skills/vcd-categorical-analysis/references/workflow.md and .../agentic-evidence-analysis/.../workflow.md differ
Files .agent/skills/vcd-categorical-analysis/SKILL.md and .../SKILL.md differ
Only in .agent/skills/vcd-categorical-analysis/templates: report.Rmd
## vcd-categorical-reporting
Files .agent/skills/vcd-categorical-reporting/SKILL.md and .../SKILL.md differ
## vcd-bayesian-evidence-analysis
## questionnaire-batch-analysis
```

## 実施計画

`docs/superpowers/plans/` の agentic ↔ toolkit 同期計画に従い Phase A（逆取り込み）→ Phase B（rsync）→ Phase C（smoke）を実行。
