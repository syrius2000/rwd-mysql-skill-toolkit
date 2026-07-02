# anomaly-detection: VACCINE 1テーブルスモークテスト

VACCINE DB の `CH_t05_covid_vaccine` を使い、`.agent/skills/anomaly-detection/` の動作確認をしてください。

目的:
- 実データ由来 CSV で異常検知 CLI が動くことを確認する
- 必須欠損、重複キー、日付矛盾、数値外れ値候補をレビューキューとして出す

手順:
1. `VACCINE` DB の `CH_t05_covid_vaccine` の行数、日付範囲、ID 欠損を確認する
2. `sql/drafts/anomaly_vaccine_single_table/` の SQL を使って抽出する
3. 抽出結果を `skill_out/anomaly_detection/vaccine_single_table/input.csv` に保存する
4. `.agent/skills/anomaly-detection/scripts/infer.py` を実行する
5. 結果を `skill_out/anomaly_detection/vaccine_single_table/review_note.md` に日本語で要約する

レビュー文書の書き方:
- 冒頭に「まず結論」を置き、専門外の人にも分かる言葉で書く
- `duplicate_entity_key` などの内部名は、必ず日本語の説明と一緒に出す
- 「異常確定」ではなく「人が確認する順番を作る結果」と明記する
- 表は `何が起きたか`, `件数`, `次に見ること` が分かる形にする
- record_id は患者番号ではなく、変換済み識別子だと説明する

入力 CSV の列名:
- `record_id`
- `study_id`
- `site_id`
- `subject_id`
- `form_name`
- `visit_date`
- `recorded_at`
- `age`
- `sbp`
- `dbp`
- `lab_value`
- `is_query_open`

制約:
- PHI/PII を出力しない
- `PATIENTNO` は SHA2 hash 化した `subject_id` として扱う
- 異常確定ではなくレビュー優先順位付けとして記述する
