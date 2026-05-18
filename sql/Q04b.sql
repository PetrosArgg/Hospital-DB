-- Τα αποτελέσματα των ANALYZE FORMAT=JSON και η σύγκριση 
-- κόστους/χρόνου βρίσκονται αναλυτικά στο docs/report.pdf
-- ANALYZE FORMAT=JSON
SELECT 
    s.last_name AS 'Επώνυμο Ιατρού',
    s.first_name AS 'Όνομα Ιατρού',
    AVG(dr.medical_care_quality) AS 'Μέση Ποιότητα Ιατρικής Φροντίδας',
    AVG(hr.overall_experience) AS 'Μέση Συνολική Εντύπωση Νοσηλείας'
FROM Doctor_Ratings dr FORCE INDEX (idx_docrat_doctor)
LEFT JOIN Hospitalization_Ratings hr FORCE INDEX (idx_hosprat_hosp) ON dr.hospitalization_id = hr.hospitalization_id
JOIN Staff s FORCE INDEX (PRIMARY) ON dr.doctor_id = s.id
WHERE dr.doctor_id = 2 
GROUP BY dr.doctor_id, s.last_name, s.first_name;
