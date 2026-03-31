# 実装計画: カテゴリカル分析2スキルの改善・拡張おすすめプラン

- 日付: 2026-04-01 (JST)
- ステータス: 計画中
- 対象: vcd-categorical-analysis, questionnaire-batch-analysis
- 目的: 統計的妥当性・解釈性・運用性を同時に高める

---

## 1. 背景

現状の2スキルは、カテゴリカル解析の自動化として十分に実用的だが、次の改善余地がある。

- 複数設問を一括解析する際の多重比較リスク
- p値中心で、効果量の解釈が弱い
- 疎セル（期待度数不足）で検定の頑健性が落ちる可能性
- 品質ゲート（解析前提チェック）が弱く、誤読リスクが残る
- 3-way 解析の交互作用・層別解釈が標準化されていない

---

## 2. 到達目標

### 2.1 統計面

- 多重比較補正を標準出力に追加（未補正と併記）
- 効果量を主指標として常時提示
- 疎セル時に妥当な検定へ自動フォールバック

### 2.2 レポート面

- 実務向け意思決定サマリー（結論3行 + 注意点）を標準化
- 残差の寄与セルを視覚的に強調（上位セルの可視化）

### 2.3 運用面

- 解析品質ゲート（サンプル不足・不均衡・期待度数違反）を導入
- テストを「統計的意味の回帰検知」まで拡張

---

## 3. フェーズ別ロードマップ

## 3.0 TDD駆動の実装原則

- 本計画の実装は必ず RED -> GREEN -> REFACTOR で進める。
- 実装前にテストケースを先に追加し、失敗を確認してから本体実装に入る。
- 1機能1コミット単位で、テストと実装を同時に完結させる。
- 統計ロジックの変更時は、数値妥当性テストを必須にする。

### 3.0.1 RED (先に失敗テストを書く)

- 多重比較補正: BH補正列が存在しないと失敗するテストを先に追加。
- 効果量: Cramer's V が未出力なら失敗するテストを先に追加。
- 疎セルフォールバック: 期待度数条件で採用検定法が切り替わらないと失敗するテストを先に追加。
- 品質ゲート: quality_flag / quality_reason が未出力なら失敗するテストを先に追加。

### 3.0.2 GREEN (最小実装で通す)

- REDで追加したテストだけを最小実装で通す。
- 出力列の追加は既存列を壊さない形で末尾に追加する。
- 2スキルで列名・定義の整合を同時に満たす。

### 3.0.3 REFACTOR (意味を維持して整理)

- 共通ロジックを関数化し、重複実装を削減する。
- レポート文言・列順・欠損時メッセージを統一する。
- リファクタ後に全テスト再実行し、統計量の値が変わらないことを確認する。

### 3.0.4 TDDでの優先テスト順

1. 出力スキーマテスト（列追加・列名整合）
2. 統計妥当性テスト（補正p値、効果量、検定分岐）
3. レポート回帰テスト（HTML主要セクション）
4. 実データE2Eテスト（Q09_long.csv）

## Phase 1 (短期: 1-2週間)

### 3.1 多重比較補正（最優先）

- questionnaire-batch-analysis の summary 出力へ以下を追加:
  - p_value_raw
  - p_value_fdr_bh
  - p_value_holm (任意)
- レポート本文に「補正前/補正後」の解釈ガイドを明記

### 3.2 効果量の標準出力

- 2-way/3-way 共通で Cramer's V を出力
- 2値比較で適用可能な場合は OR/RR をオプション追加
- summary.csv に effect_size 列群を追加（既存列は維持）

### 3.3 疎セル時フォールバック

- 期待度数の最小値、5未満セル割合を算出
- 条件に応じて:
  - Fisher 検定（2x2優先）
  - モンテカルロ近似（必要時）
- 使用した検定法をレポートに明記

### 3.4 品質ゲート v1

- 下記を自動判定して warning フラグ出力:
  - n_total が閾値未満
  - 極端不均衡
  - 期待度数違反率
- summary.csv に quality_flag / quality_reason を追加

## Phase 2 (中期: 2-4週間)

### 3.5 3-way 解釈の標準化

