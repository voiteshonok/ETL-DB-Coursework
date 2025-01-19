-- Monthly Sales Trend in OLAP Database
SELECT 
    TO_CHAR(d.Date, 'YYYY-MM') AS Month, 
    SUM(f.TotalAmount) AS TotalSalesAmount
FROM FactSales f
JOIN DimDate d ON f.DateKey = d.DateKey
WHERE d.Date >= '2023-01-01'  
GROUP BY TO_CHAR(d.Date, 'YYYY-MM')
ORDER BY Month;
