# GLM / 対数線形と適合度

## 2-way（例）

セル度数 `count` と因子 `A`, `B` があるとき:

```r
m_ind <- glm(count ~ A + B, family = poisson)
m_sat <- glm(count ~ A * B, family = poisson)
anova(m_ind, m_sat, test = "Chisq")
```

## 3-way 階層（固定スニペット）

`count` はセル度数、`A`, `B`, `C` は因子（`as.data.frame(table)` 由来の `Freq` を `count` にリネームしてもよい）。

```r
m0 <- glm(count ~ A + B + C, family = poisson)
m1 <- glm(count ~ (A + B + C)^2, family = poisson)
m2 <- glm(count ~ A * B * C, family = poisson)
anova(m0, m1, m2, test = "Chisq")
```

## 適合度の確認

- モデルオブジェクトの **deviance / Pearson 残差**、`plot(residuals(fit, type = "pearson"))` 等。
- **vcd** の mosaic/assoc で見た「セル乖離」と、GLM の当てはまりを**併記して解釈**する。

## gnm（オプション）

対称性・準対称性・非線形項などは **`gnm`** パッケージのドキュメントを参照。本スキルの既定テンプレは **標準 GLM** に留める。
