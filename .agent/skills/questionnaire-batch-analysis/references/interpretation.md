# Interpretation Guide

## Read order for beginners

1. Check `report.html` summary values (`p_value`, `effect_value`).
2. Open `residual_plot.png` — this is always generated and is the primary visual. Find bars outside `+-1.96`.
   - **dotplot** (small tables, ≤25 cells): Y-axis shows cell labels, X-axis shows residuals. Look for points beyond ±1.96 dashed lines.
   - **heatmap** (large 2-way tables, >25 cells): Rows = var1, Columns = var2, color = residual. Red = positive (over-representation), blue = negative (under-representation). Cell values printed.
   - **facet_heatmap** (large 3-way tables): Same as heatmap but faceted by the 3rd variable.
   - Check `residual_plot_mode` column in `summary.csv` to confirm which format was used.
3. If `mosaic_rendered` / `assoc_rendered` are TRUE in `summary.csv`, confirm patterns in `mosaic_plot.png` and `assoc_plot.png`. When these are FALSE (auto-skipped due to high dimensionality or long labels), rely on the residual plot and table.
4. Use `summary.csv` to compare across many questions.

## Residual plot meaning

- Positive residual: observed count is larger than model expectation.
- Negative residual: observed count is smaller than model expectation.
- Large absolute residual means stronger model mismatch for that cell.

## Practical tips

- If `p_value` is small but `effect_value` is tiny, practical impact may be weak.
- In 3-way analyses, review subgroup patterns before making conclusions.
- Always report top residual cells with plain language labels.
