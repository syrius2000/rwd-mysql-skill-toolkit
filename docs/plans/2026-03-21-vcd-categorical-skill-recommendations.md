created: 2026-03-21 07:31 (JST)
author: AI Agent (Gemini 1.5 Pro)

**反映状況**: 第1次（§1–8）および第2次（§9–15）の推奨は [2026-03-20-vcd-categorical-skill.md](2026-03-20-vcd-categorical-skill.md) に取り込み済み（2026-03-21 更新）。

# VCD カテゴリカル分析スキル 実装プラン改善提案

[docs/plans/2026-03-20-vcd-categorical-skill.md](2026-03-20-vcd-categorical-skill.md) に対する改善提案です。全体として統計的な設計判断は非常に筋が良いですが、実装時にエージェントが迷わないための境界の明確化と、検証の網羅性を高めるための推奨事項をまとめます。

## 推奨事項

### 1. スキル名の確定と description の提示

プラン段階で候補を出しておくことで承認フローをスムーズにします。

* **スキル名案**: `vcd-categorical-analysis` または `categorical-survey-analysis`
* **description 案**:
    > 「アンケート等の名義カテゴリカル変数（最大 3-way）に対し、クロス表・独立性検定・Pearson 残差（色分け表）・mosaic/assoc 可視化・対数線形モデル適合度を R コード/Rmd テンプレとして生成する。出力は `./skill_output/vcd_categorical/` に保存。」

### 2. `templates/` と `references/` の役割の明確化

`references/r-snippets.md` と `templates/analysis.R` の重複を避けるため、役割を明確に定義します。

* **`templates/`**: ユーザーがコピーして実行するファイル (`.R`, `.Rmd`)。ワークフロー全体を提供。
* **`references/`**: エージェントが参照するガイド・解説 (`.md`)。`r-snippets.md` は個別テクニック集として位置づける。

### 3. パッケージ依存の明示

依存パッケージが散在しているため、SKILL.md か references に必須 / 推奨 / オプションのレベル分けをした一覧表を追加します。

| レベル | パッケージ | 用途 |
| :--- | :--- | :--- |
| **必須** | `vcd` | mosaic, assoc |
| **必須** | `gt` または `kableExtra` | 残差表の色分け |
| **推奨** | `vcdExtra` | 補助データ・拡張例 |
| **オプション** | `gnm` | 非線形対称モデル等 |
| **オプション（序数）**| `psych`, `polycor`, `ordinal` | polychoric, clm 等 |

### 4. `report.Rmd` の YAML パラメータ化

分析設定を `params` として外出しにすることで、Rmd テンプレートの再利用性を高めます。プランの「配布物」節にこの設計方針を追記推奨。

```yaml
params:
  data_path: "data.csv"
  vars: ["Q1", "Q2"]       # 最大3つ
  output_dir: "./skill_output/vcd_categorical/"
  residual_table_pkg: "gt"  # or "kableExtra"
```

### 5. 3-way 対数線形のモデル比較テンプレの粒度明確化

`anova / AIC` で比較するモデルの階層が非自明にならないよう、テンプレに含めるモデルセットを明示します。

```r
# 典型的な 3-way 対数線形モデル階層（参考）
m0 <- glm(count ~ A + B + C, family = poisson)              # 主効果のみ
m1 <- glm(count ~ (A + B + C)^2, family = poisson)          # 全2因子交互作用
m2 <- glm(count ~ A * B * C, family = poisson)              # 飽和（3因子交互作用含む）
anova(m0, m1, m2, test = "Chisq")
```

### 6. 検証パターンの追加・強化

`HairEyeColor`（3-way）のみの検証に加えて、以下の検証パターンを追加します。

* **2-way の検証**: `Titanic` の2変数マージンや `UCBAdmissions` の 2-way slice。
* **警告ロジック**: 期待度数 < 5 のセルがある場合の警告が出力されることの確認。
* **自動テスト (CI 向け案)**: `testthat` で最低限 `xtabs` → 残差行列の次元チェックを行うスモークテストを `tests/` に配置（既存 `tests/` ディレクトリとの整合考慮）。

