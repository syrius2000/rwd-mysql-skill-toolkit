created: 2026-03-21 18:42 (JST)
author: AI Agent (Gemini 2.0 Pro)

# VCD Categorical Analysis 改善実装プラン

## Goal Description
`2026-03-21-vcd-categorical-skill-recommendations.md` で指摘されている課題（A-1〜A-7）および改善案（B-1〜B-5）を `.agent` および `.cursor` の両方のスキルコードベースに反映します。テスト結果の確認を踏まえ、`shade = TRUE` の適用は完了していますが、それ以外の堅牢性向上と機能追加がスコープとなります。

## User Review Required
> [!IMPORTANT]
> 以下の変更で問題ないか承認をお願いします。承認後、実際のコード修正および検証スモークテストの実行（EXECUTION/VERIFICATION）へ進みます。

## Proposed Changes

### `templates/report.Rmd` (A-1, A-2, A-3, B-1, B-2, B-3, B-4, B-5)
- **[MODIFY]** `report.Rmd`
  - **B-5**: `params` に `alpha: 0.05` を追加。
  - **A-2**: `load_builtin` 関数を拡張し、`Arthritis` (vcdパッケージ等) をロードできるように修正する。
  - **A-3**: データに `Freq` 列がない場合、`xtabs` を使って自動集約するフォールバック処理を追加する。
  - **B-1, B-2, B-4**: `chisq.test` チャンクにおいて、サンプルサイズ $N$ と期待度数に基づく分岐判断を導入する。
    1. **小規模/疎なデータ (`any(ct$expected < 5)`)**: Fisher の正確検定を実行・出力を追加する。
    2. **大規模データ ($N \ge 500$)**: カイ二乗検定の検出力が高くなりすぎ、実用上無意味な小さな差でもP値が有意（P < 0.05）になりやすい問題に対処するため、判定基準の主軸を**Cramer's V** (Cohenの効果量) にシフトする処理を追加する。
    3. 全てのケースで `vcd::assocstats(tab)` で Cramer's V を算出し、インライン R を用いて自動要約テキストを出力する。大規模データで $V < 0.1$ などの場合は「P値は有意ですが、効果量 $V$ は小さいため実質的な関連は弱い（または無視できる）可能性があります」等の解釈のガイドラインを自動付与する。
  - **B-3**: `mosaic-plot` チャンクにおいて、3-way (次元が3) の場合は `vcd::cotabplot` を用いた第3因子での条件付きモザイクプロットを追加出力する。
  - **A-1**: 飽和モデル (`fit_sat`) の残差はすべて0になるため、残差プロットの対象を 2-way の場合は主効果モデル (`fit0`)、3-way の場合は2因子交互作用モデル (`m1`) に変更して出力する。

### `templates/analysis.R` (A-4, A-5)
- **[MODIFY]** `analysis.R`
  - **A-4**: スキル指示書と一致させるため、パッケージ読み込みに `pacman::p_load` を使用する処理のコメントアウトを解除・修正する。
  - **A-5**: 2-way (Titanic) の例に加えて、3-way (HairEyeColor) のパイプライン実行例のコードブロックを追加する。

### `skill_output` と不要ファイルのクリーンアップ (A-6, A-7)
- **[DELETE]** `.cursor/skills/vcd-categorical-analysis/templates/skill_output/vcd_categorical/report.html` (リポジトリから削除)
- **[MODIFY]** `templates/skill_output/vcd_categorical/figures/` 内のモザイク/assoc画像 (.png) を新しく作成する `examples/` ディレクトリに移動し、`templates/skill_output/` は削除（または `.gitignore` で無視）する設定とディレクトリ構成見直しを行う。

*(注: `.agent` と `.cursor` の両方のディレクトリにあるファイルを同期して書き換えます)*

## Verification Plan

### Automated Tests
1. R スクリプトからコマンドラインで `analysis.R` を実行できることを確認する (エラーなく PNG・HTML・実行ログが出力されること)。
2. `.agent` および `.cursor` ディレクトリから `rmarkdown::render()` を呼び出し、`report.Rmd`（Titanic, HairEyeColor両方）が正常に HTML にコンパイルされるかスモークテストを行う。

### Manual Verification
- 生成された HTML (report.html) を開き、Fisher 検定のフォールバック、Cramer's V の出力、条件付きモザイクプロットの表示、及び飽和モデルではない残差プロットが適切に表示されているか（残差がゼロの一直線になっていないか）を目視確認する。
