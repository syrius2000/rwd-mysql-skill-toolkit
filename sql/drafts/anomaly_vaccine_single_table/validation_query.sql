-- Validation checks for anomaly_vaccine_single_table/main_query.sql.

WITH extracted_dataset AS (
  SELECT
    CONCAT(
      'covid_vaccine:',
      SHA2(CONCAT_WS('|', PATIENTNO, EVENTDATE, DEPARTMENTCODE, `更新日時`), 256)
    ) AS record_id,
    'VACCINE' AS study_id,
    COALESCE(NULLIF(DEPARTMENTCODE, ''), 'UNKNOWN_SITE') AS site_id,
    SHA2(PATIENTNO, 256) AS subject_id,
    'CH_t05_covid_vaccine' AS form_name,
    DATE(EVENTDATE) AS visit_date,
    DATE(`更新日時`) AS recorded_at,
    CAST(NULL AS DECIMAL(10, 2)) AS age,
    CAST(NULL AS DECIMAL(10, 2)) AS sbp,
    CAST(NULL AS DECIMAL(10, 2)) AS dbp,
    (
      (`接種日1回目` IS NOT NULL AND `接種日1回目` <> '') +
      (`接種日2回目` IS NOT NULL AND `接種日2回目` <> '') +
      (`接種日3回目` IS NOT NULL AND `接種日3回目` <> '') +
      (`接種日4回目` IS NOT NULL AND `接種日4回目` <> '') +
      (`接種日5回目` IS NOT NULL AND `接種日5回目` <> '')
    ) AS lab_value,
    (
      (`日付不明1回目` IS NOT NULL AND `日付不明1回目` NOT IN ('', '0')) OR
      (`日付不明2回目` IS NOT NULL AND `日付不明2回目` NOT IN ('', '0')) OR
      (`日付不明3回目` IS NOT NULL AND `日付不明3回目` NOT IN ('', '0')) OR
      (`日付不明4回目` IS NOT NULL AND `日付不明4回目` NOT IN ('', '0')) OR
      (`日付不明5回目` IS NOT NULL AND `日付不明5回目` NOT IN ('', '0'))
    ) AS is_query_open
  FROM CH_t05_covid_vaccine
)
SELECT
  COUNT(*) AS n_rows,
  COUNT(DISTINCT record_id) AS n_record_ids,
  COUNT(DISTINCT subject_id) AS n_subjects,
  SUM(record_id IS NULL) AS missing_record_id,
  SUM(subject_id IS NULL) AS missing_subject_id,
  SUM(visit_date IS NULL) AS missing_visit_date,
  SUM(recorded_at IS NULL) AS missing_recorded_at,
  SUM(recorded_at < visit_date) AS temporal_inconsistency_rows,
  MIN(visit_date) AS min_visit_date,
  MAX(visit_date) AS max_visit_date,
  MIN(recorded_at) AS min_recorded_at,
  MAX(recorded_at) AS max_recorded_at,
  MIN(lab_value) AS min_lab_value,
  MAX(lab_value) AS max_lab_value
FROM extracted_dataset;

WITH extracted_dataset AS (
  SELECT
    CONCAT(
      'covid_vaccine:',
      SHA2(CONCAT_WS('|', PATIENTNO, EVENTDATE, DEPARTMENTCODE, `更新日時`), 256)
    ) AS record_id,
    'VACCINE' AS study_id,
    COALESCE(NULLIF(DEPARTMENTCODE, ''), 'UNKNOWN_SITE') AS site_id,
    SHA2(PATIENTNO, 256) AS subject_id,
    'CH_t05_covid_vaccine' AS form_name,
    DATE(EVENTDATE) AS visit_date
  FROM CH_t05_covid_vaccine
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
