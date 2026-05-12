WITH urgency_statistics AS
(
    SELECT
        urgency_level,
        COUNT(*) AS total_cases,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, arrival_time, service_time)), 1) AS avg_wait_minutes,
        ROUND(100.0 * SUM(CASE WHEN referral_status = 'Hospitalization' THEN 1 ELSE 0 END)/COUNT(*), 2) AS hosp_percentage
    FROM Triage_Entries
    GROUP BY urgency_level
)
SELECT
    us.urgency_level AS 'Επίπεδο Επείγοντος',
    us.total_cases AS 'Σύνολο Περιστατικών',
    us.avg_wait_minutes AS 'Μέσος Χρόνος Αναμονής (σε λεπτά)',
    us.hosp_percentage AS 'Ποσοστό Νοσηλείας',
    CASE WHEN d.name IS NULL THEN 'Χωρίς παραπομπή' ELSE d.name END AS 'Τμήμα Παραπομπής',
    COUNT(h.id) AS 'Παραπομπές σε τμήμα'
FROM Triage_Entries te
JOIN urgency_statistics us ON us.urgency_level = te.urgency_level
LEFT JOIN Hospitalizations h ON h.triage_id = te.id
LEFT JOIN Departments d ON d.id = h.department_id
GROUP BY us.urgency_level, us.total_cases, us.avg_wait_minutes, us.hosp_percentage, d.name
ORDER BY us.urgency_level, d.name;