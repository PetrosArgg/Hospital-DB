SELECT 
    s.last_name AS 'Επώνυμο',
    s.first_name AS 'Όνομα',
    TIMESTAMPDIFF(YEAR, s.birth_date, CURDATE()) AS 'Ηλικία',
    COUNT(ma.id) AS 'Πλήθος Χειρουργείων'
FROM Medical_Acts ma
JOIN MedicalAct_Ref mar ON ma.act_code = mar.code
JOIN Staff s ON ma.main_doctor_id = s.id
WHERE 
    mar.category = 'Χειρουργική' 
    AND TIMESTAMPDIFF(YEAR, s.birth_date, CURDATE()) < 35
GROUP BY s.id, s.last_name, s.first_name, s.birth_date
ORDER BY COUNT(ma.id) DESC;
