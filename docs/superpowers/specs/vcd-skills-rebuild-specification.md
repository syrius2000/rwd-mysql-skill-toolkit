# VCD 二連スキル再構築仕様書（要求・実装準拠）

created: 2026-04-05 02:30 (JST)

author: Cursor Agent (Claude)

## 0. 文書の位置づけ

| 役割 | 本書 | 備考 |
|------|------|------|
| **再構築の正本（契約）** | 各スキル `references/interface.md` | フィールド名・ファイル規約はここと一致させる |
| **再構築手順・REQ 樹** | **本書** | Skill ディレクトリを空から再生成する際のチェックリスト |
| **背景・設計意図** | [2026-04-04-vcd-skill-improvement-design.md](./2026-04-04-vcd-skill-improvement-design.md) | 歴史・判断理由 |
| **タスク分解** | [../plans/2026-04-04-vcd-skill-improvement.md](../plans/2026-04-04-vcd-skill-improvement.md) | 実装順序の参考 |

**interface_version（現行）: `2.1`**（`summary_*.json` および `interface.md` 先頭と一致すること）

---

## 1. リポジトリ配置・ミラー規則（必須）

```
.agent/skills/vcd-categorical-analysis/     … 開発・実行の正本（AGENTS.md 準拠）
.agent/skills/vcd-categorical-reporting/

.cursor/skills/vcd-categorical-analysis/    … Cursor 用ミラー（内容同一）
.cursor/skills/vcd-categorical-reporting/
```

- **SHALL**: `.agent` と `.cursor` の上記 2 スキルは**ファイル対応で同一内容**とする（`interface.md` はバイト一致が望ましい）。
- **SHALL NOT**: `templates/skill_out/` 等の実行生成物をスキル配下にコミットしない（`.gitignore` で `**/vcd-categorical-analysis/templates/skill_out/` を除外）。

---

## 2. スキル A: `vcd-categorical-analysis`

### 2.1 ディレクトリ樹（必須ファイル）

```
vcd-categorical-analysis/
├── SKILL.md
├── references/
│   ├── interface.md          … 共有契約（reporting と同一内容）
│   ├── workflow.md           … 2パス・判断木・連携
│   ├── dependencies.md       … パッケージ一覧
│   ├── glm-gnm-goodness.md
│   ├── ordinal-likert-advanced.md
│   ├── literature-and-packages.md
│   ├── report-template.md    … レガシー Rmd 向け等（既存維持）
│   └── r-snippets.md
├── templates/
│   ├── analysis.R            … メインパイプライン（必須）
│   └── report.Rmd            … レガシー一気通貫（削除しない）
└── tests/
    ├── test_logic.R            … 論理検証（推奨）
    └── verify_skill.sh         … 任意
```

### 2.2 SKILL.md 要求（YAML + 本文）

| 項目 | SHALL |
|------|--------|
| `name` | `vcd-categorical-analysis` |
| `description` | 2パス・最大3-way・出力 `skill_out/vcd_categorical`・reporting への誘導を含む |
| `metadata.version` | `interface.md` のメジャー改修に追従（現行 `2.1`） |
| 本文 | Pass 1/2 の bash 例、成果物表、5 関数表、**`report.Rmd` はレガシー**と明記 |
| 連携 | 後続 `vcd-categorical-reporting`、`interface.md` 参照 |

### 2.3 CLI（`analysis.R`）仕様

**モード判定**

- `--profile` が引数に含まれる → Pass 1（`profile`）
- それ以外 → Pass 2（`render`）

**フラグ一覧**

| フラグ | 必須 | 既定 | 説明 |
|--------|------|------|------|
| `--profile` | Pass1 で必須 | — | プロファイルのみ出力 |
| `--render` | （暗黙） | — | `--profile` 無しで Pass2 |
| `--data` | 外部 CSV 利用時 | `NULL` → **HairEyeColor** 内蔵 | CSV パス |
| `--vars` | `--data` 指定時は必須 | 内蔵時 `Hair,Eye,Sex` | カンマ区切り、2〜3 変数 |
| `--freq` | 任意 | `Freq` | 度数列名 |
| `--label` | 任意 | ファイル名から導出 or `haireye` | `data_label`（出力ファイル接尾辞） |
| `--out` | 任意 | `./skill_out/vcd_categorical/` | 出力ディレクトリ |
| `--config` | Pass2 で任意 | 無ければ空設定→`validate_config` で既定値 | `render_config.json` パス |

**データ読込（SHALL）**

- CSV: `read.csv(..., fileEncoding = "UTF-8")`、列名・文字列の `trimws`
- 度数列は数値化を試行（非数値時は警告して変換）
- 分析変数は factor 化、`droplevels`

### 2.4 `validate_config`（SHALL）

読み込み後の `raw`（`jsonlite::read_json`）に対し、**既知キーのみ**採用。未知キーは `[WARNING] Unknown config keys ignored: ...`。

| キー | 型 | 既定 | 不正時 |
|------|-----|------|--------|
| `collapse_below_n` | integer | `0` | 既定へ |
| `max_levels_per_var` | integer | `999` | 既定へ |
| `strata_to_render` | character vector | `character(0)` | 既定へ |
| `gt_matrix_vars` | 長さ2 integer | `c(1L, 2L)` | 既定へ |
| `plot_mode` | `"auto"` \| `"always"` \| `"residual_only"` | `"auto"` | 既定へ |

### 2.5 R 関数・実行順（Pass 2）

**実装シグネチャ（再構築時の準拠目安）**

```text
generate_profile(df, vars, freq_col, output_dir, config = NULL, out_filename = "data_profile.json")
generate_data(df, vars, freq_col, output_dir, config, data_label)
generate_gt_matrix(res_df, vars, freq_col, output_dir, config, data_label)
generate_dt_table(res_df, vars, output_dir, config, data_label)
generate_plots(tab, vars, output_dir, config, data_label)
```

**Pass 1 フロー**

1. `load_input_data`
2. `generate_profile(..., config = NULL, out_filename = "data_profile.json")`

**Pass 2 フロー（順序固定）**

1. `load_input_data`
2. `raw_config` 読込 → `validate_config` → `config`
3. `generate_profile(..., config = config, out_filename = "data_profile_post.json")`
   - **SHALL**: `config` により `collapse_below_n` / `max_levels_per_var` を**プロファイル前に**データへ適用（`generate_data` と同じロジック）
4. `generate_data`（再度同じ集約を適用 → プロファイルと本番の集約結果が一致）
5. `generate_gt_matrix(rbind(res_main, res_2way), ...)`
6. `generate_dt_table(rbind(...), ...)`
7. `generate_plots(tab, ...)`

### 2.6 集約アルゴリズム（SHALL）

**`collapse_below_n > 0`（変数ごと）**

- 各水準の `Freq` 合計が `<= collapse_below_n` の水準を `"Other"` にまとめる
- その後 `factor`

**`max_levels_per_var = K` かつ `K < 999`（変数ごと）**

- 水準数が `K` を超えるとき、水準別 `Freq` 合計の**降順で上位 K** を残し、それ以外を `"Other"`

順序: 先に `collapse_below_n`、次に `max_levels_per_var`（`generate_data` / `generate_profile` 内で同一）

### 2.7 統計モデル（SHALL）

- **Main**: `glm(Freq ~ A + B [+ C], family = poisson)`
- **2-Way**: `glm(Freq ~ (A + B [+ C])^2, family = poisson)`
- **飽和**: フィット試行（`anova` 用）
- **anova**: `stats::anova(fit_main, fit_2way, fit_sat, test = "Chisq")` から主 vs 2-way の p を取得
- 残差: Pearson、`cell_label` は `vars` 列を `:` 連結
- **Cramér V（周辺）**: `vcd::assocstats(margin.table(tab, c(1,2)))$cramer`（3-way 時）

### 2.8 `generate_gt_matrix`（SHALL）

