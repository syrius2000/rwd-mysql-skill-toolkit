# 対象スキル
vcd-bayesian-evidence-analysis

## 位置づけ

このプロンプトは研修の必須デモです。`10_vcd-pass0-titanic.md` → `11_vcd-pass0-titanic100x.md` → `12_vcd-bayesian-titanic.md` → `13_vcd-bayesian-titanic100x.md` の結果を使い、生TitanicとTitanic 100倍を対比します。

## 標準プロンプト（コピペ用）
> 生Titanic（example/csv/titanic.csv）と Titanic 100倍（example/csv/titanic_100x.csv）を比較してください。前提として、Pass 0 は example/analysis/titanic/run_demo/ と example/analysis/titanic_100x/run_demo/、4-Pass分析結果は example/skill_out/vcd_bayesian/titanic/run_titanic_demo/ と example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/ を参照してください。必要であれば 10 → 11 → 12 → 13 の順にプロンプトを実行してから比較してください。比較では、N、セル比率、Residual、Evidence Score、Cramér's V、large_sample_mode、ダッシュボードの見どころを表で整理し、P値だけに依存する危険性と4-Pass分析で見るべき観点を新人向けに説明してください。Residual と Evidence Score はセル単位、Cramér's V は表全体の効果量として別枠で扱い、Cramér's V を全セル表の各行に付く指標のように説明しないでください。Cramér's V が未算出の場合は、値を推測せず、evidence_results.json の effect_status / effect_reason を引用して未算出理由を明記してください。出力は example/skill_out/vcd_bayesian/compare_titanic_vs_100x/ に保存してください。

## 入出力（example 固定）

- 入力:
  - `example/csv/titanic.csv`
  - `example/csv/titanic_100x.csv`
  - `example/analysis/titanic/run_demo/analysis_config.json`
  - `example/analysis/titanic_100x/run_demo/analysis_config.json`
  - `example/skill_out/vcd_bayesian/titanic/run_titanic_demo/evidence_results.json`
  - `example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/evidence_results.json`
  - `example/skill_out/vcd_bayesian/titanic/run_titanic_demo/executive_summary.md`
  - `example/skill_out/vcd_bayesian/titanic_100x/run_titanic100x_demo/executive_summary.md`
- 出力:
  - `example/skill_out/vcd_bayesian/compare_titanic_vs_100x/comparison_summary.md`

## 完了チェックリスト

- [ ] 生TitanicとTitanic 100倍のNが、それぞれ `2,201` と `220,100` として区別されていること
- [ ] セル構成と比率は同じで、`Freq` だけが100倍であることが説明されていること
- [ ] `evidence_results.json` の `Evidence_Score` や `Residual` を根拠に、100倍化で数値がどう変化したか説明されていること
- [ ] Cramér's V はセル単位ではなく全体効果量として別枠で比較されていること
- [ ] Cramér's V が未算出の場合は、`effect_status` / `effect_reason` に基づいて未算出理由が説明されていること
- [ ] 「P値の呪縛」を、単なる有意差ではなくサンプルサイズ依存の問題として説明していること
- [ ] 研修で見せるべきダッシュボードの確認先が明記されていること
