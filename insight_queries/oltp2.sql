-- Monthly Sales Trend in OLTP Database
SELECT 
    TO_CHAR(o.OrderDate, 'YYYY-MM') AS Month,  
    SUM(od.Quantity * od.Price) AS TotalSalesAmount
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderDate >= '2023-01-01'  
GROUP BY TO_CHAR(o.OrderDate, 'YYYY-MM')
ORDER BY Month;
