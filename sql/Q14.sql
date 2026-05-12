WITH counts_per_year AS
(
    SELECT
        LEFT(h.icd10_entry_code, 3) AS icd_category,
        YEAR(h.entry_date) AS year,
        COUNT(*) AS admission_count
    FROM Hospitalizations h
    WHERE h.icd10_entry_code IS NOT NULL
    GROUP BY LEFT(h.icd10_entry_code, 3), YEAR(h.entry_date)
    HAVING COUNT(*) >= 5
)
SELECT 
    y1.icd_category AS 'Κατηγορία ICD-10',
    y1.year AS 'Έτος 1',
    y2.year AS 'Έτος 2',
    y1.admission_count AS 'Αριθμός εισαγωγών'
FROM counts_per_year y1
JOIN counts_per_year y2
    ON y1.icd_category = y2.icd_category
    AND y2.year = y1.year +1
    AND y1.admission_count = y2.admission_count
ORDER BY y1.icd_category, y1.year;