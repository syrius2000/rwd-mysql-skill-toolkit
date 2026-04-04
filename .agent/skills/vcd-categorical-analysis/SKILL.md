---
name: vcd-categorical-analysis
description: アンケート等の名義カテゴリカル変数（最大 3-way）に対し、クロス表・独立性検定・Pearson 残差（色分け表）・mosaic/assoc 可視化・対数線形モデル適合度を R コードまたは R Markdown テンプレとして生成する。出力は ./skill_out/vcd_categorical/。序数リッカートの扱いは references の高度な分析に誘導する。
license: MIT
metadata:
  author: vcd-categorical-analysis-skill
  version: "2.0"
---

名義カテゴリのクロス表・独立性・**Pearson 残差**・**vcd** 可視化・**Poisson 対数線形（GLM）** を、コピー実行可能な `templates/` と詳細な `references/` で支援する。エージェントは **R を実行して個別結果を抽出し、AIによる解釈レポート（第一章：評価・第二章：残差・第三章：図表）を作成**する。

## スコープ

| 項目 | 内容 |
| :--- | :--- |
| **次元** | **3-way まで**（`xtabs(~ A + B + C, data)`）。**4-way 以上は対象外**（ユーザーに明示し、分割・集約を提案）。 |
| **主用途** | 比率・クロス表・独立性からの乖離（Pearson 残差の解釈）。 |
| **可視化** | **主**: `vcd::mosaic(..., shade = TRUE)`。**補**: `vcd::assoc(..., residuals_type = "Pearson", shade = TRUE)`（着色し忘れに注意）。水準数・ラベル長が大きい場合は auto 省略される（下記参照）。 |

### mosaic / assoc 自動省略 (`plot_mode`)

水準数が多い・ラベルが長いテーブルでは mosaic/assoc が判読不能になるため、既定 `auto` で自動省略し GLM 残差プロットを主表示にする。

| パラメータ | 既定値 | 説明 |
| :--- | :--- | :--- |
| `plot_mode` | `auto` | `auto` / `always` / `residual_only` |
| `max_cells_2way` | 16 | 2-way セル数しきい値（超過で省略） |
| `max_cells_3way` | 36 | 3-way セル数しきい値（超過で省略） |
| `max_label_chars` | 24 | 最長ラベル文字数しきい値（超過で省略） |

セル数 **または** ラベル長のいずれかが超過した場合に省略。`always` で強制描画も可。

### 残差プロット自動形式切り替え (`residual_plot_mode`)

セル数が多い場合、従来の dotplot（coord_flip）もラベルが潰れるため、ヒートマップ形式に自動切り替えする。

| パラメータ | 既定値 | 説明 |
| :--- | :--- | :--- |
| `max_cells_dotplot` | 25 | dotplot で描画可能な最大セル数（超過でヒートマップ） |

| 条件 | 描画形式 | 説明 |
| :--- | :--- | :--- |
| 2-way & セル ≤ 25 | `dotplot` | 従来の geom_point + coord_flip |
| 2-way & セル > 25 | `heatmap` | geom_tile（X=var2, Y=var1, fill=残差） |
| 3-way & セル ≤ 25 | `dotplot` | 従来形式 |
| 3-way & セル > 25 | `facet_heatmap` | facet_wrap(var3) + geom_tile |
| **残差表** | **既定は `gt`（HTML）** | PDF/LaTeX 主目的は `kableExtra` |
| **対象外** | **Correlogram** | 多数項目のざっくり関連は Cramer's V 参考のみ |
| **序数・リッカート** | メインは 1 段落 | 詳細は `references/ordinal-likert-advanced.md` |

## 出力先

分析例・図表・レンダー結果はプロジェクトルートの **`./skill_out/vcd_categorical/`**（必要に応じて `ordinal/` 等のサブディレクトリ）。

レンダー後、同じディレクトリに **`.metrics.rds`** が書かれ、Cramér の V 関連指標（`cramer_v_marginal`, `cramer_v_df_star`, `cramer_v_effect_label`, 3-way の層別 JSON・平均・最大、`marginal_strata_signal` など）を回収できる。

