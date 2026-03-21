# R スニペット（断片）

全文テンプレは `templates/` を参照。ここは**短い断片**のみ。

## 2-way 表と検定

```r
tab <- xtabs(~ A + B, data = df)
chisq.test(tab)
```

## Pearson 残差行列（`chisq.test` と一致）

```r
ct <- chisq.test(tab)
ct$residuals
```

## 3-way の層別 2-way

```r
tab3 <- xtabs(~ A + B + C, data = df)
ftable(tab3)
```

## モザイク → assoc

```r
vcd::mosaic(tab, shade = TRUE)
vcd::assoc(tab, residuals_type = "Pearson", shade = TRUE)
```

`assoc` の `shade = TRUE` は**独立性モデルからの残差**に基づく着色（`?vcd::assoc` の例と同じ）。

## 期待度数が小さいとき

`chisq.test` が警告することがある。**解釈は慎重に**（必要なら Fisher の正確検定・模擬 `simulate.p.value`・集約の見直し）。
