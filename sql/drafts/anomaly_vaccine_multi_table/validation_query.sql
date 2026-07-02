-- Validation checks for anomaly_vaccine_multi_table/main_query.sql.

WITH test_summary AS (
  SELECT
    PATIENTNO,
    COUNT(*) AS covid_test_count,
    SUM(OUTOFSTANDARD IS NOT NULL AND OUTOFSTANDARD NOT IN ('', '0')) AS out_of_standard_count
  FROM CH_t11_covid_test
  GROUP BY PATIENTNO
),
outcome_summary AS (
  SELECT
    PATIENTNO,
    COUNT(*) AS outcome_count,
    SUM(SHIBOU IS NOT NULL AND SHIBOU NOT IN ('', '0')) AS death_flag_count
  FROM CH_t13_outcome_severity
  GROUP BY PATIENTNO
),
extracted_dataset AS (
  SELECT
    CONCAT(
      'covid_vaccine_multi:',
      SHA2(CONCAT_WS('|', v.PATIENTNO, v.EVENTDATE, v.DEPARTMENTCODE, v.`更新日時`), 256)
    ) AS record_id,
    'VACCINE' AS study_id,
    COALESCE(NULLIF(v.DEPARTMENTCODE, ''), 'UNKNOWN_SITE') AS site_id,
    SHA2(v.PATIENTNO, 256) AS subject_id,
    'CH_t05_covid_vaccine+demo+test+outcome' AS form_name,
    DATE(v.EVENTDATE) AS visit_date,
    DATE(v.`更新日時`) AS recorded_at,
    TIMESTAMPDIFF(YEAR, d.BIRTHDAY, DATE(v.EVENTDATE)) AS age,
    CAST(NULL AS DECIMAL(10, 2)) AS sbp,
    CAST(NULL AS DECIMAL(10, 2)) AS dbp,
    (
      COALESCE(ts.covid_test_count, 0) +
      COALESCE(os.outcome_count, 0) +
      (
        (v.`接種日1回目` IS NOT NULL AND v.`接種日1回目` <> '') +
        (v.`接種日2回目` IS NOT NULL AND v.`接種日2回目` <> '') +
        (v.`接種日3回目` IS NOT NULL AND v.`接種日3回目` <> '') +
        (v.`接種日4回目` IS NOT NULL AND v.`接種日4回目` <> '') +
        (v.`接種日5回目` IS NOT NULL AND v.`接種日5回目` <> '')
      )
    ) AS lab_value,
    (
      d.PATIENTNO IS NULL OR
      DATE(v.`更新日時`) < DATE(v.EVENTDATE) OR
      COALESCE(ts.out_of_standard_count, 0) > 0 OR
      COALESCE(os.death_flag_count, 0) > 0
    ) AS is_query_open
  FROM CH_t05_covid_vaccine v
  LEFT JOIN CH_t01_demo d
    ON d.PATIENTNO = v.PATIENTNO
  LEFT JOIN test_summary ts
    ON ts.PATIENTNO = v.PATIENTNO
  LEFT JOIN outcome_summary os
    ON os.PATIENTNO = v.PATIENTNO
)
SELECT
  COUNT(*) AS n_rows,
  COUNT(DISTINCT record_id) AS n_record_ids,
  COUNT(DISTINCT subject_id) AS n_subjects,
  SUM(record_id IS NULL) AS missing_record_id,
  SUM(subject_id IS NULL) AS missing_subject_id,
  SUM(age IS NULL) AS missing_age,
  SUM(age < 0) AS negative_age,
  SUM(age > 120) AS implausible_age_high,
  SUM(recorded_at < visit_date) AS temporal_inconsistency_rows,
  MIN(visit_date) AS min_visit_date,
  MAX(visit_date) AS max_visit_date,
  MIN(recorded_at) AS min_recorded_at,
  MAX(recorded_at) AS max_recorded_at,
  MIN(age) AS min_age,
  MAX(age) AS max_age,
  MIN(lab_value) AS min_lab_value,
  MAX(lab_value) AS max_lab_value
FROM extracted_dataset;

WITH test_summary AS (
  SELECT PATIENTNO, COUNT(*) AS covid_test_count
  FROM CH_t11_covid_test
  GROUP BY PATIENTNO
),
outcome_summary AS (
  SELECT PATIENTNO, COUNT(*) AS outcome_count
  FROM CH_t13_outcome_severity
  GROUP BY PATIENTNO
),
extracted_dataset AS (
  SELECT
    CONCAT(
      'covid_vaccine_multi:',
      SHA2(CONCAT_WS('|', v.PATIENTNO, v.EVENTDATE, v.DEPARTMENTCODE, v.`更新日時`), 256)
    ) AS record_id,
    'VACCINE' AS study_id,
    COALESCE(NULLIF(v.DEPARTMENTCODE, ''), 'UNKNOWN_SITE') AS site_id,
    SHA2(v.PATIENTNO, 256) AS subject_id,
    'CH_t05_covid_vaccine+demo+test+outcome' AS form_name,
    DATE(v.EVENTDATE) AS visit_date
  FROM CH_t05_covid_vaccine v
  LEFT JOIN CH_t01_demo d
    ON d.PATIENTNO = v.PATIENTNO
  LEFT JOIN test_summary ts
    ON ts.PATIENTNO = v.PATIENTNO
  LEFT JOIN outcome_summary os
    ON os.PATIENTNO = v.PATIENTNO
)
SELECT
  study_id,
  site_id,
  subject_id,
  visit_date,
  form_name,
  COUNT(*) AS n
FROM extracted_dataset
GROUP BY study_id, site_id, subject_id, visit_date, form_name
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 20;
