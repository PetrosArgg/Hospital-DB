WITH prescriptioned_substances AS (
    SELECT 
        p.hospitalization_id,
        p.patient_id,
        ms.substance_id,
        s.substance_name
    FROM Prescriptions p
    JOIN Medication_Substances ms ON p.medication_id = ms.medication_id
    JOIN Active_Substances s ON ms.substance_id = s.id
)
SELECT
    ps1.substance_name AS substance_1,
    ps2.substance_name AS substance_2,
    COUNT(*) AS frequency
FROM prescriptioned_substances ps1 JOIN prescriptioned_substances ps2
ON ps1.hospitalization_id = ps2.hospitalization_id
AND ps1.patient_id = ps2.patient_id
AND ps1.substance_id < ps2.substance_id
GROUP BY
    ps1.substance_id, ps1.substance_name, ps2.substance_id, ps2.substance_name
ORDER BY frequency DESC
LIMIT 3;