# anomaly-detection 出力（`summary.json` / `anomaly_results.jsonl` v0.2.0）の解釈

対象: `.agents/skills/anomaly-detection/` (バージョン: `v0.2.0`)

本スキルの出力は「異常の確定」ではなく、**人手レビューの優先順位付け（review queue）**および**データ品質ドリフトモニタリング**です。`label=normal` でも「問題なし」を意味しません（**しきい値未満**という意味）。

---

## 1. 何が出力されるか

推論実行時（`make infer` または CLI 実行時）、以下の成果物が `skill_out/anomaly_detection/run_<id>/` に出力されます。

- `anomaly_results.jsonl` (スキーマ: `output.schema.json` v0.2.0)
  - 1行=1レコードの結果（`schema_version`, `record_id`, `score`, `label`, `triggered_rules`, `model_contributions`, `explanation`）
- `summary.json`
  - バッチ全体の集計結果（`schema_version`, `n_records`, `n_returned`, `n_warning_or_critical`, `audit`, ポピュレーション安定性指標 `psi_metrics`, KS検定 `ks_metrics`）
- `review_note.md` (生成オプション有効時)
  - 実行条件、集計、上位候補（Top K）の表、解釈、推奨アクション

---

## 2. 表（Top candidates）の各列と統合スコア (v0.2.0)

### 2.1 スコア統合 (Score Fusion)

既定設定（`configs/default.yaml`）における各検出器の評価割合:

- **rule score（臨床/構造ルール）**: 30%
- **robust MAD（ロバスト統計）**: 10%
- **Isolation Forest（決定木外れ値）**: 20%
- **LOF（密度偏差外れ値）**: 15%
- **MCD（ロバストマハラノビス距離）**: 15%
- **STL（時系列分解残差）**: 10%

各スコアは 0〜1 に min-max 正規化され、加重平均された総合 `score` に基づいて `label`（`normal` / `warning` (≥0.55) / `critical` (≥0.80)）が自動付与されます。

---

## 3. v0.2.0 で追加されたモデル・指標の解釈

### 3.1 MCD (Minimum Covariance Determinant)
- **解釈**: 多変量数値データの相関構造から外れたサンプル（多変量外れ値）を、ロバスト共分散行列を用いて検出します。
- **使いどころ**: 年齢・血圧・検査値の相互相関関係が通常と異なる臨床的に特異な症例を検出します。

### 3.2 STL (Seasonal-Trend Decomposition)
- **解釈**: 時系列データのトレンド成分・季節周期成分（例: 7日周期）を分解し、予測値からの残差（乖離）を検出します。
- **使いどころ**: 定期受診データや日次バイタルにおいて、通常の周期パターンから突発的に逸脱した測定値を捕捉します。

### 3.3 PSI (Population Stability Index) & KS検定 (`summary.json`)
- **解釈**: ベースライン期間/群（`baseline_group`）と最新期間/群（`current_group`）の分布シフトを計測します。
- **判定基準**:
  - `psi_value < 0.10`: 安定 (`stable`)
  - `0.10 ≤ psi_value ≤ 0.25`: 中度のシフト (`moderate_shift`)
  - `psi_value > 0.25`: 重大なシフト (`significant_shift`)
- **使いどころ**: データマート統合後や施設追加後の全体的なポピュレーション変化・測定機器変更に伴うデータシフトを早期検知します。

---

## 4. 実務上の推奨運用

- **rank 上位から見る**（全件レビューを前提にしない）
- まず **rule evidence を確認**（重複・日付・欠損・範囲外）
- 次に **MCD / STL / IForest などのモデル貢献度** を参考にして未知の異常パターンを精査
- `summary.json` の `psi_metrics` で `significant_shift` が検出された場合は、個々のレコード異常だけでなくデータソース全体の品質変更を疑う
