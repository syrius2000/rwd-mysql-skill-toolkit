-- Purpose: Ct05 (CH_t05_covid_vaccine) から、各症例（PATIENTNO）の最古レコードを1行ずつ抽出する。
-- Grain: one row per PATIENTNO (症例単位)。
-- Main ID: PATIENTNO。
-- Date policy: 期間未指定。最古判定は EVENTDATE 昇順、同値時は 更新日時 → DEPARTMENTCODE でタイブレーク。
-- DB: VACCINE

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
    WHERE v.PATIENTNO IS NOT NULL  -- 症例 ID 欠損を除外
)
SELECT
    PATIENTNO,
    DEPARTMENTCODE,
    DEPTNAME,
    EVENTDATE,
    `更新日時`,
    `問診1_過去2週間の曝露歴`,
    `問診2_濃厚接触者`,
    `問診3_症状の有無`,
    `問診4_家族_同僚症状の有無`,
    `問診5_接種歴`,
    `接種日1回目`,
    `日付不明1回目`,
    `年1回目`,
    `月1回目`,
    `接種日2回目`,
    `日付不明2回目`,
    `年2回目`,
    `月2回目`,
    `接種日3回目`,
    `日付不明3回目`,
    `年3回目`,
    `月3回目`,
    `接種日4回目`,
    `日付不明4回目`,
    `年4回目`,
    `月4回目`,
    `問診6_希望`,
    `接種日5回目`,
    `日付不明5回目`,
    `年5回目`,
    `月5回目`,
    `問診7_妊娠`
FROM ranked
WHERE rn = 1;
