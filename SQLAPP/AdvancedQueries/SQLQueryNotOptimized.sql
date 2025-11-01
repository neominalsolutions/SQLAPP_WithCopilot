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