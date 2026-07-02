# anomaly-detection: VACCINE 複数テーブル整合性テスト

VACCINE DB の `CH_t05_covid_vaccine`、`CH_t01_demo`、`CH_t11_covid_test`、`CH_t13_outcome_severity` を結合し、`.agent/skills/anomaly-detection/` で整合性由来の異常候補を検出してください。

目的:
- 患者、接種、検査、アウトカムの join 後データで異常検知を行う
- 重複、欠損、日付矛盾、施設差、数値外れ値、未解決 query 相当の列をレビュー対象にする

手順:
1. `VACCINE` DB の join key 候補と粒度を確認する
2. `sql/drafts/anomaly_vaccine_multi_table/` の SQL を使って抽出する
3. 抽出結果を `skill_out/anomaly_detection/vaccine_multi_table/input.csv` に保存する
4. `.agent/skills/anomaly-detection/scripts/infer.py` を実行する
5. 結果を `skill_out/anomaly_detection/vaccine_multi_table/review_note.md` に日本語で要約する

レビュー文書の書き方:
- 冒頭に「まず結論」を置き、専門外の人にも分かる言葉で書く
- `robust_mad`, `iforest`, `duplicate_entity_key` などの内部名は、必ず日本語の説明と一緒に出す
- 「異常確定」ではなく「人が確認する順番を作る結果」と明記する
- どのテーブルを何のために使ったかを表で示す
- record_id は患者番号ではなく、変換済み識別子だと説明する

粒度:
- 1行 = 1患者 x 1接種イベント
- join によって行数が増える場合は、validation query で原因を確認する

制約:
- PHI/PII を出力しない
- `PATIENTNO` は SHA2 hash 化した `subject_id` として扱う
- join 前後の `COUNT(*)` と `COUNT(DISTINCT subject_id)` を必ず比較する
- 異常確定ではなくレビュー優先順位付けとして記述する
