WITH patient_yearly_hospitalized AS (
    SELECT
        h.patient_id,
        YEAR(h.entry_date) AS stay_year,
        SUM(DATEDIFF(COALESCE(h.exit_date, CURDATE()), h.entry_date)) AS total_days
        FROM Hospitalizations h
        GROUP BY
            h.patient_id,
            YEAR(h.entry_date)
        HAVING total_days > 15
)
SELECT 
    p1.patient_id AS patient1_id,
    s1.first_name AS patient1_first_name,
    s1.last_name AS patient1_last_name,
    p2.patient_id AS patient2_id,
    s2.first_name AS patient2_first_name,
    s2.last_name AS patient2_last_name,
    p1.total_days,
    p1.stay_year
FROM patient_yearly_hospitalized p1 JOIN patient_yearly_hospitalized p2
ON p1.total_days = p2.total_days
    AND p1.stay_year = p2.stay_year
    AND p1.patient_id < p2.patient_id
JOIN Patients s1 ON p1.patient_id = s1.id
JOIN Patients s2 ON p2.patient_id = s2.id
ORDER BY p1.stay_year, p1.total_days;