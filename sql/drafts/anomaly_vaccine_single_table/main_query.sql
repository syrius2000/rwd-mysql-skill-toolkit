-- Anomaly detection input for VACCINE single-table smoke test.
-- Grain: one row per CH_t05_covid_vaccine record.
-- PHI/PII policy: PATIENTNO is hashed; raw patient identifiers are not selected.

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
FROM CH_t05_covid_vaccine;