### 7. Correlogram のスコープ除外の明記

現状「任意」となっている Correlogram について、プランとして **「本スキルのスコープ外。必要時は `references/literature-and-packages.md` に Cramer's V ヒートマップの参考リンクのみ記載」** と明確に切り捨てることで、スコープクリープを防ぎます。

### 8. 既存スキル（MySQL等）との連携の明示

RWD 分析のコンテキストにおける前提や連携について、「前提・関連スキル」節を追加し、データ取得フェーズにおける `mysql-table-cardinality` や グローバルスキル `r-robust-workflow` との連携について言及します。

---

## 第2次レビュー（2026-03-21 07:52 JST）

**対象**: 第1ラウンドの推奨事項反映後の [2026-03-20-vcd-categorical-skill.md](2026-03-20-vcd-categorical-skill.md)（240行版）。
第1ラウンドの8項目はすべて的確に取り込まれており、プランの品質は高い。以下はさらに踏み込んだ実装品質向上のための提案。

### 9. `gt` vs `kableExtra` のデフォルト選定を確定すべき

L50 で「いずれか」、L155 で `params` のデフォルトは `"gt"` としているが、プラン本文では明確に確定していない。

**提案**: **`gt` をデフォルト**に確定（理由: パイプ構文で可読性が高い、HTML 出力がモダン、Posit 社が積極メンテ）。`kableExtra` は `references/` に「PDF/LaTeX 出力が主の場合の代替」として短く言及する。この方針を「Pearson 残差の表」節に1行追加。

### 10. `templates/analysis.R` のエラーハンドリング方針

現在のプランには、テンプレが実行時エラー（パッケージ未インストール、データ読み込み失敗等）をどう扱うかの記述がない。

**提案**: `analysis.R` / `report.Rmd` の冒頭で `pacman::p_load()` を使い、未インストールパッケージの自動インストール＋ロードを一括で行う。

```r
# pacman で一括ロード（未インストール時は自動インストール）
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(vcd, gt)
```

### 11. `report.Rmd` の `params$vars` のバリデーション

`params$vars` に1〜3個の変数名を渡す設計だが、0個・4個以上が渡された場合の挙動が未定義。

**提案**: Rmd の setup チャンクの先頭で `stopifnot(length(params$vars) >= 1, length(params$vars) <= 3)` を入れる設計方針を「配布物」節に追記。同時に、変数名がデータフレームの列名に存在するかのチェック（`%in% colnames(dat)`）も推奨。

### 12. `references/workflow.md` の位置づけが不明確

ディレクトリ構成（L188）に `references/workflow.md` が含まれるが、プラン本文でこのファイルの内容を具体的に述べているのは L167 の1行のみ。他の references ファイルには内容チェックリストがある。

**提案**: `workflow.md` の内容を以下のように具体化。
* スキルの典型的な使用フロー（Mermaid シーケンス図 1 本）
* 「どのテンプレをいつ使うか」の判断木（2-way vs 3-way、名義 vs 序数）
* `r-robust-workflow` グローバルスキルとの連携ポイント

### 13. SKILL.md の「行数上限 500 行」の根拠と計測時点

L200 で「500 行未満」としているが、references へ分離した結果 500 行を超えるリスクは低い。一方、**SKILL.md を読み込むエージェントのコンテキストウィンドウ上の実質的消費**を考えると「SKILL.md 本体は 200 行以内、references 各ファイルは 300 行以内」のように**分散上限**を設定する方が実装時のガイドになる。

### 14. `output_dir` の自動作成

`params$output_dir`（デフォルト `./skill_output/vcd_categorical/`）が存在しない場合の処理が未記載。

**提案**: `report.Rmd` の setup チャンクで `dir.create(params$output_dir, recursive = TRUE, showWarnings = FALSE)` を実行する旨をプランに追加。`analysis.R` も同様。

### 15. 検証節にレンダリング出力形式の網羅を追加

