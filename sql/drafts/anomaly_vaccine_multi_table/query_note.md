# anomaly_vaccine_multi_table query note

## 目的

`CH_t05_covid_vaccine` を主テーブルに、患者基本情報、COVID検査、アウトカムを患者単位で集約結合し、複数テーブル整合性を含む anomaly-detection 入力を作成する。

## 粒度

1行 = `CH_t05_covid_vaccine` の1接種イベント相当レコード。

## 入力テーブル

- `CH_t05_covid_vaccine`: 主テーブル
- `CH_t01_demo`: 生年月日から接種時年齢を算出
- `CH_t11_covid_test`: 患者単位の COVID 検査件数と基準外件数
- `CH_t13_outcome_severity`: 患者単位のアウトカム件数と死亡フラグ件数

## ID とプライバシー

- `PATIENTNO` は raw 値を出力せず、`SHA2(PATIENTNO, 256)` を `subject_id` とする。
- `record_id` は `PATIENTNO`, `EVENTDATE`, `DEPARTMENTCODE`, `更新日時` を組み合わせて hash 化する。

## 列マッピング

- `site_id`: `CH_t05_covid_vaccine.DEPARTMENTCODE`
- `visit_date`: `CH_t05_covid_vaccine.EVENTDATE`
- `recorded_at`: `CH_t05_covid_vaccine.更新日時`
- `age`: `CH_t01_demo.BIRTHDAY` から接種時年齢を算出
- `lab_value`: COVID 検査件数、アウトカム件数、接種日入力数の合計
- `is_query_open`: 基本情報欠損、日付矛盾、基準外検査、死亡フラグのいずれか

## 既知の制約

- `lab_value` は臨床検査値そのものではなく、複数テーブル由来のイベント量を表すレビュー用特徴量。
- `is_query_open` は実 EDC query ではなく、レビュー優先度を上げるための整合性シグナル。
- COVID 検査とアウトカムは患者単位集約のため、接種イベントとの時間的前後関係はこの SQL では限定していない。
