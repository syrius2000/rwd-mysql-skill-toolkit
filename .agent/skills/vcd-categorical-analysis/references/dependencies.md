# 依存パッケージ

検証時の **R バージョン**は README または本ファイル先頭に 1 行記録する（例: `R 4.4.x`）。CI で固定する場合はワークフロー側で指定。

| レベル | パッケージ | 用途 |
|--------|------------|------|
| **必須** | `vcd` | mosaic, assoc |
| **必須（いずれか）** | **`gt`（既定）** または `kableExtra` | 残差表の色分け。HTML は `gt`、PDF 主は `kableExtra`（`params$residual_table_pkg`）。 |
| **必須** | `ggplot2` | 残差プロットの生成用 |
| **必須（Rmd）** | `jsonlite` | 3-way 層別 Cramér V の JSON 出力（`report.Rmd`） |
| **実質必須（Rmd 利用時）** | `rmarkdown`, `knitr` | `templates/report.Rmd` のレンダリング。**純 R のみ**なら不要。 |
| **推奨（テンプレ）** | `pacman` | `pacman::p_load()` で一括ロード。**オフライン・企業環境では自動 install を使わず**、`library()` + 手動 `install.packages()` に切り替え。 |
| **推奨** | `vcdExtra` | 補助データ・拡張例 |
| **オプション** | `gnm` | 対称性・非線形対数線形 |
| **オプション（序数）** | `psych`, `polycor`, `ordinal` 等 | `ordinal-likert-advanced.md` |

## PDF レンダリング

`pdf_document` は **TinyTeX または TeX** が必要なことが多い。失敗時は TeX 未導入を疑う。`gt` の PDF 直出しは制約があるため、検証では **`kableExtra` 分岐**を使う（`literature-and-packages.md` の `webshot2` 注参照）。