L225–231 の検証は HTML 出力（目視）のみ。`report.Rmd` は PDF 出力もサポートする設計だが、PDF レンダリング時の `gt` の互換性（`gt` は PDF 非対応、`as_latex()` は限定的）が未検証。

**提案**: 検証の項目に「**PDF 出力**: `kableExtra` への切り替えで `rmarkdown::render(..., output_format = "pdf_document")` が通ることを確認」を追加。`gt` で PDF が必要な場合は `webshot2` 経由の画像化を代替として references に記載。

---

## 第3次レビュー — 実装済みスキルの精査（2026-03-21 16:36 JST）

**対象**: `.agent/skills/vcd-categorical-analysis/` の全18ファイル（SKILL.md, templates/2本, references/7本, 出力サンプル画像3枚）。
`.cursor` 側との同期状態は **完全一致**（`.cursor` 側に `report.html` が1本余分にある以外）。

---

### A. 問題点・不足

#### A-1. `report.Rmd` — 飽和モデルの残差プロットが常に 0 になる問題

L159–161 で飽和モデル (`A * B * C`) の Pearson 残差をプロットしているが、**飽和モデルの残差は定義上すべて 0**。診断プロットとしては無意味。

```r
# L159: 現状（飽和モデルの残差 → 全て 0）
plot(residuals(fit_sat, type = "pearson"), ...)
```

**修正案**: 残差プロットは**非飽和の中間モデル（`m1` = 2因子交互作用まで）**で出すか、飽和モデルのプロットは削除し 3-way の `m0/m1/m2` の anova 結果のみにする。

#### A-2. `report.Rmd` — `load_builtin` が `UCBAdmissions` / `Arthritis` をサポートしていない

L43–53 で `Titanic` と `HairEyeColor` のみハードコード。検証で使うべきとプランに挙がっている `UCBAdmissions`（2-way 層別）、`vcd::Arthritis`（序数）が使えない。

**修正案**: `load_builtin` を汎用化するか、サポートデータを拡張。

```r
load_builtin <- function(name) {
  pkg <- if (name %in% c("Arthritis")) "vcd" else "datasets"
  data(list = name, package = pkg, envir = environment())
  obj <- get(name, envir = environment())
  if (is.table(obj)) as.data.frame(obj) else obj
}
```

#### A-3. `report.Rmd` — `Freq` 列を前提としているが、生データ（非集約）に非対応

L62 で `if (!"Freq" %in% names(dat)) stop(...)` がある。実際のアンケート生データはレコード単位（各行が1回答）で `Freq` 列がないことが多い。

**修正案**: `Freq` がなければ `xtabs(~ vars, data = dat)` で自動集約する分岐を追加（またはプランに記載）。

```r
if (!"Freq" %in% names(dat)) {
  message("Freq 列が見つかりません。行数ベースの集約を実行します。")
  dat <- as.data.frame(xtabs(as.formula(paste("~", paste(vars, collapse = " + "))), data = dat))
}
```

#### A-4. `analysis.R` — `pacman::p_load` がコメントアウトされている

L8 で `pacman::p_load` がコメントアウトされ `library()` が使われている。プランでは `pacman::p_load` を推奨パターンとしてまとめたが、テンプレ側が不整合。コメントにオフライン想定と書かれているが、SKILL.md の記述との統一が必要。

#### A-5. `analysis.R` — 3-way パイプラインが未実装

`analysis.R` は2-way（Titanic）の例のみ。プランの趣旨は「最小だが 2-way/3-way 両方をカバー」であり、`HairEyeColor` を使った 3-way の最小例が欠けている。

#### A-6. `.cursor` 側に `report.html`（生成済み出力）がコミットされている

`.cursor/skills/vcd-categorical-analysis/templates/skill_output/vcd_categorical/report.html` が存在するが `.agent` 側には無い。生成済み HTML はバージョン管理すべきでない。`.gitignore` に `skill_output/` を追加するか、該当ファイルを削除すべき。

#### A-7. `templates/skill_output/` がテンプレディレクトリ内に存在している