- 条件付き独立と交互作用の説明チャンクを追加
- 層別で効果量比較（各層の Cramer's V）
- レポート冒頭に「3-way の読み方」をテンプレート化

### 3.6 残差可視化の強化

- 標準化残差ヒートマップを追加
- |residual| 上位セルを表・注釈でハイライト
- 既存 residual plot と重複しない補助情報として実装

### 3.7 前処理ポリシーの明示化

- 欠測処理、低頻度カテゴリ統合ルールを設定ファイル化
- レポートに「今回適用した前処理」を自動出力

## Phase 3 (長期: 4週間+)

### 3.8 意思決定サマリー

- 固定フォーマットで最後に出力:
  - 主要結論
  - 実務アクション候補
  - 統計的制約

### 3.9 テスト基盤の拡張

- メタモルフィックテスト導入（既知データの方向性検証）
- しきい値境界ケース（n小、疎セル、偏り大）を追加

### 3.10 ベイズ拡張（オプション）

- 事後分布ベースの比較を追加可能に設計
- 頻度論レポートと並立できる params 設計

---

## 4. 変更対象（想定）

### テンプレート・ロジック

- .agent/skills/vcd-categorical-analysis/templates/report.Rmd
- .agent/skills/questionnaire-batch-analysis/templates/report.Rmd
- .agent/skills/questionnaire-batch-analysis/templates/batch_runner.R

### 仕様書・ドキュメント

- .agent/skills/vcd-categorical-analysis/SKILL.md
- .agent/skills/questionnaire-batch-analysis/SKILL.md — summary.csv 列定義の正式更新含む
- .agent/skills/questionnaire-batch-analysis/references/interpretation.md — 効果量・品質ゲートの読み方追記
- .agent/skills/vcd-categorical-analysis/references/interpretation.md — 同上

### テスト

- tests/test_questionnaire_batch_smoke.R
- tests/test_questionnaire_batch_ucbadmissions.R
- tests/test_vcd_categorical_smoke.R
- tests/test_vcd_categorical_template_residual_layout.R
- tests/test_summary_csv_new_columns.R — 新列テスト拡張（既存ファイル更新）
- tests/ (新規) 統計妥当性テスト（既知データで数値検証）
- tests/ (新規) 境界値テスト（全セル同一、2x2最小、極端偏り）
- tests/ (新規) .agent/.cursor 同期チェックテスト

注: .cursor/skills 側に同一内容を同期する。

---

## 5. リスクと対策

1. 列追加による下流互換性の崩れ
- 対策: 既存列順は保持し、新列は末尾追加

1. 検定法分岐で挙動が複雑化
- 対策: レポートへ「採用検定法」と理由を必ず表示

1. 多重比較補正の誤解
- 対策: 未補正/補正後を併記し、判定基準を明記

1. .agent/.cursor 不整合
- 対策: 変更完了後に同期と差分確認を必須化。同期テストを自動化

1. SKILL.md 仕様と実装の乖離
- 対策: 列追加時に SKILL.md の summary 列定義を同時更新。CI で列一覧を検証

1. 既存部分実装との衝突（vcd の Cramer's V 2-way、Fisher 2-way）
- 対策: 既存ロジックを壊さず拡張する設計とし、2-way 出力の回帰テストを先に追加

---

## 6. 検証計画

1. 単体検証
- 補正p値列が summary に追加される
- 効果量が NA でなく計算される（計算不可条件は理由付き）
- 疎セルケースで検定フォールバックが発動する

1. TDD検証（RED/GREEN確認）
- 各Phaseで「先に追加したテストが最初に失敗した証跡」を残す
- 実装後に同一テストが通ることを確認する
- リファクタ後に差分テストで統計値の不変性を確認する

1. 回帰検証
- 既存のレポート出力（HTML/図）を維持
- 既存の主要テストが通る

1. 実データ検証
- Q09_long.csv で2スキル実行
- 補正p値、効果量、quality_flag を確認

---

## 7. 完了条件 (Definition of Done)

