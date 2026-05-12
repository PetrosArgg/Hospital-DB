WITH RECURSIVE supervision_hierarchy (level, doctor_id, supervisor_id) AS 
(
    SELECT 1, d.staff_id, d.supervisor_id
    FROM Doctors d
    WHERE d.supervisor_id IS NOT NULL
    UNION ALL
    SELECT sh.level + 1, sh.doctor_id, d.supervisor_id
    FROM Doctors d
    INNER JOIN supervision_hierarchy sh ON d.staff_id = sh.supervisor_id
    WHERE d.supervisor_id IS NOT NULL
)
SELECT 
    s_doc.last_name AS 'Επώνυμο Ιατρού',
    s_doc.first_name AS 'Όνομα Ιατρού',
    d_doc.rank AS 'Βαθμίδα Ιατρού',
    level AS 'Επίπεδο Εποπτείας',
    s_sup.last_name AS 'Επώνυμο Επόπτη',
    s_sup.first_name AS 'Όνομα Επόπτη',
    d_sup.rank AS 'Βαθμίδα Επόπτη'
FROM supervision_hierarchy sh
JOIN Doctors d_doc ON d_doc.staff_id = sh.doctor_id
JOIN Staff s_doc ON s_doc.id = sh.doctor_id
JOIN Doctors d_sup ON d_sup.staff_id = sh.supervisor_id
JOIN Staff s_sup ON s_sup.id = sh.supervisor_id
ORDER BY doctor_id, level;
