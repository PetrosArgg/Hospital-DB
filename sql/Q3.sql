SELECT 
    p.last_name AS Επώνυμο_Ασθενή, 
    p.first_name AS Όνομα_Ασθενή,
    d.name AS Τμήμα, 
    SUM(COALESCE(h.total_cost, 0)) AS Συνολικό_Κόστος
FROM Hospitalizations h
JOIN Patients p ON h.patient_id = p.id
JOIN Departments d ON h.department_id = d.id
GROUP BY p.id, d.id, p.last_name, p.first_name, d.name
HAVING COUNT(*) > 3
ORDER BY Συνολικό_Κόστος DESC;