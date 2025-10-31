-- Multi-Level Sales Aggregation Report
-- AdventureWorksLT2019 Database
-- Combines customer-level purchasing behavior with product-level performance metrics

-- Tecnical Prompt: GeminiAI Pro %33 VS No Tech Prompt %67,  
-- Prompt Boost VS %58 - GeminiAI Pro %42
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


-- tURKİSH VERSION %67 no technical prompt
WITH CustomerProductOrders AS (
    -- Her müşteri ve ürün kombinasyonu için sipariş detayları
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
    -- Her ürün için toplam sipariş sayısı ve ortalama tutar
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
    -- Tüm siparişlerin toplam sayısı
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
ORDER BY 
    cpo.ParentCategoryName,
    cpo.CategoryName,
    cpo.ProductName,
    cpo.CustomerTotalSpent DESC;


-- PromptBoost Extention VSCode Prompt  %58
WITH ProductOrderStats AS (
    SELECT 
        p.ProductID,
        pc.Name AS CategoryName,
        psc.Name AS SubcategoryName,
        p.Name AS ProductName,
        COUNT(DISTINCT sod.SalesOrderID) AS TotalOrderCount,
        FORMAT(AVG(sod.LineTotal), 'C', 'tr-TR') AS AvgOrderAmount,
        AVG(sod.LineTotal) AS AvgOrderAmountNumeric
    FROM SalesLT.Product p
    INNER JOIN SalesLT.ProductCategory psc ON p.ProductCategoryID = psc.ProductCategoryID
    INNER JOIN SalesLT.ProductCategory pc ON psc.ParentProductCategoryID = pc.ProductCategoryID
    INNER JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY p.ProductID, pc.Name, psc.Name, p.Name
),
CustomerProductDetails AS (
    SELECT 
        p.ProductID,
        c.CustomerID,
        ISNULL(c.FirstName, '') AS FirstName,
        ISNULL(c.LastName, '') AS LastName,
        COUNT(sod.SalesOrderDetailID) AS CustomerOrderCount,
        FORMAT(SUM(sod.LineTotal), 'C', 'tr-TR') AS CustomerTotalSpent,
        SUM(sod.LineTotal) AS CustomerTotalSpentNumeric
    FROM SalesLT.Product p
    INNER JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    INNER JOIN SalesLT.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
    GROUP BY p.ProductID, c.CustomerID, c.FirstName, c.LastName
)
SELECT 
    pos.CategoryName,
    pos.SubcategoryName,
    pos.ProductName,
    pos.TotalOrderCount,
    pos.AvgOrderAmount,
    STRING_AGG(
        CONCAT(
            cpd.FirstName, ' ', cpd.LastName, 
            ' (Sipariş: ', cpd.CustomerOrderCount, 
            ', Toplam: ', cpd.CustomerTotalSpent, ')'
        ), 
        '; '
    ) WITHIN GROUP (ORDER BY cpd.CustomerTotalSpentNumeric DESC) AS CustomerDetails
FROM ProductOrderStats pos
INNER JOIN CustomerProductDetails cpd ON pos.ProductID = cpd.ProductID
GROUP BY 
    pos.CategoryName,
    pos.SubcategoryName, 
    pos.ProductName,
    pos.TotalOrderCount,
    pos.AvgOrderAmount,
    pos.AvgOrderAmountNumeric
ORDER BY 
    pos.CategoryName,
    pos.SubcategoryName,
    pos.ProductName;



