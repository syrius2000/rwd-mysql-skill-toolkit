# anomaly-detection 出力（`review_note.md` / `anomaly_results.jsonl`）の解釈

対象: `.agent/skills/anomaly-detection/`

本スキルの出力は「異常の確定」ではなく、**人手レビューの優先順位付け（review queue）**です。`label=normal` でも「問題なし」を意味しません（**しきい値未満**という意味）。

---

## 1. 何が出力されるか

- `review_note.md`
  - 実行条件、集計、上位候補（Top K）の表、解釈、推奨アクション
- `anomaly_results.jsonl`
  - 1行=1レコードの結果（`record_id`, `score`, `label`, `triggered_rules`, `model_contributions`, `explanation`）

---

## 2. 表（Top candidates）の各列の意味

`review_note.md` の表は次の列を持ちます。

- **rank**
  - 総合 `score` の高い順（1が最優先レビュー候補）
- **record_id prefix**
  - 匿名化された `record_id` の先頭（完全なIDは `anomaly_results.jsonl` を参照）
- **score**
  - 0〜1 の総合スコア（高いほど「要確認の可能性が高い」）
- **label**
  - しきい値で区分したカテゴリ（`normal` / `warning` / `critical`）
- **rule evidence**
  - ルールベースで引っかかった項目（説明可能な根拠）
- **model evidence**
  - 教師なしモデル由来の根拠（例: `iforest 0.5595`）

---

## 3. `score` と `label` の関係（重要）

### 3.1 `label` は `score` だけで決まる

既定設定（`configs/default.yaml`）:

- `warning`: score ≥ 0.55
- `critical`: score ≥ 0.80
- それ未満: `normal`

したがって、上位に並んでいても `score < 0.55` なら `label=normal` のままです。

### 3.2 `score` は複数ソースの加重平均

既定設定（例）:

- rule score（ルール）: 40%
- robust MAD（ロバスト統計）: 15%
- Isolation Forest: 25%
- LOF: 20%

単一テーブルのスモークテストでは、数値列（年齢・血圧・検査値など）が欠けると `robust_mad` が効かず、モデル evidence もカテゴリ特徴に偏ります。解釈は**ルール evidence を優先**してください。

---

## 4. `rule evidence` の解釈（例）

スモークテスト（VACCINE 単一テーブル）で典型的に現れる例:

### `duplicate_entity_key`

同一の `study_id / site_id / subject_id / visit_date / form_name` が重複している候補です。

レビュー観点:

- 同一イベントの重複入力か
- 更新履歴・再送・データマート統合など「正当な複数行」か

### `unresolved_query`

`is_query_open` のようなフラグ列がある場合に立つレビュー用シグナルです。

注意:

- **EDC の Query（発行・未解決）を直接表しているとは限りません**
- データ定義書（フラグの意味）を確認して扱ってください

### `temporal_inconsistency`

`recorded_at < visit_date` の候補です（監査上の確認対象になり得ます）。

---

## 5. `model evidence` の解釈（例: `iforest 0.5595`）

Isolation Forest（`iforest`）などの教師なしモデルは、**全体分布の中で「珍しい特徴量の組み合わせ」**を 0〜1 で表します。

使い方の基本:

- ルール evidence と整合するなら「優先度の後押し」
- ルール evidence が弱い／ないのにモデルが高いなら「未知のパターンの探索枠」
- 逆に、モデルが高くても業務上の意味が薄い特徴量由来（カテゴリ偏り等）の場合は過信しない

---

## 6. 1行（1レコード）の読み方（チェックリスト）

`anomaly_results.jsonl` の各行には `explanation` があり、以下の順で読むと早いです。

- **label / score**: アラート閾値を超えているか
- **triggered_rules**: 何が「説明可能な」根拠か
- **model_contributions**: どのモデルが押し上げたか（補助）
- **次アクション**: DB で原票確認、サイト集計、運用上の解釈確認

---

## 7. 実務上の推奨運用（最小）

- **rank 上位から見る**（全件レビューを前提にしない）
- まず **rule evidence を潰す**（重複・日付・欠損・フラグ）
- `label=normal` は「問題なし」ではなく「閾値未満」なので、**上位候補は通常のレビュー対象**として扱う
- 最終判断は、単一テーブルより **複数テーブル整合性**（時系列・関連フォーム・監査ログ）を優先する