`templates/skill_output/vcd_categorical/figures/` に PNG ファイル3枚がある。テンプレというよりは**出力サンプル**（example output）。`templates/` の役割定義（「ユーザーがコピーして実行するファイル」）と矛盾する。

**修正案**: `examples/` ディレクトリに移動するか、`.gitignore` で生成済み出力を除外。

---

### B. 改善アイデア

#### B-1. Effect Size（効果量）の自動計算を追加

現状 χ² 検定の p 値のみで**効果量**（Cramer's V, φ 係数）の計算がない。RWD 分析・学術論文では効果量の報告が求められるケースが増えている。

**提案**: `report.Rmd` の `chisq-test` チャンクに Cramer's V を追加。

```r
# Cramer's V の計算（vcd パッケージに含まれる）
vcd::assocstats(tab)  # phi, Cramer's V, contingency coefficient
```

`vcd::assocstats` はすでに必須パッケージ `vcd` に含まれるため、依存追加なし。

#### B-2. Fisher の正確検定の自動フォールバック

`r-snippets.md` L37 に「Fisher の正確検定」に言及しているが、テンプレには未実装。期待度数 < 5 の警告が出た場合の自動フォールバックは実務上非常に有用。

**提案**: `report.Rmd` に条件分岐を追加。

```r
ct <- chisq.test(tab)
if (any(ct$expected < 5)) {
  warning("期待度数 < 5 のセルがあります。Fisher の正確検定を併記します。")
  print(fisher.test(tab, simulate.p.value = TRUE, B = 2000))
}
```

#### B-3. 3-way の層別（conditional）mosaic プロットの追加

現在の 3-way mosaic は全変数を一括表示するのみ。第3因子で層別した 2-way モザイクを並べると、交互作用の解釈が飛躍的に容易になる（Friendly の推奨パターン）。

**提案**: `report.Rmd` の `mosaic-plot` チャンクに条件付きモザイクを追加。

```r
if (length(dim(tab)) == 3L) {
  # 第3因子で層別した 2-way モザイクを並列表示
  cotabplot(tab, panel = cotab_mosaic, shade = TRUE,
            main = "Conditional mosaic (by 3rd factor)")
}
```

`vcd::cotabplot` は `vcd` パッケージに含まれており、追加コストなし。

#### B-4. 結果のサマリテキスト自動生成

Rmd のレンダリング結果が図表のみで、**解釈の要約テキスト**がない。インラインR で χ² の結果や最大残差のセルを自動要約すると、レポートとしての完成度が格段に上がる。

**提案**: `chisq-test` チャンクの後に inline R を使った要約段落を追加。

```markdown
χ² 検定の結果: χ²(`r ct$parameter`) = `r round(ct$statistic, 2)`,
p `r ifelse(ct$p.value < 0.001, "< 0.001", paste("=", round(ct$p.value, 4)))`.
最大の正の残差は `r names(which.max(ct$residuals))` セル（`r round(max(ct$residuals), 2)`）。
```

#### B-5. `params` に `alpha` レベルの追加

残差表の色分け閾値や統計的有意性の判定基準が固定（暗黙の α = 0.05）。`params` に `alpha` を追加し、Bonferroni 補正等も含めてカスタマイズ可能にする。

#### B-6. 日本語レポートテンプレの提供

SKILL.md やテンプレのコメントは日英混在。ユーザー環境（JST、日本語コメントルール）を考慮すると、`templates/report_ja.Rmd`（日本語セクションヘッダ・解説文）を提供するとユーザーフレンドリ。

---

### C. 軽微な改善

* **`analysis.R` L34**: `names(longdf)` で `"Var1"`, `"Var2"` とハードコードされているが、実際の変数名を使う方が出力の可読性が高い
* **`report.Rmd` L29**: `assoc` チャンクで `d >= 3L` のとき最初の2因子のマージンのみ表示しているが、どの2因子を選ぶかの説明が不足
* **`references/report-template.md`**: 構成の「抜粋」であり `report.Rmd` の変更に追随しない懸念がある。自動同期の仕組みがなければ、この references は削除して SKILL.md 内の表で代替してもよい
