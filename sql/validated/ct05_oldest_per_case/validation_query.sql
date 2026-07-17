-- Validation SQL for ct05_oldest_per_case/main_query.sql
-- Run before moving to sql/validated/

-- 1. 探索: 元テーブルの概要
SELECT
    COUNT(*) AS n_rows,
    COUNT(DISTINCT PATIENTNO) AS n_patients,
    SUM(CASE WHEN PATIENTNO IS NULL THEN 1 ELSE 0 END) AS n_missing_patient_id,
    MIN(EVENTDATE) AS min_eventdate,
    MAX(EVENTDATE) AS max_eventdate,
    MIN(`更新日時`) AS min_updated_at,
    MAX(`更新日時`) AS max_updated_at
FROM CH_t05_covid_vaccine;

-- 2. 探索: 症例あたりレコード数の分布
SELECT
    n_per_patient,
    COUNT(*) AS n_patients
FROM (
    SELECT PATIENTNO, COUNT(*) AS n_per_patient
    FROM CH_t05_covid_vaccine
    WHERE PATIENTNO IS NOT NULL
    GROUP BY PATIENTNO
) AS per_patient
GROUP BY n_per_patient
ORDER BY n_per_patient DESC
LIMIT 20;

-- 3. 本 SQL 結果の件数・ID・日付レンジ
WITH result AS (
    WITH ranked AS (
        SELECT
            v.*,
            ROW_NUMBER() OVER (
                PARTITION BY v.PATIENTNO
                ORDER BY
                    v.EVENTDATE ASC,
                    v.`更新日時` ASC,
                    v.DEPARTMENTCODE ASC
            ) AS rn
        FROM CH_t05_covid_vaccine AS v
        WHERE v.PATIENTNO IS NOT NULL
    )
    SELECT *
    FROM ranked
    WHERE rn = 1
)
SELECT
    COUNT(*) AS n_rows,
    COUNT(DISTINCT PATIENTNO) AS n_patients,
    SUM(CASE WHEN PATIENTNO IS NULL THEN 1 ELSE 0 END) AS n_missing_patient_id,
    MIN(EVENTDATE) AS min_eventdate,
    MAX(EVENTDATE) AS max_eventdate
FROM result;

-- 4. 重複チェック: 症例 ID が一意か
WITH result AS (
    WITH ranked AS (
        SELECT
            v.*,
            ROW_NUMBER() OVER (
                PARTITION BY v.PATIENTNO
                ORDER BY
                    v.EVENTDATE ASC,
                    v.`更新日時` ASC,
                    v.DEPARTMENTCODE ASC
            ) AS rn
        FROM CH_t05_covid_vaccine AS v
        WHERE v.PATIENTNO IS NOT NULL
    )
    SELECT PATIENTNO
    FROM ranked
    WHERE rn = 1
)
SELECT
    PATIENTNO,
    COUNT(*) AS n
FROM result
GROUP BY PATIENTNO
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 50;

-- 5. 同時刻タイの確認: 最古 EVENTDATE が症例内で複数行あるケース
SELECT
    PATIENTNO,
    EVENTDATE,
    COUNT(*) AS n
FROM CH_t05_covid_vaccine
WHERE PATIENTNO IS NOT NULL
GROUP BY PATIENTNO, EVENTDATE
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 20;