- 多重比較補正・効果量・検定フォールバック・品質ゲートが実装される
- 2スキルで共通指標の列名/定義が揃う
- 既存テスト + 追加テストが pass
- RED -> GREEN -> REFACTOR の実施ログが残っている
- .agent と .cursor の同期が確認できる

---

## 8. 推奨着手順（実装優先度）

1. Phase 1: 3.1, 3.2, 3.3, 3.4
2. Phase 2: 3.5, 3.6, 3.7
3. Phase 3: 3.8, 3.9, 3.10

---

## 9. 実装前の合意ポイント

1. 補正法の既定を BH のみにするか、BH+Holm 併記にするか
2. 効果量の既定セット（Cramer's V のみ / OR-RR 追加）
3. 品質ゲート閾値（n, 期待度数違反率, 不均衡率）
4. ベイズ拡張を今期スコープに含めるか
5. 3-way の Cramer's V 算出方針（全体テーブル / 層別マージンごと / 両方併記）
6. vcd 側に summary.csv / metrics 出力を追加するか（2スキル横断比較の要否）
7. questionnaire の SKILL.md summary 列定義の正式更新タイミング（Phase 1 開始時 / 各列追加時）

---

## 10. 現状精査による追加事項

前回のスキル現状チェック（2026-04-01）で発見した抜け漏れと対応方針。

### 10.1 既に部分実装済みの機能（上書きリスク注意）

| 機能 | 現状 | 注意点 |
|---|---|---|
| 効果量 Cramer's V | vcd: 2-way のみ `assocstats(tab)$cramer` で出力中。3-way 未実装 | 3.2 で 3-way 拡張時に 2-way 出力を壊さない設計が必要 |
| 疎セル Fisher | vcd: 2-way で `any(ct$expected < 5)` → Fisher 併記済み。questionnaire: 未実装 | questionnaire 側への移植が 3.3 の主作業。vcd 側は 3-way 対応が追加 |

### 10.2 計画から漏れていた項目

| # | 項目 | 重要度 | 対応方針 |
|---|---|---|---|
| B1 | summary.csv 列定義: SKILL.md に未記載の列が実装に存在 | HIGH | Phase 1 開始時に SKILL.md の列定義を実装と同期。合意ポイント 7 で決定 |
| B2 | vcd 側に summary.csv / metrics 出力がない | HIGH | 合意ポイント 6 で要否を決定。追加する場合は Phase 1 に組み込む |
| B3 | questionnaire の Fisher フォールバック未実装 | MEDIUM | 3.3 の変更対象に questionnaire report.Rmd を明記済み（Section 4 更新済み）|
| B4 | 3-way の効果量算出方法が未決定 | MEDIUM | 合意ポイント 5 で方針決定。Phase 2 (3.5) で実装 |
| B5 | vcd の大規模データ警告が questionnaire にない | LOW | Phase 2 (3.7) の前処理ポリシー明示化と同時に統一 |
| B6 | .agent/.cursor 同期テストの自動化 | MEDIUM | Section 4 テスト欄に追加済み。Phase 1 で自動同期チェックを導入 |
| B7 | references/interpretation.md の更新漏れ | LOW | Section 4 ドキュメント欄に追加済み。効果量・品質ゲート追加時に同時更新 |

### 10.3 テスト網羅性の不足と対策

| 現状テスト | カバー範囲 | 必要な追加 |
|---|---|---|
| test_vcd_categorical_smoke.R | base R の chisq/glm 動作確認のみ | 効果量・Fisher フォールバック・品質ゲートの数値テスト |
| test_questionnaire_batch_smoke.R | バッチ実行と summary.csv 生成確認 | 多重比較補正列・品質ゲート列のスキーマテスト |
| test_summary_csv_new_columns.R | 既存 4 新列の存在テスト | 新列 (p_value_fdr_bh, effect_size, quality_flag 等) のテスト追加 |
| (欠落) 統計妥当性テスト | なし | 既知データ (UCBAdmissions 等) で Cramer's V, 補正p値の期待範囲を検証 |
| (欠落) 境界値テスト | なし | 全セル同一度数 (V=0)、2x2 最小テーブル、1セルだけ極端に大きいケース |
