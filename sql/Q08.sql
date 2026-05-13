SELECT
    s.id AS staff_id,
    s.amka,
    s.first_name,
    s.last_name,
    s.staff_type,
    s.birth_date,
    TIMESTAMPDIFF(YEAR, s.birth_date, CURDATE()) AS age,
    s.email,
    s.phone,
    s.hire_date,
    d.license_number,
    d.specialty,
    d.rank AS doctor_rank,
    d.supervisor_id,
    n.rank AS nurse_rank,
    a.duty_role,
    a.office_location,
    CASE s.staff_type
        WHEN 'doctor' THEN
            (SELECT GROUP_CONCAT(dep.name SEPARATOR ', ')
             FROM   Doctor_Departments dd
             JOIN   Departments dep ON dd.department_id = dep.id
             WHERE  dd.doctor_id = s.id)
        WHEN 'nurse' THEN
            (SELECT dep.name FROM Departments dep
             WHERE  dep.id = n.department_id)
        WHEN 'admin' THEN
            (SELECT dep.name FROM Departments dep
             WHERE  dep.id = a.department_id)
    END AS belongs_to_departments
FROM Staff s
LEFT JOIN Doctors d ON s.id = d.staff_id
LEFT JOIN Nurses n ON s.id = n.staff_id
LEFT JOIN Administrative_Staff a ON s.id = a.staff_id
JOIN Departments dep ON dep.name = '...'
WHERE s.active = TRUE
    AND (
        EXISTS (SELECT 1 FROM Doctor_Departments dd
                    WHERE dd.doctor_id = s.id AND dd.department_id = dep.id)
         OR (n.department_id = dep.id)
         OR (a.department_id = dep.id)
         )
    AND s.id NOT IN (
        SELECT ss.staff_id
        FROM Staff_Shifts ss
        JOIN Shifts sh ON ss.shift_id = sh.id
        WHERE sh.shift_date = '2026-05-01' AND sh.department_id = dep.id
    )
ORDER BY s.staff_type, s.last_name, s.first_name;