-- tURKÝSH VERSION %67 no technical prompt
SET STATISTICS TIME ON
SET STATISTICS IO ON

WITH CustomerProductOrders AS (
    -- Her müþteri ve ürün kombinasyonu için sipariþ detaylarý
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        ISNULL(pcp.Name, 'Ana Kategori') AS ParentCategoryName,
        COUNT(DISTINCT soh.SalesOrderID) AS CustomerOrderCount,
        SUM(sod.LineTotal) AS CustomerTotalSpent
    FROM SalesLT.Customer c
    INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    INNER JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN SalesLT.Product p ON sod.ProductID = p.ProductID
    INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN SalesLT.ProductCategory pcp ON pc.ParentProductCategoryID = pcp.ProductCategoryID
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        p.ProductID,
        p.Name,
        pc.Name,
        pcp.Name
),
ProductStats AS (
    -- Her ürün için toplam sipariþ sayýsý ve ortalama tutar
    SELECT 
        p.ProductID,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
        COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
        AVG(sod.LineTotal) AS AvgOrderAmount
    FROM SalesLT.Product p
    INNER JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    INNER JOIN SalesLT.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
    GROUP BY 
        p.ProductID
),
TotalOrderCount AS (
    -- Tüm sipariþlerin toplam sayýsý
    SELECT COUNT(DISTINCT SalesOrderID) AS TotalOrder
    FROM SalesLT.SalesOrderHeader
)
SELECT 
    (SELECT TotalOrder FROM TotalOrderCount) AS TotalOrder,
    cpo.ParentCategoryName,
    cpo.CategoryName,
    cpo.ProductName,
    ps.TotalOrders,
    FORMAT(cpo.CustomerTotalSpent, 'C', 'tr-TR') AS CustomerTotalSpent,
    cpo.CustomerOrderCount,
    cpo.CustomerName,
    ps.TotalCustomers,
    FORMAT(ps.AvgOrderAmount, 'C', 'tr-TR') AS AvgOrderAmount
FROM CustomerProductOrders cpo
INNER JOIN ProductStats ps ON cpo.ProductID = ps.ProductID

SET STATISTICS TIME OFF
SET STATISTICS IO OFF


	-- Tecnical Prompt: GeminiAI Pro %33 VS No Tech Prompt %67,  
-- Prompt Boost VS %58 - GeminiAI Pro %42
SET STATISTICS TIME ON
SET STATISTICS IO ON
WITH CustomerProductMetrics AS (
    -- Step 1: Calculate customer-specific metrics per product using GROUP BY
    SELECT 
        pc_parent.Name AS ParentCategoryName,
        pc_sub.Name AS SubCategoryName,
        p.Name AS ProductName,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
        p.ProductID,
        c.CustomerID,
        -- Customer-specific metrics
        COUNT(sod.SalesOrderDetailID) AS Customer_ProductOrderCount,
        SUM(sod.LineTotal) AS Customer_ProductTotalSpend
    FROM 
        SalesLT.SalesOrderDetail sod
        INNER JOIN SalesLT.SalesOrderHeader soh 
            ON sod.SalesOrderID = soh.SalesOrderID
        INNER JOIN SalesLT.Customer c 
            ON soh.CustomerID = c.CustomerID
        INNER JOIN SalesLT.Product p 
            ON sod.ProductID = p.ProductID
        INNER JOIN SalesLT.ProductCategory pc_sub 
            ON p.ProductCategoryID = pc_sub.ProductCategoryID
        LEFT JOIN SalesLT.ProductCategory pc_parent 
            ON pc_sub.ParentProductCategoryID = pc_parent.ProductCategoryID
    GROUP BY 
        pc_parent.Name,
        pc_sub.Name,
        p.Name,
        p.ProductID,
        c.CustomerID,
        c.FirstName,
        c.LastName
)
-- Step 2: Apply window functions to calculate product-level aggregated metrics
SELECT 
    ParentCategoryName,
    SubCategoryName,
    ProductName,
    CustomerFullName,
    Customer_ProductOrderCount,
    FORMAT(Customer_ProductTotalSpend, 'C', 'tr-TR') AS Customer_ProductTotalSpend,
    -- Product-level metrics using window functions
   FORMAT(SUM(Customer_ProductOrderCount) OVER (PARTITION BY ProductID), 'C', 'tr-TR') AS Product_GrandTotalOrders,
   FORMAT(AVG(Customer_ProductTotalSpend) OVER (PARTITION BY ProductID), 'C', 'tr-TR') AS Product_OverallAverageValue
