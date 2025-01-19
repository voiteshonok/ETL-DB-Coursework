-- Create the database
CREATE DATABASE sport_oltp;

-- Connect to the database
\c sport_oltp;

-- Logical Schema in 3NF

-- 1. Categories Table
CREATE TABLE Categories (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Products Table
CREATE TABLE Products (
    ProductID SERIAL PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    Description TEXT,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

-- 3. Suppliers Table
CREATE TABLE Suppliers (
    SupplierID SERIAL PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL UNIQUE,
    ContactNumber VARCHAR(15),
    Email VARCHAR(100),
    Address TEXT
);

-- 4. SupplierProducts Table (Many-to-Many relationship between Suppliers and Products)
CREATE TABLE SupplierProducts (
    SupplierID INT NOT NULL,
    ProductID INT NOT NULL,
    SupplyPrice DECIMAL(10, 2),
    PRIMARY KEY (SupplierID, ProductID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 5. Customers Table
CREATE TABLE Customers (
    CustomerID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(15),
    Address TEXT
);

-- 6. Orders Table
CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- 7. OrderDetails Table (Line items in an order)
CREATE TABLE OrderDetails (
    OrderDetailID SERIAL PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 8. Reviews Table
CREATE TABLE Reviews (
    ReviewID SERIAL PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewText TEXT,
    ReviewDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);



COPY Categories(CategoryName)
FROM '/categories.csv' DELIMITER ',' CSV HEADER;

-- Load Products data
COPY Products(ProductName, CategoryID, Price, StockQuantity, Description)
FROM '/products.csv' DELIMITER ',' CSV HEADER;

\COPY Suppliers(SupplierName, ContactNumber, Email, Address) FROM '/suppliers.csv' WITH CSV HEADER;

\COPY SupplierProducts(SupplierID, ProductID, SupplyPrice) FROM '/supplier_products.csv' WITH CSV HEADER;

\COPY Customers(FirstName, LastName, Email, PhoneNumber, Address) FROM '/customers.csv' WITH CSV HEADER;

\COPY Orders(CustomerID, OrderDate, TotalAmount) FROM '/orders.csv' WITH CSV HEADER;

\COPY OrderDetails(OrderID, ProductID, Quantity, Price) FROM '/orderDetails.csv' WITH CSV HEADER;

\COPY Reviews(ProductID, CustomerID, Rating, ReviewText, ReviewDate) FROM '/reviews.csv' WITH CSV HEADER;


CREATE TEMP TABLE Categories_temp (
    CategoryName VARCHAR(100)
);

COPY Categories_temp(CategoryName)
FROM '/categories.csv' DELIMITER ',' CSV HEADER;

-- Insert only new categories
INSERT INTO Categories (CategoryName)
SELECT c.CategoryName
FROM Categories_temp c
WHERE NOT EXISTS (
    SELECT 1 FROM Categories existing WHERE existing.CategoryName = c.CategoryName
);

DROP TABLE Categories_temp;


CREATE TEMP TABLE Products_temp (
    ProductName VARCHAR(100),
    CategoryName VARCHAR(100),
    Price DECIMAL(10, 2),
    StockQuantity INT,
    Description TEXT
);

COPY Products_temp(ProductName, CategoryName, Price, StockQuantity, Description)
FROM '/products.csv' DELIMITER ',' CSV HEADER;

Select * from Products


INSERT INTO Products (ProductName, CategoryID, Price, StockQuantity, Description)
SELECT p.ProductName, c.CategoryID, p.Price, p.StockQuantity, p.Description
FROM Products_temp p
JOIN Categories c ON p.CategoryName = c.CategoryName


DROP TABLE Products_temp;


CREATE TEMP TABLE Suppliers_temp (
    SupplierName VARCHAR(100),
    ContactNumber VARCHAR(15),
    Email VARCHAR(100),
    Address TEXT
);

COPY Suppliers_temp(SupplierName, ContactNumber, Email, Address)
FROM '/suppliers.csv' DELIMITER ',' CSV HEADER;

-- Insert only new suppliers
INSERT INTO Suppliers (SupplierName, ContactNumber, Email, Address)
SELECT s.SupplierName, s.ContactNumber, s.Email, s.Address
FROM Suppliers_temp s
WHERE NOT EXISTS (
    SELECT 1 FROM Suppliers existing WHERE existing.SupplierName = s.SupplierName
);

DROP TABLE Suppliers_temp;


CREATE TEMP TABLE SupplierProducts_temp (
    SupplierName VARCHAR(100),
    ProductName VARCHAR(100),
    SupplyPrice DECIMAL(10, 2)
);

COPY SupplierProducts_temp(SupplierName, ProductName, SupplyPrice)
FROM '/supplierProducts.csv' DELIMITER ',' CSV HEADER;

-- Insert only new supplier-product combinations
INSERT INTO SupplierProducts (SupplierID, ProductID, SupplyPrice)
SELECT s.SupplierID, p.ProductID, sp.SupplyPrice
FROM SupplierProducts_temp sp
JOIN Suppliers s ON sp.SupplierName = s.SupplierName
JOIN Products p ON sp.ProductName = p.ProductName
WHERE NOT EXISTS (
    SELECT 1 FROM SupplierProducts existing
    WHERE existing.SupplierID = s.SupplierID AND existing.ProductID = p.ProductID
);

DROP TABLE SupplierProducts_temp;


CREATE TEMP TABLE Customers_temp (
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(15),
    Address TEXT
);

COPY Customers_temp(FirstName, LastName, Email, PhoneNumber, Address)
FROM '/customers.csv' DELIMITER ',' CSV HEADER;

-- Insert only new customers based on Email
INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber, Address)
SELECT c.FirstName, c.LastName, c.Email, c.PhoneNumber, c.Address
FROM Customers_temp c
WHERE NOT EXISTS (
    SELECT 1 FROM Customers existing WHERE existing.Email = c.Email
);

DROP TABLE Customers_temp;


CREATE TEMP TABLE Orders_temp (
    CustomerID INT,
    OrderDate TIMESTAMP,
    TotalAmount DECIMAL(10, 2)
);

COPY Orders_temp(CustomerID, OrderDate, TotalAmount)
FROM '/orders.csv' DELIMITER ',' CSV HEADER;

-- Insert only new orders based on CustomerID and OrderDate
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
SELECT o.CustomerID, o.OrderDate, o.TotalAmount
FROM Orders_temp o
WHERE NOT EXISTS (
    SELECT 1 FROM Orders existing WHERE existing.CustomerID = o.CustomerID AND existing.OrderDate = o.OrderDate
);

DROP TABLE Orders_temp;


CREATE TEMP TABLE OrderDetails_temp (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    Price DECIMAL(10, 2)
);

COPY OrderDetails_temp(OrderID, ProductID, Quantity, Price)
FROM '/orderDetails.csv' DELIMITER ',' CSV HEADER;

-- Insert only new order details based on OrderID and ProductID
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
SELECT od.OrderID, od.ProductID, od.Quantity, od.Price
FROM OrderDetails_temp od
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails existing WHERE existing.OrderID = od.OrderID AND existing.ProductID = od.ProductID
);

DROP TABLE OrderDetails_temp;

CREATE TEMP TABLE Reviews_temp (
    ProductID INT,
    CustomerID INT,
    Rating INT,
    ReviewText TEXT,
    ReviewDate TIMESTAMP
);

COPY Reviews_temp(ProductID, CustomerID, Rating, ReviewText, ReviewDate)
FROM '/reviews.csv' DELIMITER ',' CSV HEADER;

-- Insert only new reviews based on ProductID, CustomerID, and ReviewDate
INSERT INTO Reviews (ProductID, CustomerID, Rating, ReviewText, ReviewDate)
SELECT r.ProductID, r.CustomerID, r.Rating, r.ReviewText, r.ReviewDate
FROM Reviews_temp r
WHERE NOT EXISTS (
    SELECT 1 FROM Reviews existing WHERE existing.ProductID = r.ProductID AND existing.CustomerID = r.CustomerID AND existing.ReviewDate = r.ReviewDate
);

DROP TABLE Reviews_temp;


