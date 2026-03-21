# 序数・リッカート（高度）

メインスキルは **名義カテゴリの頻度・クロス表**が中心。順序を統計的にフル活用する場合は以下を検討し、出力は `./skill_output/vcd_categorical/ordinal/` 等へ。

## R の因子

```r
x <- factor(resp, levels = c("低", "中", "高"), ordered = TRUE)
```

レベル順が**解釈の前提**になるため、必ず明示する。

## 手法の目安

| 目的 | 例 |
|------|-----|
| 単調な関連（2 変数とも順序） | Spearman 相関 |
| 潜在連続を仮定 | polychoric（`psych`, `polycor`） |
| 従属が序数 | `ordinal::clm`, `MASS::polr` 等 |
| 名義の関連 | χ²、Cramer's V、GK tau（非対称に注意） |

## vcd との関係

リッカートを **`ordered` factor** にしても、**セル頻度のモザイク・対数線形**としては有効。ただし順序をモデルで直接扱うなら **序数回帰・polychoric** を別枠で検討。

## 参考リンク

- [Measuring associations between non-numeric variables（R-bloggers）](https://www.r-bloggers.com/2012/02/measuring-associations-between-non-numeric-variables/) … Goodman & Kruskal tau。**長文コードの転載は避け**、公式文献と `?` ヘルプを優先。
