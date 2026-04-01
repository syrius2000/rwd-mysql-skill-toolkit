# 実装計画: mosaic/cotabplot のタイトル除去と文字サイズ調整
created: 2026-04-01 21:56 (JST)
author: GPT-5.2

## 背景
`vcd-categorical-analysis` の 3-way 出力で生成される conditional mosaic（`vcd::cotabplot()`）において、各パネルのタイトル文字が大きく、図の枠をはみ出して重なって見える（例: `skill_out/vcd_categorical/ucb_admit_gender_dept/figures/mosaic-plot-2.png`）。

## 目標
- **mosaic / cotabplot のタイトルを消す**
- **文字サイズ（ポイント）を小さくして可読性を上げる**
- `.agent` と `.cursor` のテンプレートを **同一修正** してミラー整合を維持する

## 対象
- `.agent/skills/vcd-categorical-analysis/templates/report.Rmd`
- `.cursor/skills/vcd-categorical-analysis/templates/report.Rmd`

## アプローチ案（2〜3案）
### 案A（推奨・最小変更）
- `mosaic()` と `cotabplot()` の `main` を **空文字**にする（タイトル除去）
- `mosaic-plot` チャンク内で base graphics の `par()` を一時的に設定し、文字サイズを下げる
  - 例: `par(cex = 0.9, cex.main = 0.9, cex.lab = 0.9, cex.axis = 0.9)`
  - 必要なら `mar` を調整し、タイトル領域（上マージン）を縮める

**利点**: 最小のコード差分で確実に直せる。
**欠点**: 文字サイズ調整が固定値（ただし実用上は十分）。

### 案B（パラメータ化）
- `params` に `base_cex` などを追加し、`par(cex = params$base_cex, ...)` として調整可能にする
- 同時に `show_mosaic_title` / `show_cotab_title` のような boolean を追加して切替可能にする

**利点**: 再利用性が高い。
**欠点**: パラメータが増え、テンプレの理解コストが上がる。

### 案C（描画サイズで逃がす）
- `mosaic-plot` チャンクに `fig.width` / `fig.height` / `dpi` を付け、画像自体を大きくして重なりを解消

**利点**: コード変更が少ない。
**欠点**: “タイトル文字が大きすぎる”根本は残り、ケースによって再発。

## 推奨
まず **案A** を適用し、必要なら **案C** を併用（図のサイズも少し上げる）。
パラメータ化（案B）は要望が出た時点で追加する。

## 具体的変更内容（案A）
テンプレの `mosaic-plot` チャンク（`mosaic()`/`cotabplot()` 呼び出し部）で以下を行う。
- `mosaic(..., main = "")`
- `vcd::cotabplot(..., main = "")`
- `op <- par(no.readonly = TRUE)` を保存して `on.exit(par(op), add = TRUE)` で復帰
- `par(cex = 0.9, cex.main = 0.85, ...)` を設定（値はレンダリングで微調整）

## 検証計画
- `datasets::UCBAdmissions`（3-way: `Admit`, `Gender`, `Dept`）を再レンダリングし、
  - `skill_out/vcd_categorical/ucb_admit_gender_dept/figures/mosaic-plot-2.png` のタイトル重なりが解消している
  - `Dept = A` などのパネル表示（ストリップ）は保たれている
- 2-way（`Admit`, `Gender`）でも `mosaic-plot-1.png` が破綻していない
- `.agent` と `.cursor` のテンプレ差分が無い（同一修正）

## 完了条件（DoD）
- conditional mosaic のタイトルが表示されない
- 文字サイズが小さくなり、パネル内文字が重ならない
- `.agent` と `.cursor` 双方に同一修正が入っている
