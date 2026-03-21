---
作成: 2026-03-20
作成者: Cursor Agent（ユーザー依頼に基づくプラン）
更新: 2026-03-20 — 実装完了（vcd-categorical-analysis スキル・tests スモーク） / 2026-03-21 — 推奨レビュー反映 / QA 観点追記
name: Artifact_002
overview: create-skill に沿い、VCD（Friendly）ベースのカテゴリカル・アンケート分析（最大3-way）用スキルを追加する。可視化はモザイク主・assoc 補、Pearson 残差表は**既定 gt**（PDF は kableExtra 切替）。glm/gnm・序数は references。templates に pacman 案・params 検証・異常系・dir.create、workflow.md に Mermaid・判断木、SKILL/references の行数目安、**DoD / P0・P1 検証**、PDF（TeX 前提）、Rmd 実質必須依存、スモークの警告方針、Titanic 中心のテスト。Correlogram はスコープ外。出力は `./skill_output/vcd_categorical/`。
todos:
  - id: name-desc
    content: スキル名（vcd-categorical-analysis 等）と description（第3人称・プラン内候補を既定化可）を確定
    status: completed
  - id: skill-md
    content: SKILL.md に 3-way上限・templates/references役割・依存表・Correlogram除外・mosaic主/assoc補・既定gt・params検証・dir.create・行数目安・関連スキル を記載
    status: completed
  - id: references
    content: references に workflow / r-snippets / glm-gnm-goodness / ordinal-likert-advanced / literature-and-packages / dependencies（pacman・rmarkdown・knitr・R バージョン記録）を追加
    status: completed
  - id: mirror-agent-cursor
    content: .cursor/skills と .agent/skills に同一スキルディレクトリを配置
    status: completed
  - id: verify-tests
    content: DoD を満たす手動検証（P0/P1）と tests/ スモーク（警告方針・Titanic 主・期待度数ケース）
    status: completed
---

# VCD カテゴリカル分析スキル実装プラン（3-way まで）

## 保存場所

- 本プラン: [docs/plans/2026-03-20-vcd-categorical-skill.md](2026-03-20-vcd-categorical-skill.md)
- 改善提案（反映済み）: [docs/plans/2026-03-21-vcd-categorical-skill-recommendations.md](2026-03-21-vcd-categorical-skill-recommendations.md)

## 完了定義（DoD）

実装完了とみなす最低条件（リリース前にすべて満たす）。

- スキル名・`description` が確定し、下記「ディレクトリ配置」どおり `.cursor/skills/` と `.agent/skills/` に**同一内容**が置かれている。
- `SKILL.md` にスコープ（3-way 上限・Correlogram 外・序数は references）、`skill_output`、既定 `gt`、関連スキル（任意1行）が書かれ、**本文リンクは 1 段まで**。
- `templates/analysis.R` と `templates/report.Rmd`（＋ `references/*`）がプラン方針どおり（params・バリデーション・`dependencies.md` との整合）。
- 下記「検証（手動）」の **P0** を実施済み（記録は PR 説明またはチェックボックスで可）。
- 下記「自動テスト」のスモークが追加され、既存 [tests/](../tests/) と整合。

## スキル名・description 候補（プラン段階で提示・承認を早める）

- **スキル名案**: `vcd-categorical-analysis`（推奨）または `categorical-survey-analysis`
- **description 案**（第3人称・トリガー語込み）:
  > アンケート等の名義カテゴリカル変数（最大 3-way）に対し、クロス表・独立性検定・Pearson 残差（色分け表）・mosaic/assoc 可視化・対数線形モデル適合度を R コードまたは R Markdown テンプレとして生成する。出力は `./skill_output/vcd_categorical/`。序数リッカートの扱いは references の高度な分析に誘導する。

## `templates/` と `references/` の役割（重複防止）

