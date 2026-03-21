# 文献・パッケージ誘導

SKILL 本文は短く保ち、**一次情報へ誘導**する。

| 区分 | 先 |
|------|-----|
| Web | [R-bloggers: non-numeric associations](https://www.r-bloggers.com/2012/02/measuring-associations-between-non-numeric-variables/) |
| CRAN | [vcd](https://cran.r-project.org/package=vcd), [vcdExtra](https://cran.r-project.org/package=vcdExtra) |
| 教科書 | Alan Agresti — *Categorical Data Analysis*（版は最新を確認） |
| 可視化 | Michael Friendly — *Visualizing Categorical Data* 等 |

## vcd

`vignette("strucplot", package = "vcd")` 等で strucplot 系の読み方を確認。

## gt と PDF

`gt` の PDF 直出しには制約がある。**HTML 既定**、PDF が主目的なら **`kableExtra` 分岐**（`params$residual_table_pkg`）。`gt` を画像化して PDF に埋め込む流れは **`webshot2`** 等が必要になることがあり、**本スキルの既定テンプレには含めない**（必要なら各自で追加）。

## 多数項目のスクリーニング（参考のみ）

**Correlogram は本スキル対象外**。名義項目のざっくり関連把握には **pairwise Cramer's V** のヒートマップ等を**外部記事・自前コード**で検討（テンプレは置かない）。

## アクセシビリティ

残差表の色分けは **極端な色のみに依存しない**（コントラスト・凡例）。印刷・色覚多様性のため **数値・太字・符号**で補足できるとよい。
