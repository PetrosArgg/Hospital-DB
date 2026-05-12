SELECT
    d.staff_id AS 'ID Ιατρου',
    s. last_name AS 'Επώνυμο',
    s.first_name AS 'Όνομα',
    d.specialty AS 'Ειδικότητα',
    d.rank AS 'Βαθμίδα',
    COUNT(ma.id) AS 'Επεμβάσεις Τρέχον Έτος'
FROM Doctors d
JOIN Staff s ON d.staff_id = s.id
LEFT JOIN Medical_Acts ma
    ON ma.main_doctor_id = d.staff_id
    AND YEAR(ma.scheduled_time) = YEAR(CURDATE())
GROUP BY d.staff_id, s.last_name, s.first_name, d.specialty, d.rank
HAVING COUNT(ma.id) <= (
    SELECT COUNT(id)
    FROM Medical_Acts
    WHERE YEAR(scheduled_time) = YEAR(CURDATE())
    GROUP BY main_doctor_id
    ORDER BY COUNT(id) DESC
    LIMIT 1       
) -5
ORDER BY COUNT(ma.id) DESC, s.last_name;


  