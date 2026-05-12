-- Ιατροί ανά ειδικότητα
SELECT 
    dep.name AS 'Τμήμα',
    sh.shift_date AS 'Ημερομηνία',
    sh.shift_type AS 'Βάρδια',
    'Ιατρός' AS 'Κατηγορία',
    d.specialty AS 'Υποκατηγορία',
    COUNT(ss.staff_id) AS 'Αριθμός Προσωπικού'
FROM Shifts sh
JOIN Departments dep ON sh.department_id = dep.id
JOIN Staff_Shifts ss ON ss.shift_id = sh.id
JOIN Doctors d ON d.staff_id = ss.staff_id
WHERE sh.shift_date BETWEEN '2026-05-04' AND '2026-05-10'
GROUP BY dep.name, sh.shift_date, sh.shift_type, d.specialty

UNION ALL

-- Νοσηλευτές ανά βαθμίδα
SELECT 
    dep.name,
    sh.shift_date,
    sh.shift_type,
    'Νοσηλευτής',
    n.rank,
    COUNT(ss.staff_id)
FROM Shifts sh
JOIN Departments dep ON sh.department_id = dep.id
JOIN Staff_Shifts ss ON ss.shift_id = sh.id
JOIN Nurses n ON n.staff_id = ss.staff_id
WHERE sh.shift_date BETWEEN '2026-05-04' AND '2026-05-10'
GROUP BY dep.name, sh.shift_date, sh.shift_type, n.rank

UNION ALL

-- Διοικητικό προσωπικό ανά ρόλο
SELECT 
    dep.name,
    sh.shift_date,
    sh.shift_type,
    'Διοικητικό προσωπικό',
    a.duty_role,
    COUNT(ss.staff_id)
FROM Shifts sh
JOIN Departments dep ON sh.department_id = dep.id
JOIN Staff_Shifts ss ON ss.shift_id = sh.id
JOIN Administrative_Staff a ON a.staff_id = ss.staff_id
WHERE sh.shift_date BETWEEN '2026-05-04' AND '2026-05-10'
GROUP BY dep.name, sh.shift_date, sh.shift_type, a.duty_role

ORDER BY Ημερομηνία, Τμήμα, Βάρδια, Κατηγορία, Υποκατηγορία;

