CREATE TABLE DimCustomer (
    CustomerID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(15),
    Address TEXT
);

CREATE TABLE DimCategory (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE DimDate (
    DateKey SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    Week INT,
    DayOfWeek INT
);


CREATE TABLE DimProduct (
    ProductID SERIAL PRIMARY KEY,
    ProductName VARCHAR(100),
    CategoryID INT,
    Price DECIMAL(10, 2),
    StockQuantity INT,
    Description TEXT,
    FOREIGN KEY (CategoryID) REFERENCES DimCategory(CategoryID)
);


CREATE TABLE FactSales (
    SaleID SERIAL PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    DateKey INT NOT NULL,
    Quantity INT NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);



-- Enable FDW extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create server connection to OLTP database
CREATE SERVER IF NOT EXISTS oltp_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'sport_oltp', port '5432');

-- Create a user mapping for accessing OLTP database
CREATE USER MAPPING IF NOT EXISTS FOR current_user
SERVER oltp_server
OPTIONS (
  user 'myuser',
  password 'mypassword'
);

-- Create a schema for storing foreign tables
CREATE SCHEMA IF NOT EXISTS fdw_oltp;

-- Import all tables from the OLTP schema into the fdw_oltp schema
IMPORT FOREIGN SCHEMA public
  FROM SERVER oltp_server
  INTO fdw_oltp;


-- Insert only missing categories from the original table
INSERT INTO DimCategory (CategoryName)
SELECT DISTINCT CategoryName
FROM fdw_oltp.Categories
WHERE NOT EXISTS (
    SELECT 1 
    FROM DimCategory 
    WHERE DimCategory.CategoryName = fdw_oltp.Categories.CategoryName
);  


WITH ValidProducts AS (
    SELECT DISTINCT ON (ProductName) 
        p.ProductID, p.ProductName, p.CategoryID, p.Price, p.StockQuantity, p.Description
    FROM fdw_oltp.Products p
    WHERE Price > 0 AND StockQuantity >= 0  
    ORDER BY p.ProductName, p.Price DESC
)
-- Insert into DimProduct, handling missing categories
INSERT INTO DimProduct (ProductName, CategoryID, Price, StockQuantity, Description)
SELECT p.ProductName, p.CategoryID, p.Price, p.StockQuantity, p.Description
FROM ValidProducts p
JOIN DimCategory d ON p.CategoryID = d.CategoryID
WHERE d.CategoryID IS NOT NULL;


WITH ValidCustomers AS (
    SELECT CustomerID, FirstName, LastName, Email, PhoneNumber, Address
    FROM fdw_oltp.Customers
    WHERE Email IS NOT NULL AND PhoneNumber IS NOT NULL
)
-- Insert into DimCustomer
INSERT INTO DimCustomer (CustomerID, FirstName, LastName, Email, PhoneNumber, Address)
SELECT CustomerID, FirstName, LastName, Email, PhoneNumber, Address
FROM ValidCustomers;


-- Validate date data (e.g., only insert dates from the last 12 months)
WITH ValidDates AS (
    SELECT DISTINCT OrderDate::DATE AS Date
    FROM fdw_oltp.Orders
    WHERE OrderDate >= CURRENT_DATE - INTERVAL '12 months'
)
INSERT INTO DimDate (Date, Year, Quarter, Month, Day, Week, DayOfWeek)
SELECT Date, 
       EXTRACT(YEAR FROM Date), 
       EXTRACT(QUARTER FROM Date), 
       EXTRACT(MONTH FROM Date), 
       EXTRACT(DAY FROM Date), 
       EXTRACT(WEEK FROM Date), 
       EXTRACT(DOW FROM Date)
FROM ValidDates;


WITH SalesSummary AS (
    SELECT
        od.ProductID,
        o.CustomerID,
        d.DateKey,
        SUM(od.Quantity) AS TotalQuantity,         
        SUM(od.Price * od.Quantity) AS TotalAmount  
    FROM fdw_oltp.OrderDetails od
    JOIN fdw_oltp.Orders o ON od.OrderID = o.OrderID  
    JOIN DimDate d ON o.OrderDate::DATE = d.Date  
    WHERE o.OrderDate >= '2020-01-01'  
    GROUP BY od.ProductID, o.CustomerID, d.DateKey
)

INSERT INTO FactSales (ProductID, CustomerID, DateKey, Quantity, TotalAmount)
SELECT ProductID, CustomerID, DateKey, TotalQuantity, TotalAmount
FROM SalesSummary;

