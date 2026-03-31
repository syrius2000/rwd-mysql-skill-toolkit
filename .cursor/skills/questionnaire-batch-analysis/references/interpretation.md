# Interpretation Guide

## Read order for beginners

1. Check `report.html` summary values (`p_value`, `effect_value`).
2. Open `residual_plot.png` and find bars outside `+-1.96`.
3. Confirm same pattern in `mosaic_plot.png` and `assoc_plot.png`.
4. Use `summary.csv` to compare across many questions.

## Residual plot meaning

- Positive residual: observed count is larger than model expectation.
- Negative residual: observed count is smaller than model expectation.
- Large absolute residual means stronger model mismatch for that cell.

## Practical tips

- If `p_value` is small but `effect_value` is tiny, practical impact may be weak.
- In 3-way analyses, review subgroup patterns before making conclusions.
- Always report top residual cells with plain language labels.
