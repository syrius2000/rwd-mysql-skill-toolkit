# Survey CSV Preparation

## Required shape

- One row per respondent.
- Columns referenced by `var1`, `var2`, `var3` must exist in source CSV.
- UTF-8 encoding is recommended.

## Missing values

- `na_policy=drop`: rows with NA in analysis vars are removed.
- `na_policy=explicit_level`: NA/empty are converted to `Missing`.

## Likert columns

For `likert_2way` or `likert_3way`, specify `ordered_levels` with `|` separator.

Example:

`とても不満|不満|普通|満足|とても満足`

## Subset expression

`subset_expr` is evaluated by R `subset()`. Keep it simple.

Examples:

- `visit_type == '外来'`
- `response_status == 'complete'`