| 種別 | 役割 |
|------|------|
| **`templates/`** | ユーザーが**コピーして実行**する `.R` / `.Rmd`。ワークフロー全体・再現用のエントリ。 |
| **`references/`** | エージェント・読者が**参照する** `.md`。解説・文献誘導・個別テクニック（`r-snippets.md` は**短い断片集**に限定し、`templates/analysis.R` の全文複製は避ける）。 |

## パッケージ依存（SKILL または `references/dependencies.md` に表で明記）

| レベル | パッケージ | 用途 |
|--------|------------|------|
| **必須** | `vcd` | mosaic, assoc |
| **必須（いずれか）** | **`gt`（既定）** または `kableExtra` | 残差表の色分け。**既定は `gt`**（HTML・可読性・保守）。PDF 主目的は `kableExtra` を `params$residual_table_pkg` で選択可（検証節参照）。 |
| **実質必須（Rmd 利用時）** | `rmarkdown`, `knitr` | `templates/report.Rmd` のレンダリング。`dependencies.md` に **Rmd を使う場合は必須**と明記し、`analysis.R` のみ利用時は不要と区別。 |
| **推奨（テンプレ）** | `pacman` | `templates/*.R` / `report.Rmd` 冒頭で `pacman::p_load()` による一括ロード案（**自動 install** はオフライン環境では使わない旨を `dependencies.md` に注記）。 |
| **推奨** | `vcdExtra` | 補助データ・拡張例・vignette 補足 |
| **オプション** | `gnm` | 対称性・非線形対数線形など |
| **オプション（序数）** | `psych`, `polycor`, `ordinal` 等 | polychoric, clm 等（`ordinal-likert-advanced.md` 側） |

## スコープ（確定）

- **表の次元**: **3-way まで**（`xtabs(~ A + B + C, data)` 等）。**4-way 以上は対象外**と SKILL に明記。
- **実行方針**: **R コード・Rmd テンプレの生成が主**（エージェントが R を必ず実行しない前提）。ユーザーが RStudio / `Rscript` / `rmarkdown::render()` で実行。
- **主用途**: アンケートのカテゴリ比率、クロス表、独立性からの乖離（**Pearson 残差**の解釈）。

## 分析例・成果物の保存先

- スキル付属の **分析例・テンプレ実行の出力**（中間表、PNG/PDF、レンダー済み HTML 等）は、プロジェクトルートの **`./skill_output/`** 配下に保存する旨を SKILL・Rmd・テンプレ先頭に明記する（本リポジトリの他スキルと同様の慣習）。
- サブディレクトリ例: `skill_output/vcd_categorical/`（スキル名に合わせて固定）。

## モデルによる強化（glm / gnm / 対数線形）

- **目的**: モザイク・Assoc の「視覚的残差」に加え、**一般化線形モデル（GLM）** および必要に応じて **一般化非線形モデル（gnm）** で、**適合度（deviance / Pearson 残差 / 期待度数との比較）** を数値・図で補強する。
- **2-way**: 主に **`glm(count ~ A * B, family = poisson)`**（対数線形＝独立・交互作用の有無をパラメータで表現）と **`chisq.test` / モザイク** の結果を併記。
- **3-way（重点）**: **対数線形モデル**（Poisson + カテゴリ因子の交互作用）を用い、`family = poisson` の GLM で **(A,B,C) の主効果・2因子交互作用・3因子交互作用** のどこまで入れるかをモデル比較（anova / AIC 等、スキルにテンプレ化）。**複雑な交互作用**や **対称性** などが必要なら **`gnm` パッケージ** を参照節に追加（実装はテンプレ＋短い説明に留め、依存パッケージは README または references に列挙）。
- **3-way 対数線形のモデル階層（テンプレに明示）**: エージェントが迷わないよう、比較するモデル集合を **固定スニペット**として `references/glm-gnm-goodness.md` および `templates/report.Rmd` に含める。

```r
# 典型的な 3-way 対数線形モデル階層（参考。count はセル度数、A,B,C は因子）
m0 <- glm(count ~ A + B + C, family = poisson)           # 主効果のみ（相互独立）
m1 <- glm(count ~ (A + B + C)^2, family = poisson)       # 全 2 因子交互作用まで
m2 <- glm(count ~ A * B * C, family = poisson)           # 飽和（3 因子交互作用含む）
anova(m0, m1, m2, test = "Chisq")
```

- **適合度の可視化**（テンプレに含める）:
  - **期待度数 vs 観測**（棒・ドット）や **Pearson / deviance 残差のプロット**（`plot(residuals(model, type="pearson"))` 等）。
  - **`vcd` の `mosaic` / `assoc` と `glm` 残差の解釈を対応づける**一文を report-template に入れる。

## 可視化（主と補）

| 役割 | 関数（vcd） | 目的 |
|------|-------------|------|
| **主** | `vcd::mosaic`（`shade = TRUE` 等、strucplot 系） | カテゴリ構成と、独立性モデルからの乖離をタイルで表現（Friendly / Meyer 系の標準的な読み方）。 |
| **補** | `vcd::assoc`（`residuals_type = "Pearson"`） | セルごとの Pearson 残差の符号・大きさを棒（矩形の高さ）で補足。 |

- 3-way: **マージン 2-way**（`margin.table`）と **層別 2-way**（第3因子で分割）のどちらでも、**同じく mosaic → assoc の順**でテンプレ化する。

## Correlogram（相関図）— **本スキルのスコープ外**

- **方針**: **correlogram（連続変数の相関行列ヒートマップ等）をスキル本体の手順に含めない**。スコープクリープを防ぐ。
- **代替の誘導のみ**: 多数項目のざっくりスクリーニングが必要な読者向けに、`references/literature-and-packages.md` に **pairwise Cramer's V ヒートマップ**の**参考リンクまたは短い注**のみ記載（実装テンプレは置かない）。

## 高度な分析（序数・リッカート尺度）

**対象**: レベルに順序はあるがコードが数値とは限らない変数（例: 「強く同意する」…「強く同意しない」）。**名義カテゴリとの扱いを分ける**。

### 位置づけ（SKILL 構成）

- メイン本文（`SKILL.md`）では **1 段落＋ `references/ordinal-likert-advanced.md` へのリンク**に留め、詳細・コードスニペット・注意書きは **references に progressive disclosure**。
- 分析例・図表の保存先は他パートと同様 **`./skill_output/`**（例: `skill_output/vcd_categorical/ordinal/`）。

### 参照文献・外部解説（プランで固定）

- [Measuring associations between non-numeric variables（R-bloggers, 2012）](https://www.r-bloggers.com/2012/02/measuring-associations-between-non-numeric-variables/): **名義（順序なし）カテゴリ**の関連として **Goodman & Kruskal の tau** を紹介。**x から y をどれだけ予測できるか**に基づくため **非対称**（\(a(x,y) \neq a(y,x)\) が一般）。連続変数同士の相関とは別物。欠損をレベルとして扱える点の言及あり。
- 実務メモ: 同記事の **GKtau 実装例**は教育用として references に転載可否を判断（著作権のため **アルゴリズム説明＋ユーザーが `?` で辿れる公式文献**を優先し、長いコードの丸写しは避ける）。

### 序数（リッカート）でよく使う選択肢（references に展開）

| 目的 | 手法の例 | メモ |
|------|----------|------|
| 2 変数がともに序数 | **Spearman 順位相関**（`cor(..., method="spearman")`） | 数値化した順位に依存。解釈は「単調な関係」。 |
| 潜在連続を仮定した項目間関連 | **Polychoric 相関**（[`psych::polychoric`](https://search.r-project.org/CRAN/refmans/psych/html/tetrachor.html)、[`polycor::polychor`](https://rdrr.io/cran/polycor/man/polychor.html) 等） | Likert の因子分析前処理でよく参照。カテゴリ数が多いと計算負荷・前提の議論あり（[EFA.dimensions POLYCHORIC 等の説明](https://search.r-project.org/CRAN/refmans/EFA.dimensions/html/POLYCHORIC_R.html)）。 |
| 従属変数が序数の回帰 | **累積ロジット / 比例オッズ**（`ordinal::clm`、`MASS::polr`、`rms` 等） | 共変量とリッカートの関係をモデル化。 |
| クロス表の「トレンド」 | **線形×線形関連**（対数線形に線形×線形項を入れる考え方）、**Cochran-Armitage 型**（2×J 表など条件付き） | 3-way 対数線形パートと接続可能なら1節。 |
| 名義ペアの関連（記事と接続） | **Goodman & Kruskal tau**、**Cramer's V**、**χ²** | 順序を捨てるか、順序を `ordered factor` として別枠で扱うかを明示。 |

### vcd / 対数線形パートとの接続

- **モザイク・Assoc・対数線形（Poisson GLM）** は、リッカートを **`ordered` factor** にしても **カテゴリセル頻度の分析**として有効。ただし「順序を統計的にフル活用」するなら **序数回帰や polychoric** を別枠で推奨、と references に書き分ける。
- **3-way**: 名義3因子の対数線形に加え、序数を含む場合は **どの変数を順序としてモデル化するか**（1つだけ序数従属、など）をテンプレの分岐に含める。

### `references/ordinal-likert-advanced.md` に含める内容（実装時チェックリスト）

- R での **`factor(..., ordered=TRUE)`** とレベル順の明示。
- GK tau（R-bloggers 記事との対応）・Spearman・polychoric の**使い分け**と**誤用しやすい点**（名義を数値コードにして Pearson する等）。
- 出力は **`skill_output/`**、必要なら **Rmd チャンク例**を1本。

## Pearson 残差の「表」を色分けして出す

- **定義**: セル \((i,j)\) の Pearson 残差は \((O_{ij}-E_{ij})/\sqrt{E_{ij}}\)（`chisq.test(tab)$residuals` と一致）。3-way は層ごとに 2-way 表を切って同様に取得。
- **既定パッケージの確定**: **`gt` をデフォルト**（HTML 向け、`params$residual_table_pkg: "gt"`）。理由の例: パイプで読みやすい、HTML 表現がモダン、メンテ状況。**`kableExtra`** は **PDF/LaTeX 主目的**や `gt` が向かない出力のときの代替（`references/` に短く）。
- **PDF との関係**: `gt` の PDF 直出しは制約があるため、**PDF レンダリング検証時は `kableExtra` に切り替え**る（下記「検証（手動）」）。高度な `gt`→PDF は `webshot2` 等を **references のみ**に記載し、スキルテンプレの既定にはしない。
- **出力形式の推奨**:
  - **R Markdown（推奨）**: チャンク内で残差行列を作り、**HTML 向けは `gt`**（`gt::tab_style()` + `gt::cell_fill()` 等）。アクセシビリティ: 極端な色のみに頼らない旨を references に1行。**任意**: 色に加え **太字・符号・脚注** 等でセルを区別できるスニペットを `references/` に短く（印刷・色覚多様性向け）。
  - **PDF 向け**: `kableExtra` + `kable()` + `cell_spec(background = ...)` を **`params$residual_table_pkg == "kableExtra"`** の分岐で。
  - **コンソールのみ**: `crayon` / `cli` は再現性が低いため、プレーン R は `print(round(residuals, 2))` に加え、任意で HTML 書き出しスニペット。

- SKILL には「**色分けの既定は `gt`（HTML）。PDF は `kableExtra` を params で**」と1行で明記する。

## 配布物（スキル内リソース）

- `templates/analysis.R`: 最小の **純 R** パイプライン（`xtabs` → `chisq.test` → 残差行列 → `mosaic` / `assoc` → **出力は `./skill_output/vcd_categorical/`**）。`references/r-snippets.md` は**全文の複製を避け**、断片のみ。
- **エラーハンドリング / ロード**: テンプレ冒頭で **`pacman::p_load(vcd, gt, ...)`** による一括ロード案を載せる（**未インストール時の自動 install**）。オフライン・企業環境では使わない旨を `dependencies.md` に注記し、代替として `library()` + 手動 `install.packages()` を併記。
- **`output_dir` の作成**: 最初の `setup` チャンク（または `analysis.R` 先頭）で  
  `dir.create(params$output_dir, recursive = TRUE, showWarnings = FALSE)` を実行する方針を明記（`analysis.R` も同様）。
- `templates/report.Rmd`: **推奨の再現用**。YAML で `html_document` または `pdf_document`。分析設定は **`params` で外出し**し、再利用性を高める（例）。

```yaml
params:
  data_path: "data.csv"
  vars: ["Q1", "Q2", "Q3"]   # 最大 3 変数（3-way）
  output_dir: "./skill_output/vcd_categorical/"
  residual_table_pkg: "gt"   # 既定。PDF 主なら "kableExtra"
```

- **`params$vars` のバリデーション**（setup チャンク先頭）: `stopifnot(length(params$vars) >= 1, length(params$vars) <= 3)`。データ読み込み後は `all(params$vars %in% names(dat))` 等で列存在を確認（なければ `stop()` で明示）。**重複列名**は `anyDuplicated(params$vars)` で `stop()`。**因子でない列**は `factor()` に変換するか `warning()` してから進める方針をテンプレに1行（実装時にどちらか固定）。**対象列がすべて NA** のときは `stop()` または解析スキップを明示。
- チャンク: データ読み込みプレースホルダ、`mosaic` / `assoc`、**Pearson 残差表の色付け**、**glm/gnm（3-way は対数線形）の適合度・残差プロット**（`params$residual_table_pkg` で分岐）。
- `references/glm-gnm-goodness.md`（仮名）: Poisson 対数線形の式の例、`anova` によるモデル比較、gnm を使う場合の注意（任意）。
- `references/ordinal-likert-advanced.md`: 序数・リッカートの高度な分析（本節の詳細）。
- `references/literature-and-packages.md`: **外部への誘導のみを集約**（下記「references に誘導する情報」）。`SKILL.md` からはこの1ファイルへリンクし、深い文献はここから辿る。Correlogram はスコープ外；Cramer's V 参考のみ。
- `references/dependencies.md`: 上記「パッケージ依存」表をそのまま保守（SKILL からリンク）。

## 前提・関連スキル（任意・境界の明確化）

- **データ取得・前処理**は本スキルの主対象外。DB からの件数・スキーマ確認が必要なら、本リポジトリの **`mysql-table-cardinality`** スキル（`.cursor/skills/mysql-table-cardinality/`）を **「先にデータを揃える」** 文脈で `SKILL.md` に1行言及してよい。
- ユーザー環境の **個人スキル**（例: R ワークフロー全般、グローバルに `r-robust-workflow` 等をお持ちの場合）があるときは、**データ取得〜前処理**の役割分担を `references/workflow.md` に記載。

## `references/workflow.md` に含める内容（実装時チェックリスト）

- **典型的な使用フロー**: Mermaid の **シーケンス図 1 本**（ユーザー → テンプレ選択 → 出力 → `skill_output`）。
- **判断木**: 2-way vs 3-way、名義 vs 序数（序数は `ordinal-likert-advanced.md`）で **どのテンプレ・どの節を読むか**。
- **関連スキル**: `mysql-table-cardinality`、個人の R ワークフロースキル（例: `r-robust-workflow`）との **連携ポイント**を短く。

## ドキュメント行数の目安（create-skill の「500行」に加えて分散上限）

- **`SKILL.md` 本体**: **200 行以内**を目安（エージェントコンテキストの負荷軽減）。詳細は references へ。
- **`references/*.md` 各ファイル**: **300 行以内**を目安（必要ならファイルを分割）。

## references に誘導する情報（実装時に `literature-and-packages.md` 等へ記載）

スキル本文に長文を置かず、**読者を一次情報へ誘導**する。最低限、次を **リンク付きで**整理する。

| 区分 | 誘導先 | メモ |
|------|--------|------|
| Web 解説（先の Blog） | [Measuring associations between non-numeric variables（R-bloggers, 2012）](https://www.r-bloggers.com/2012/02/measuring-associations-between-non-numeric-variables/) | Goodman & Kruskal tau 等。著作権に配慮し**全文転載はしない**。 |
| R パッケージ | **[vcd](https://cran.r-project.org/package=vcd)** | モザイク・assoc・strucplot。CRAN の Description / vignette（例: `vignette("strucplot", package = "vcd")`）への誘導。 |
| R パッケージ（拡張） | **[vcdExtra](https://cran.r-project.org/package=vcdExtra)** | 補助データ・追加例・拡張トピック。スキルで 3-way や glm 接続を深めるときの参照先。 |
| 教科書 | **Alan Agresti** | *Categorical Data Analysis*（版は実装時に最新版を明記）など、**対数線形・カテゴリカルモデル**の理論的裏付け。 |
| 教科書・可視化 | **Michael Friendly** | *Visualizing Categorical Data* 等、**Friendly / Meyer 系**の可視化（VCD の文脈）と対応づけて誘導。 |

- `SKILL.md` の「追加リソース」セクションは **上表へのポインタ1つ**＋必要なら **vcd の `?mosaic` / `?assoc`** 程度に抑える。

## ディレクトリ配置（プロジェクトスキル）

- [.cursor/skills/&lt;skill-name&gt;/](../.cursor/skills/) と [.agent/skills/&lt;skill-name&gt;/](../.agent/skills/) に **同一内容**（既存運用に合わせる）。
- 構成例:
  - `SKILL.md`
  - `references/workflow.md`
  - `references/r-snippets.md`
  - `references/report-template.md`（`templates/report.Rmd` の構成・チャンク意図の**説明抜粋**。本文の重複は避け、Rmd を正とする）
  - `references/ordinal-likert-advanced.md`
  - `references/literature-and-packages.md`
  - `references/dependencies.md`
  - `templates/analysis.R`
  - `templates/report.Rmd`

## 実装手順（承認後）

1. スキル名・`description`（本プランの候補を流用可）を確定。
2. `SKILL.md` に上記スコープ・templates/references 役割・依存表へのリンク・**Correlogram スコープ外**・可視化の主補・**残差表は既定 `gt`**・**skill_output 保存**・**glm/gnm（3-way は対数線形・階層スニペット）**・**序数リッカートは `ordinal-likert-advanced.md` 参照**・関連スキル1行を記載（**SKILL 本体は 200 行目安、全体は 500 行未満**）。
3. `templates/` と `references/` を埋める（**`literature-and-packages.md`** に Blog・vcd・vcdExtra・Agresti・Friendly 誘導、**Cramer's V 参考のみ**。**`dependencies.md`** にパッケージ表＋**Rmd 利用時の `rmarkdown`/`knitr`**）。
4. `.cursor` / `.agent` 両方へミラー。
5. 上記「完了定義（DoD）」「検証（手動）」P0・「自動テスト」を満たす。

## 検証・テスト用データ（ユーザーフレンドリに統一）

**方針**: 外部 CSV に依存せず、**R 組み込みデータ**だけで「手動の動作確認」と **`tests/` の自動スモーク**を揃える。ドキュメント・`templates/` のデフォルト例も同じデータ名にすると迷わない。

### 主例（推奨の顔つき）

- **`Titanic`（`datasets::Titanic`）**: 有名で説明しやすい。**2-way**（例: `Class` × `Survived` のマージン表）を主デモにする。乗客データとしてユーザーに直感的。

### ほかの良い組み込み例（用途別）

| データ | 包 | 用途の目安 |
|--------|-----|------------|
| **`HairEyeColor`** | `datasets` | **3-way** クロス表・モザイク・対数線形の定番。 |
| **`UCBAdmissions`** | `datasets` | バークレー入試（偏りの例）。**2-way / 層別**の説明に強い。 |
| **`Arthritis`** | `vcd` | **序数（Improved）**付き。リッカート高度パートの例に。 |
| **`Alligator`** 等 | `vcd` / `vcdExtra` | 補助例（`vcdExtra` 推奨パッケージと整合）。 |

実装時は **`templates/report.Rmd` の `params` デフォルト**を「`Titanic` 由来の表を `data()` で読む」か、スキル内に最小の再現用チャンクを置く形にするとよい。

## 検証（手動）

**優先度**: **P0** はリリース必須、**P1** は環境が揃う場合・時間があるとき。

**環境前提（切り分け用）**

- **R**: 実装時点の安定版を記録（README または `dependencies.md` に1行）。CI でテストする場合は **ワークフローでバージョンを固定**するか、ローカル検証のみと明記。
- **HTML レンダリング**: `rmarkdown` / `knitr` が利用可能であること（上記「パッケージ依存」の「実質必須（Rmd 利用時）」）。
- **PDF（P1）**: `pdf_document` は **TinyTeX または TeX ディストリビューション**が必要なことが多い。失敗時は「TeX 未導入」と切り分け、P0 の完了には含めない。

| 優先度 | 内容 |
|--------|------|
| **P0** | `Titanic` で `xtabs` → `chisq.test` → 残差 → `mosaic` / `assoc` → **HTML** で色付き残差表（`gt` 既定）まで通る。 |
| **P0** | `HairEyeColor` で `report.Rmd`（`params` 使用）が **html_document** でレンダーできる。 |
| **P0** | 小さい期待度数で **`chisq.test` の警告**が出るケースを1つ含め、テンプレまたは references に「解釈注意」1行。 |
| **P0** | `SKILL.md` のリンクは 1 段まで（目視）。 |
| **P1** | `UCBAdmissions` で層別または 2-way が通る。 |
| **P1** | `vcd::Arthritis` で高度パートの1チャンクが動く。 |
| **P1** | `params$residual_table_pkg: "kableExtra"` に切り替え、`rmarkdown::render(..., output_format = "pdf_document")` が **TeX あり環境で**通る（`gt` 単体の PDF 制約は references の前提）。 |

## リリース QA（任意）

- 外部 URL（Blog・CRAN・rdrr 等）の **リンク生存確認**をリリース前に1パス（自動化は不要）。

## 自動テスト（`tests/` にも利用できる）

- **同じ組み込みデータ**で **`testthat`**（または既存のテストランナー）による **スモークテスト**を置く。
  - 例: `Titanic` の 2-way 表で `chisq.test` が完走する、`residuals` の次元が表と一致する、`expect_true(nrow(res) == ...)` 等。
  - **3-way** は `HairEyeColor` で `xtabs` の次元・`glm(count ~ ...)` が収束する程度の軽いチェック（実行時間に注意）。
- **警告の扱い**: 期待度数が小さいケースなどで `chisq.test` が**警告**する場合は、(a) **警告を許容**し結果オブジェクトのみ検証する、または (b) `suppressWarnings()` で包んだ上で**期待する警告クラスを `expect_warning()`** する、のいずれかに**テストファイル内で統一**（フラッキー回避のため、無警告を必須にしない）。
- **PDF / レンダリング**: CI に TeX を入れない場合、`rmarkdown::render` の PDF スモークは **スキップ**（`testthat::skip_if_not` 等）し、P0 はベース R＋数値検証中心に留める。
- メリット: CI で外部ファイル不要、ユーザーが README の手順をコピーしたときと **同じデータ名**で再現できる。
- 既存の [tests/](../tests/) 構成（ファイル命名・`testthat` の有無）に合わせて追加する。
