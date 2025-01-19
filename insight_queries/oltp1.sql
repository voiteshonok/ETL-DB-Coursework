-- Total Sales per Product and Customer in OLTP Database
SELECT 
    od.ProductID,
    o.CustomerID,
    SUM(od.Quantity * od.Price) AS TotalSalesAmount
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderDate >= '2024-01-01' 
GROUP BY od.ProductID, o.CustomerID
ORDER BY TotalSalesAmount DESC;