- 行・列変数: `config$gt_matrix_vars` の `[1],[2]` を `vars` のインデックスとみなす。範囲外はクリップ `1..length(vars)`
- 周辺: `model_type == "Main"` のみでピボット、`matrix_marginal_{data_label}.html`
- 3-way: 第3変数を層とし、`strata_to_render` が空なら**全層**、非空なら**指定層のみ** → `matrix_{data_label}_{layer}.html`
- セル: Pearson 残差平均（aggregate）、`gt::data_color` 域 `[-mx,mx]`、パレット `#D73027`–白–`#4575B4`
- `|res| >= 1.96` の行に太枠（`cell_borders`）

### 2.9 `generate_dt_table`（SHALL）

- 列: `vars`, `Freq`, `pearson_res`, `abs_pearson_res`, `model_type`
- ソート: `abs_pearson_res` 降順、`pageLength = 50`、`filter = "top"`
- `htmlwidgets::saveWidget(..., selfcontained = TRUE)`
- ファイル名: `dt_residuals_{data_label}.html`

### 2.10 `generate_plots` / `plot_mode`（SHALL）

| `plot_mode` | 挙動 |
|-------------|------|
| `always` | 条件付き PNG をすべて出力 |
| `residual_only` | **PNG 出力なし**（メッセージのみ） |
| `auto` | 次を**両方**満たすときのみ描画: `prod(dim(tab)) <= threshold_cells` かつ `max(nchar(dimnames)) <= 24`。`threshold_cells`: 2-way **16**、3-way **36** |

**PNG（auto/always 時）**

- 常に `mosaic_{data_label}.png`
- 2-way のみ `assoc_{data_label}.png`
- 3-way 以上 `cotab_{data_label}.png`（`vcd::cotabplot`, `vars[3]` を条件軸）

### 2.11 `data_profile.json` / `data_profile_post.json`（SHALL）

- フィールドは `interface.md` の表どおり（`warning` はゼロセル時にメッセージ、なければ null）
- Pass 1: 集約**前**の `data_profile.json`
- Pass 2: 集約**後**の `data_profile_post.json`

### 2.12 レガシー `report.Rmd`（SHALL）

- 削除しない
- タイトルまたは冒頭に **LEGACY / v1.x** と分かる表記
- SKILL で「新規は `analysis.R` 2パス推奨」と記載

### 2.13 テスト（推奨仕様）

`tests/test_logic.R` で最低限:

1. Pass 1: 因子化・疎密度・`warning`
2. `validate_config` の型フォールバック・未知キー警告
3. Pass 2: `data_profile_post.json` の存在
4. `plot_mode: residual_only` で mosaic/assoc PNG が出ないこと

---

## 3. スキル B: `vcd-categorical-reporting`

### 3.1 ディレクトリ樹

```
vcd-categorical-reporting/
├── SKILL.md
└── references/
    ├── interface.md           … analysis と同一（バイト一致推奨）
    ├── workflow.md            … シーケンス・render_config 判断ガイド
    ├── report-template.md     … 3章テンプレ
    └── evaluation-criteria.md … 残差閾値・層選択・文体
```

### 3.2 SKILL.md 要求（SHALL）

| 項目 | 内容 |
|------|------|
| 前提 | `vcd-categorical-analysis` 先行、`./skill_out/vcd_categorical/` に成果物 |
| Pass 1（AI） | `data_profile.json` 読取 → `render_config.json` 方針（セル数>200 等のガイドは workflow と整合） |
| Pass 2（AI） | `summary_*.json` 二段思考、`strata_summary` で前面層選択、有意セル比率の注釈 |
| 成果物名 | **`vcd_analysis_report.md`**（Artifact 名固定） |
| 品質 | Mermaid 概況、`[!NOTE]` / `[!TIP]` の使用を推奨 |
| `metadata.version` | 契約変更時は analysis と整合（現状 reporting は `2.0` のままでも可だが、**interface 2.1 対応を本文で明示**推奨） |

### 3.3 `references` 内容の要件

