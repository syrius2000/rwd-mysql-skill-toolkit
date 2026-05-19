# questionnaire-batch-analysis margin.table namespace correction

## 背景

`tests/test_questionnaire_batch_smoke.R` の 3-way 設問 `q03_waiting_dept_time` で、以下のエラーにより `report.html` と `residual_plot.png` が生成されなかった。

```text
'margin.table' is not an exported object from 'namespace:stats'
```

## 根拠

R の `margin.table` は `base` パッケージの関数として提供されている。公式 R documentation では `marginSums` / `margin.table` が `base` の table margin 関数として説明されている。

- R manual: <https://stat.ethz.ch/R-manual/R-devel/RHOME/library/base/html/marginSums.html>

## 対処

このリポジトリでは、以下を `.agent` と `.cursor` の両方で修正した。

```r
stats::margin.table(tab, c(1L, 2L))
```

を

```r
base::margin.table(tab, c(1L, 2L))
```

へ変更した。

また、未修飾の `margin.table(...)` も、namespace を明示して `base::margin.table(...)` に変更した。

同じ smoke test で `stats::replace(...)` も `stats` から export されていないことが確認されたため、R の実行環境で `replace` が `base` に属することを確認し、`base::replace(...)` に変更した。`stats::complete.cases(...)` は `stats` に属することを確認したため維持した。

## 参照ディレクトリへの注意

以下の参照専用ディレクトリにも同種の記述がある場合は、各ディレクトリを別作業として同じ修正を適用する必要がある。この作業では参照ディレクトリは変更していない。

- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_VSCODE/`
- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_RAW/`
- `/Users/myamaguchi/Programing/OSX_IDE_Skill_management_Gemini/`

## 検証

この修正後に以下を実行する。

```bash
Rscript tests/test_questionnaire_batch_smoke.R
```
