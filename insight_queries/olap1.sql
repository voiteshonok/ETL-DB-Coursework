-- Total Sales per Product and Customer in OLAP Database
WITH ValidDate  as (
	SELECT DateKey FROM DimDate WHERE Date >= '2024-01-01'
)
SELECT 
    ProductID,
    CustomerID,
    SUM(TotalAmount) AS TotalSalesAmount
FROM FactSales f, ValidDate v
WHERE f.DateKey = v.DateKey  
GROUP BY ProductID, CustomerID
ORDER BY TotalSalesAmount DESC; 
