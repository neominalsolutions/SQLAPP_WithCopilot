

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


