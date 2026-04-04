# 実装計画: 残差表ヘッダから cell_label を既定で除外

- 日付: 2026-04-01 (JST)
- ステータス: **実装完了** (2026-04-01)
- 対象: vcd-categorical-analysis, questionnaire-batch-analysis
- 目的: 残差表の可読性向上のため、列見出しを既定で
  Admit / Gender / Dept / pearson_res / abs_res
  の 5 列構成に統一し、cell_label は既定表示から外す。

---

## 1. 背景と課題

現在の残差表は、人間が読むレポート表に cell_label を含むため、
- 横幅が広がる
- 同じ情報がカテゴリ列と重複する
- 3-way で特に視認性が落ちる

という課題がある。

一方で cell_label は以下で必要:
- max_residual_cell の算出
- top3_residual_cells の算出
- dotplot の軸ラベル生成

したがって「内部計算には保持」「表示テーブルからは除外」を基本方針とする。

---

## 2. 目標仕様

### 2.1 表示仕様

- 残差表の表示列（既定）
  - vars（2-way なら 2 列、3-way なら 3 列）
  - pearson_res
  - abs_res
- cell_label は既定では非表示

### 2.2 互換性方針

- cell_label 列の内部保持は継続（破壊的変更を避ける）
- summary の以下は現行維持
  - max_residual_cell
  - top3_residual_cells
- 既存指標・検定結果・画像出力パス仕様は変更しない

### 2.3 オプション設計（提案）

将来拡張として params に include_cell_label_in_table を追加可能にする。
- 既定: FALSE
- TRUE 時のみ表示テーブルへ cell_label を追加

本計画ではまず既定非表示までを最小実装とし、オプション化は Phase 2 として分離可能。

---

## 3. 変更対象（実装予定）

## Phase 1: 表示列の整理（最小変更）

1. .agent/skills/vcd-categorical-analysis/templates/report.Rmd
- residual_table_view の列選択から cell_label を除外
- 想定変更前: c(vars, "pearson_res", "abs_res", "cell_label")
- 想定変更後: c(vars, "pearson_res", "abs_res")

1. .agent/skills/questionnaire-batch-analysis/templates/report.Rmd
- residual-table チャンクの表示列から cell_label を除外
- 想定変更前: c(vars, "pearson_res", "abs_res", "cell_label")
- 想定変更後: c(vars, "pearson_res", "abs_res")

## Phase 2: ミラー同期

1. .cursor/skills/vcd-categorical-analysis/templates/report.Rmd
- .agent 側と同一変更を反映

1. .cursor/skills/questionnaire-batch-analysis/templates/report.Rmd
- .agent 側と同一変更を反映

## Phase 3: ドキュメント反映（必要なら）

1. .agent/skills/questionnaire-batch-analysis/SKILL.md
2. .agent/skills/vcd-categorical-analysis/SKILL.md
3. .cursor 側の同名 SKILL.md
- 残差表列仕様を 5 列基準に更新
- 「内部では cell_label を保持し summary で利用」を明記

---

## 4. 非対象（今回やらないこと）

- max_residual_cell / top3_residual_cells の廃止
- residual plot のラベル生成ロジック変更
- mosaic/assoc の描画条件変更
- summary.csv の列削減

---

## 5. リスクと対策

1. テストが cell_label 列の存在を前提にしている可能性
- 対策: tests 配下で cell_label 前提 assertion を検索し、必要箇所のみ修正

1. 下流処理が report.html の表ヘッダ文字列一致で検証している可能性
- 対策: 文字列一致依存を列名集合チェックへ緩和

1. .agent と .cursor の差分発生
- 対策: 同一変更をペアで実施し、差分確認を追加

---

## 6. 検証計画

1. 単体確認
- vcd テンプレートで residual_table_view に cell_label が含まれないこと
- questionnaire テンプレートで gt 表示列に cell_label が含まれないこと

1. 回帰確認
- max_residual_cell, top3_residual_cells が従来どおり出力されること
- residual_plot が従来どおり生成されること

1. テスト実行候補
- tests/test_vcd_categorical_template_residual_layout.R
- tests/test_questionnaire_batch_smoke.R
- tests/test_questionnaire_batch_ucbadmissions.R
- 必要時: report.html の列見出し確認テストを 1 件追加

---

## 7. 完了条件 (Definition of Done)

- 2 スキル（vcd / questionnaire）とも、残差表の既定表示から cell_label が除外されている
- .agent / .cursor 双方に同一反映がある
- summary 指標（max_residual_cell, top3_residual_cells）が維持される
- 既存主要テストが通る（または失敗理由が本変更と無関係で説明可能）

---

## 8. 実装順序案

1. vcd (.agent)
2. questionnaire (.agent)
3. .cursor 同期
4. テスト
5. 必要なら SKILL.md 更新

---

## 9. 判断ポイント（実装前合意）

1. 今回は「既定非表示のみ」で進めるか
2. 同時に include_cell_label_in_table オプションを導入するか
3. report.html の見出し固定テストを追加するか
