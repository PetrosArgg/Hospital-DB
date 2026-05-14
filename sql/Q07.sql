SELECT 
    s.id AS substance_id,
    substance_name,
    COUNT(DISTINCT p.patient_id) AS num_allergic_patients,
    COUNT(DISTINCT m.medication_id) AS num_medications_containing
FROM Active_Substances s
LEFT JOIN Patient_Allergies p ON s.id = p.substance_id
LEFT JOIN Medication_Substances m ON s.id = m.substance_id
GROUP BY
    s.id, s.substance_name
ORDER BY num_allergic_patients DESC;