- **workflow.md**: AI→R の 2パスシーケンス、`render_config` の判断表（セル数・層数・疎密度）
- **report-template.md**: 第1〜3章の見出し・表スロット
- **evaluation-criteria.md**: `|res|` 閾値（1.96 / 2.58 / 3.29）、層別選択ロジック、有意セル比率の解釈表

---

## 4. 成果物ファイル一覧（REQ-FILES）

`{data}` = `data_label`。すべて `output_dir`（既定 `./skill_out/vcd_categorical/`）直下。

| ID | ファイル | Pass | 必須 |
|----|----------|------|------|
| F01 | `data_profile.json` | 1 | Pass1 実行時 |
| F02 | `data_profile_post.json` | 2 | Pass2 |
| F03 | `summary_{data}.json` | 2 | ✓ |
| F04 | `residuals_{data}.csv` | 2 | ✓ |
| F05 | `residuals_{data}_significant.csv` | 2 | ✓ |
| F06 | `matrix_marginal_{data}.html` | 2 | ✓ |
| F07 | `matrix_{data}_{layer}.html` | 2 | 3-way かつ層ごと（0 層なら無しもあり得る） |
| F08 | `dt_residuals_{data}.html` | 2 | ✓ |
| F09 | `mosaic_{data}.png` | 2 | `plot_mode` によりスキップ可 |
| F10 | `assoc_{data}.png` | 2 | 2-way かつ plot 許可時のみ |
| F11 | `cotab_{data}.png` | 2 | 3-way かつ plot 許可時 |

---

## 5. 依存パッケージ（SHALL）

`pacman::p_load` 対象（`analysis.R`）:

`vcd`, `gt`, `DT`, `htmlwidgets`, `ggplot2`, `jsonlite`

詳細・Rmd 用の注記は `dependencies.md` に記載。

---

## 6. 受け入れ基準（再構築完了の定義）

- [ ] `.agent` / `.cursor` ミラー一致（`diff -rq`）
- [ ] 両スキル `references/interface.md` 一致、`interface_version: "2.1"`
- [ ] `Rscript analysis.R --profile ...` で F01 が妥当
- [ ] `Rscript analysis.R --render --config ...` で F02–F08、条件付き F09–F11
- [ ] `tests/test_logic.R` が exit 0
- [ ] reporting の SKILL が `vcd_analysis_report.md`・契約参照を満たす

---

## 7. REQ トレース（要約）

| REQ-ID | 内容 | 検証 |
|--------|------|------|
| REQ-SPLIT | 分析とレポートを 2 スキルに分離 | ディレクトリ樹 |
| REQ-IFACE | `interface.md` 双方向同一 | diff |
| REQ-CLI | §2.3 | 手動またはスクリプト |
| REQ-VAL | `validate_config` | test_logic / 手動 |
| REQ-POST | `data_profile_post.json` | test_logic |
| REQ-PLOT | `plot_mode` 三分岐 | test_logic |
| REQ-LEGACY | `report.Rmd` 残存＋SKILL 注記 | 目視 |
| REQ-MIRROR | `.agent`/`.cursor` | diff -rq |

---

## 8. 改訂履歴（本仕様 ↔ 旧 superpowers 設計）

| 項目 | 旧設計書（2026-04-04） | 現行（2.1） |
|------|------------------------|-------------|
| interface | 2.0 記載 | **2.1**、`warning`、`data_profile_post.json` |
| analysis 関数 | 表が `generate_gt_matrix(tab,...)` 等 | **実装は** `res_df` 起点の gt/DT、シグネチャは §2.5 |
| `validate_config` | なし | **必須** |
| `plot_mode` / `gt_matrix_vars` / `max_levels` | 契約のみの段階あり | **実装済み**（§2.6–2.10） |
| `report.Rmd` | 大規模改修スコープ外 | **レガシー明示・残存** |

---

## 9. 関連リンク

- 設計（背景）: [2026-04-04-vcd-skill-improvement-design.md](./2026-04-04-vcd-skill-improvement-design.md)
- 実装計画: [../plans/2026-04-04-vcd-skill-improvement.md](../plans/2026-04-04-vcd-skill-improvement.md)
