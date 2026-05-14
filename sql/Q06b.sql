EXPLAIN ANALYZE
SELECT
    h.id AS hospitalization_id,
    h.entry_date,
    h.exit_date,
    DATEDIFF(h.exit_date, h.entry_date) AS days_stayed,
    h.icd10_entry_code,
    icd_entry.description AS entry_diagnosis,
    h.icd10_exit_code,
    icd_exit.description AS exit_diagnosis,
    h.total_cost,
    ROUND(
        (hr.nursing_care_quality +
         hr.cleanliness +
         hr.food_quality +
         hr.overall_experience) / 4.0, 2) AS avg_hospitalization_rating,
    ROUND(AVG(dr.medical_care_quality), 2) AS avg_doctor_rating
FROM Hospitalizations h FORCE INDEX (idx_hosp_patient)
LEFT JOIN ICD10_Ref icd_entry ON h.icd10_entry_code = icd_entry.code
LEFT JOIN ICD10_Ref icd_exit ON h.icd10_exit_code  = icd_exit.code
LEFT JOIN Hospitalization_Ratings hr FORCE INDEX (idx_hosprat_hosp) ON h.id = hr.hospitalization_id
LEFT JOIN Doctor_Ratings dr FORCE INDEX (idx_docrat_hosp) ON h.id = dr.hospitalization_id
WHERE h.patient_id = 1
GROUP BY
    h.id, h.entry_date, h.exit_date,
    h.icd10_entry_code, icd_entry.description,
    h.icd10_exit_code, icd_exit.description,
    h.total_cost,
    hr.nursing_care_quality, hr.cleanliness,
    hr.food_quality, hr.overall_experience
ORDER BY h.entry_date ASC;