FROM 
    CustomerProductMetrics
ORDER BY 
    ParentCategoryName,
    SubCategoryName,
    ProductName,
    CustomerFullName;
SET STATISTICS TIME OFF
SET STATISTICS IO OFF




-- Optimized olmayan versiyon


-- Fixed Non-optimized version - Corrected aggregate and ORDER BY errors

SELECT DISTINCT
    -- Scalar subqueries for each row (very inefficient)
    (SELECT Name FROM SalesLT.ProductCategory WHERE ProductCategoryID = 
        (SELECT ParentProductCategoryID FROM SalesLT.ProductCategory WHERE ProductCategoryID = p.ProductCategoryID)) AS ParentCategoryName,
    (SELECT Name FROM SalesLT.ProductCategory WHERE ProductCategoryID = p.ProductCategoryID) AS SubCategoryName,
    p.Name AS ProductName,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    -- Redundant subqueries calculating the same thing multiple times
    (SELECT COUNT(*) FROM SalesLT.SalesOrderDetail sod2 
     WHERE sod2.ProductID = p.ProductID 
     AND sod2.SalesOrderID IN (SELECT SalesOrderID FROM SalesLT.SalesOrderHeader WHERE CustomerID = c.CustomerID)) AS Customer_ProductOrderCount,
    FORMAT((SELECT SUM(LineTotal) FROM SalesLT.SalesOrderDetail sod3 
            WHERE sod3.ProductID = p.ProductID 
            AND sod3.SalesOrderID IN (SELECT SalesOrderID FROM SalesLT.SalesOrderHeader WHERE CustomerID = c.CustomerID)), 'C', 'tr-TR') AS Customer_ProductTotalSpend,
    -- Fixed: Simple count without nested aggregation
    (SELECT COUNT(*) 
     FROM SalesLT.SalesOrderDetail sod4 
     WHERE sod4.ProductID = p.ProductID) AS Product_GrandTotalOrders,
    -- Fixed: Calculate average per customer for this product
    FORMAT((SELECT AVG(CustomerSpend) 
            FROM (SELECT SUM(sod5.LineTotal) AS CustomerSpend
                  FROM SalesLT.SalesOrderDetail sod5
                  INNER JOIN SalesLT.SalesOrderHeader soh5 ON sod5.SalesOrderID = soh5.SalesOrderID
                  WHERE sod5.ProductID = p.ProductID
                  GROUP BY soh5.CustomerID) AS CustomerTotals), 'C', 'tr-TR') AS Product_OverallAverageValue
FROM 
    SalesLT.Product p,
    SalesLT.Customer c,
    SalesLT.SalesOrderHeader soh,
    SalesLT.SalesOrderDetail sod
WHERE 
    sod.SalesOrderID = soh.SalesOrderID
    AND soh.CustomerID = c.CustomerID
    AND sod.ProductID = p.ProductID
ORDER BY 
    ParentCategoryName,  -- Fixed: Use column alias instead of subquery
    SubCategoryName,     -- Fixed: Use column alias instead of subquery
    ProductName,         -- Fixed: Use column alias instead of subquery
    CustomerFullName;    -- Fixed: Use column alias instead of subquery


CREATE NONCLUSTERED INDEX NON_CLUSTERED_CarrierTrackingNumber
ON [Sales].[SalesOrderDetail] ([CarrierTrackingNumber])

SELECT * FROM Sales.SalesOrderDetail WHERE Sales.SalesOrderDetail.CarrierTrackingNumber = '4911-403C-98'
SELECT * FROM Test_SalesOrderDetail WHERE Test_SalesOrderDetail.CarrierTrackingNumber = '4911-403C-98'


/****** Object:  Index [AK_SalesOrderDetail_rowguid]    Script Date: 1.11.2025 10:07:47 ******/
CREATE UNIQUE NONCLUSTERED INDEX [AK_SalesOrderDetail_rowguid_1] ON Test_SalesOrderDetail
(
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_SalesOrderDetail_ProductID]    Script Date: 1.11.2025 10:07:52 ******/
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] ON Test_SalesOrderDetail
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


ALTER TABLE Test_SalesOrderDetail ADD  CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO








