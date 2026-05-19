# SQL Assets

This directory stores reusable SQL created while using the DB exploration and query-support skills.

## Directory Policy

| Directory | Use |
|---|---|
| `drafts/` | Work-in-progress SQL. Queries here may be incomplete or unvalidated. |
| `validated/` | SQL that has passed count, NULL, duplicate, date-range, and category checks. |
| `examples/` | Teaching examples and reusable patterns for junior engineers. |

## Standard Files Per Topic

Each topic should use this structure:

```text
sql/drafts/<topic>/
  main_query.sql
  validation_query.sql
  query_note.md
```

Move a topic from `drafts/` to `validated/` only after the user confirms that the validation results match the intended grain and analysis purpose.

## Required Notes

`query_note.md` records:

- Natural-language goal
- Dataset grain
- Main ID
- Date policy
- JOIN rationale
- Validation results
- Remaining risks
- Recommended next analysis skill
