# Integrated DB Analysis Skills Merge Message

## Context

This branch changes the repository direction from a generic IDE skill management repository into the parent repository for integrated DB construction, DB exploration, query creation support, and analysis/reporting skills.

The three existing development directories were used as read-only references only:

- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_VSCODE/`
- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_RAW/`
- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_Gemini/`

They were not modified.

## Summary

- Added `mysql-create-query-support` to help junior engineers turn natural-language analysis goals into SQL, validation SQL, and query notes.
- Added root-level `sql/` asset policy with `drafts/`, `validated/`, and `examples/`.
- Reframed README/AGENTS around DB construction, broad exploration/query creation, and analysis/reporting.
- Linked existing DB construction/exploration skills to `mysql-create-query-support`.
- Brought forward compatible Gemini reference skills: `vcd-categorical-reporting` and `vcd-bayesian-evidence-analysis`.
- Fixed `questionnaire-batch-analysis` namespace errors by changing base functions from `stats::margin.table` and `stats::replace` to `base::margin.table` and `base::replace`.

## Verification

- `pytest tests/test_mysql_create_query_support_assets.py -q`
- `Rscript tests/test_vcd_categorical_smoke.R`
- `Rscript tests/test_questionnaire_batch_smoke.R`
- `git diff --check`

## Notes For Follow-Up

- Reference directories may need the same `questionnaire-batch-analysis` namespace correction in separate work.
- Root `README.md` now documents the teaching goal: helping junior engineers build RDBMS instances from local data, explore schema/data, create desired SQL, and hand validated datasets to analysis skills.