## 効果量（Cramér の V）

- **2-way**: 表全体の V。ラベルは英語（`negligible` / `small` / `medium` / `large`）。閾値は 0.1, 0.3, 0.5 を `sqrt(min(r-1,c-1))` で割った値、境界は **≥**。
- **3-way**: **周辺** var1×var2 の V に加え、`vcd::assocstats` による **第3次元の層別** V（リスト）。`|V_marginal - mean(V_strata)| ≥ 0.05` で `marginal_strata_signal = review_stratified`（層別優先の注意）。探索的ヒューリスティックであり、シンプソン・パラドックスの正式検定ではない。

## 手順（AIによる章立てレポート出力）

データが与えられた際、従来の「一気通貫によるRender」と異なり、エージェントは以下のステップを遵守して実行すること：

1. **個別結果の出力**: `templates/analysis.R` を実行し、結果表（JSON・CSV）やプロット画像を `./skill_out/vcd_categorical/` に生成する。
2. **AI評価（第一章：AI評価）**: 生成された `summary_*.json` および `residuals_significant.csv` を読み込み、以下の2段階で思考し、記述すること。
   - **第1段階（全体構造の俯瞰）**: 主効果モデル (`model_type == "Main"`) の残差から、「変数間に存在する自明かつ強力な関連性」を指摘する。
   - **第2段階（局所交互作用の洞察）**: 2-way交互作用モデル (`model_type == "2-Way"`) の残差から、「単純な相関だけでは説明できない、3要因の組み合わせ特有の偏り（Simpsonのパラドックスや潜在的な相互作用）」を鋭く言語化する。
3. **残差サマリー（第二章：モデル・残差サマリー）**: モデル指標（Deviance, $p$値）および、有意な残差（$|res| > 1.96$）を持つセルを、解釈のしやすさを優先して「主効果モデル」ベースで一覧提示する。
4. **参考図表（第三章：参考図表）**: 生成されたプロット画像を配置する。

> [!IMPORTANT]
> 報告は必ず **`vcd_analysis_report.md`** という名前の Artifact として作成すること。
> デザインは Mermaid シーケンス図による概況説明や、`> [!NOTE]` などのバッジを駆使し、ビジネスエグゼクティブにそのまま提示できる品質とすること。

## リソースの使い分け

| パス | 役割 |
| :--- | :--- |
| `templates/analysis.R` | JSON等の個別結果・プロット出力用Rスクリプト。エージェントが実行して結果を読み取る。 |
| `templates/report.Rmd` | 一気通貫HTML出力用（ユーザーが単体でKnittedレポートが欲しい場合向け）。 |
| `references/` | ワークフロー、スニペット、GLM/gnm、序数、文献・パッケージ、依存一覧。 |

詳細は **`references/workflow.md`**。パッケージ一覧は **`references/dependencies.md`**（**R Markdown 利用時は `rmarkdown` / `knitr` が実質必須**）。

## モデル（概要）

- **2-way**: `stats::chisq.test` と `glm(count ~ A * B, family = poisson)`（対数線形）を併記。
- **3-way**: 主効果のみ → 2 因子交互作用まで → 飽和、を **`stats::anova(..., test = "Chisq")`** で比較（スニペットは `references/glm-gnm-goodness.md` と `templates/report.Rmd`）。
- **gnm** や対称性モデルは **オプション**（`references/glm-gnm-goodness.md`）。

## 追加リソース（リンクは 1 段まで）

- **`references/literature-and-packages.md`** … vcd / vcdExtra / Agresti / Friendly / Blog 等への誘導を集約。
- **ヘルプ**: `?vcd::mosaic`、`?vcd::assoc`。

## 関連スキル（任意）

DB からの件数・スキーマ確認が先に必要なら、本リポジトリの **`mysql-table-cardinality`**（`.cursor/skills/mysql-table-cardinality/`）を参照。データ取得〜前処理の分担は `references/workflow.md`。

## 配置

- **Cursor**: `.cursor/skills/vcd-categorical-analysis/`
- **Antigravity**: `.agent/skills/vcd-categorical-analysis/`（**同一内容をミラー**）
