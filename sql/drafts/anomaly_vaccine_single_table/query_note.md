# anomaly_vaccine_single_table query note

## 目的

`CH_t05_covid_vaccine` 単一テーブルから、anomaly-detection Skill の標準入力列に近い CSV を作成し、実データ由来のスモークテストを行う。

## 粒度

1行 = `CH_t05_covid_vaccine` の1レコード。

## 入力テーブル

- `CH_t05_covid_vaccine`

## ID とプライバシー

- `PATIENTNO` は raw 値を出力せず、`SHA2(PATIENTNO, 256)` を `subject_id` とする。
- `record_id` は `PATIENTNO`, `EVENTDATE`, `DEPARTMENTCODE`, `更新日時` を組み合わせて hash 化する。

## 列マッピング

- `site_id`: `DEPARTMENTCODE`
- `visit_date`: `EVENTDATE`
- `recorded_at`: `更新日時`
- `lab_value`: 1回目から5回目までの接種日入力数
- `is_query_open`: 日付不明フラグのいずれかが立っている場合

## 既知の制約

- 単一テーブルでは年齢、血圧、検査値は取得しない。
- 日付不明フラグは EDC query そのものではなく、レビュー対象信号として `is_query_open` に写像する。
