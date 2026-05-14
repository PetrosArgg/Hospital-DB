SELECT 
    d.name AS Department,
    YEAR(h.entry_date) AS Year,
    k.code AS KEN_Code,
    p.insurance_provider AS Provider,
    COUNT(h.id) AS Total_Hospitalizations,
    SUM(k.base_cost) AS Base_Revenue,
    SUM(CASE 
        WHEN DATEDIFF(h.exit_date, h.entry_date) > k.mdn_days 
        THEN (DATEDIFF(h.exit_date, h.entry_date) - k.mdn_days) * (k.base_cost / k.mdn_days)
        ELSE 0 
    END) AS Extra_Revenue,
    SUM(h.total_cost) AS Total_Revenue

FROM 
    Hospitalizations h
JOIN 
    Departments d ON h.department_id = d.id
JOIN 
    KEN_Ref k ON h.ken_code = k.code
JOIN 
    Patients p ON h.patient_id = p.id

GROUP BY 
    d.name, 
    YEAR(h.entry_date), 
    k.code, 
    p.insurance_provider

ORDER BY 
    Year DESC,
    Department ASC, 
    KEN_Code ASC;