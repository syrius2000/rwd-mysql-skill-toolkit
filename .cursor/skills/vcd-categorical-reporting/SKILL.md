---
name: vcd-categorical-reporting
description: "【非推奨】AI考察・レポートは vcd-categorical-analysis の Step 2–3 に統合済み。後方互換の参照用。"
license: MIT
metadata:
  author: vcd-categorical-reporting-skill
  version: "3.0-deprecated"
---

# 非推奨（Deprecated）

**`vcd-categorical-reporting` は `vcd-categorical-analysis` v3.0 に統合されました。**

新規作業では **`vcd-categorical-analysis` の必須3ステップ** を使用してください。

| 旧 reporting | 新 analysis |
| :--- | :--- |
| Pass 1: data_profile → render_config | Step 1: `analysis.R --render` |
| Pass 2: AI が `vcd_analysis_report.md` | Step 2: `executive_summary.md`（＋任意で `vcd_analysis_report.md`） |
| （別スキル） | Step 3: `dashboard.Rmd`（既定）または `report.Rmd` |

## 参照のみ残すファイル

- `references/report-template.md` … 判断ファースト3章のテンプレート
- `references/evaluation-criteria.md` … AI 判断基準
- `references/interface.md` … 共有契約（analysis 側と同期）

## 配置

- **Cursor**: `.cursor/skills/vcd-categorical-reporting/`
- **Antigravity**: `.agent/skills/vcd-categorical-reporting/`
