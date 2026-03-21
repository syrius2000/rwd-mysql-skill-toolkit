# report.Rmd の構成（抜粋）

正本は **`templates/report.Rmd`**。ここではチャンクの意図のみ。

1. **YAML** … `output: html_document`（既定）。`params`: `data_path`, `builtin_dataset`, `vars`, `output_dir`, `residual_table_pkg`。
2. **setup** … `dir.create(output_dir)`、`pacman::p_load` または `library()`、パッケージ未導入時はエラーで止まる想定。
3. **validate** … `vars` の長さ 1〜3、重複なし、列存在、**全 NA 列は `stop`**。非因子列は **`factor()` に変換**（警告付き）。
4. **data** … `data_path` が空なら組み込みデータ（既定 `Titanic`）、あれば `read.csv` 等。
5. **table** … `xtabs` でクロス表。
6. **chisq** … `chisq.test`。期待度数が小さい場合の注意は本文 1 行＋ `r-snippets.md`。
7. **plot** … `mosaic` / `assoc` を PNG で `output_dir` へ。
8. **residual table** … `gt` または `kableExtra`（`residual_table_pkg`）。
9. **glm** … 2-way は `A*B`、3-way は `m0/m1/m2` + `anova`（`glm-gnm-goodness.md` と同じ階層）。

PDF を出す場合は **`kableExtra`** と TeX 環境を用意し、`output: pdf_document` を検討。
