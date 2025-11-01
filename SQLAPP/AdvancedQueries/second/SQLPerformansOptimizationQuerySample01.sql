
SELECT * INTO TEST_SalesOrderHeader FROM Sales.SalesOrderHeader
SELECT * INTO TEST_SalesOrderDetail FROM Sales.SalesOrderDetail
SELECT * INTO TEST_Person FROM Person.Person
SELECT * INTO TEST_Product  FROM Production.Product
SELECT * INTO TEST_Customer FROM Sales.Customer



SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
	SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    o.SalesOrderID,
    o.OrderDate,
    sod.ProductID,
    pr.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalAmount
FROM 
    TEST_Customer AS c
INNER JOIN 
    TEST_SalesOrderHeader AS o ON c.CustomerID = o.CustomerID
INNER JOIN 
    TEST_SalesOrderDetail AS sod ON o.SalesOrderID = sod.SalesOrderID
INNER JOIN 
    TEST_Person AS p ON c.PersonID = p.BusinessEntityID
INNER JOIN 
   TEST_Product AS pr ON sod.ProductID = pr.ProductID
WHERE 
    c.TerritoryID = 1
    AND o.OrderDate >= '2013-01-01'
    AND EXISTS (
        SELECT 1 
        FROM TEST_SalesOrderHeader AS o2 
        WHERE o2.CustomerID = c.CustomerID 
        AND o2.Status = 5
    )
GROUP BY 
    c.CustomerID, p.FirstName, p.LastName, o.SalesOrderID, o.OrderDate, sod.ProductID, pr.Name
ORDER BY 
    TotalAmount DESC

SET STATISTICS TIME OFF
SET STATISTICS IO OFF



-- Ýndeksli hali
-- Indeksli sorgu CPU daha az kullanýyor ama Daha uzun sürüyor
-- Üsteki Indeksiz hali CPU 2 kat daha faazla kullanýyor ama sorgu daha hýzlý cevap veriyor.
USE AdventureWorks2019


SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    o.SalesOrderID,
    o.OrderDate,
    sod.ProductID,
    pr.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalAmount
FROM 
    Sales.Customer AS c
INNER JOIN 
    Sales.SalesOrderHeader AS o ON c.CustomerID = o.CustomerID
INNER JOIN 
    Sales.SalesOrderDetail AS sod ON o.SalesOrderID = sod.SalesOrderID
INNER JOIN 
    Person.Person AS p ON c.PersonID = p.BusinessEntityID
INNER JOIN 
    Production.Product AS pr ON sod.ProductID = pr.ProductID
WHERE 
    c.TerritoryID = 1
    AND o.OrderDate >= '2013-01-01'
	AND o.CustomerID =  c.CustomerID  AND o.Status = 5
    AND EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderHeader AS o2 
        WHERE o2.CustomerID = c.CustomerID 
        AND o2.Status = 5
    )
GROUP BY 
    c.CustomerID, p.FirstName, p.LastName, o.SalesOrderID, o.OrderDate, sod.ProductID, pr.Name
ORDER BY 
    TotalAmount DESC




--- OPTIMIZED VERSION WITH PROFILER
-- OPTIMIZED VERSION for SalesLT Schema (AdventureWorksLT2019)

SELECT 
    c.CustomerID,
    pe.FirstName,
    pe.LastName,
    o.SalesOrderID,
    o.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalAmount
FROM 
    Sales.Customer AS c
    INNER JOIN Sales.SalesOrderHeader AS o 
        ON c.CustomerID = o.CustomerID
		AND c.TerritoryID = 1
        AND o.Status = 5
        AND o.OrderDate >= '2013-01-01'
    INNER JOIN Sales.SalesOrderDetail AS sod 
        ON o.SalesOrderID = sod.SalesOrderID
	INNER JOIN 
	Person.Person AS pe ON c.PersonID = pe.BusinessEntityID

    INNER JOIN Production.Product AS p 
        ON sod.ProductID = p.ProductID
GROUP BY 
    c.CustomerID, 
    pe.FirstName, 
    pe.LastName, 
    o.SalesOrderID, 
    o.OrderDate, 
    sod.ProductID, 
    p.Name
ORDER BY 
    TotalAmount DESC;


-- 2. olarak Index önerisi verdi

CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [Sales].[SalesOrderHeader] ([Status],[OrderDate])
INCLUDE ([CustomerID])
