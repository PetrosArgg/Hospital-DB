SELECT 
    s.last_name AS 'Επώνυμο',
    s.first_name AS 'Όνομα',
    d.specialty AS 'Ειδικότητα',
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Staff_Shifts ss 
            JOIN Shifts sh ON ss.shift_id = sh.id 
            WHERE ss.staff_id = d.staff_id 
              AND YEAR(sh.shift_date) = YEAR(CURDATE())
        ) THEN 'ΝΑΙ' 
        ELSE 'ΟΧΙ' 
    END AS 'Εφημερία Τρέχον Έτος',
    (
        SELECT COUNT(*) 
        FROM Medical_Acts ma 
        WHERE ma.main_doctor_id = d.staff_id
    ) AS 'Πλήθος Επεμβάσεων (Κύριος Χειρουργός)'
FROM Doctors d
JOIN Staff s ON d.staff_id = s.id
WHERE d.specialty = 'Χειρουργική'
ORDER BY s.last_name, s.first_name;