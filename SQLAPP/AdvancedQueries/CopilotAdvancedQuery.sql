
-- "Her ürün için, o ürünü sipariş eden tüm müşterilerin toplam sipariş sayısını ve ortalama sipariş tutarını hesapla. Ayrıca her müşteri için, bu ürünü kaç kez sipariş ettiğini ve toplam harcamasını göster. Sonuçları ürün kategorisi ve alt kategorisine göre grupla."



-- "Her ürün için, o ürünü sipariş eden tüm müşterilerin toplam sipariş sayısını ve ortalama sipariş tutarını hesapla. Ayrıca her müşteri için, bu ürünü kaç kez sipariş ettiğini ve toplam harcamasını göster. Sonuçları ürün kategorisi ve alt kategorisine göre grupla."

WITH CustomerProductOrders AS (
    -- Her müşteri ve ürün kombinasyonu için sipariş detayları
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        pc.ParentProductCategoryID,
        ISNULL(pcp.Name, 'Ana Kategori') AS ParentCategoryName,
        COUNT(DISTINCT soh.SalesOrderID) AS CustomerOrderCount,
        SUM(sod.LineTotal) AS CustomerTotalSpent,
        SUM(sod.OrderQty) AS CustomerTotalQuantity
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
        pc.ParentProductCategoryID,
        pcp.Name
),
ProductStats AS (
    -- Her ürün için toplam sipariş sayısı ve ortalama tutar
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        ISNULL(pcp.Name, 'Ana Kategori') AS ParentCategoryName,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
        COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
        AVG(sod.LineTotal) AS AvgOrderAmount,
        SUM(sod.LineTotal) AS TotalRevenue,
        SUM(sod.OrderQty) AS TotalQuantitySold
    FROM SalesLT.Product p
    INNER JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    INNER JOIN SalesLT.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
    INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN SalesLT.ProductCategory pcp ON pc.ParentProductCategoryID = pcp.ProductCategoryID
    GROUP BY 
        p.ProductID,
        p.Name,
        pc.Name,
        pcp.Name
)
SELECT 
    ps.ParentCategoryName,
    ps.CategoryName,
    ps.ProductID,
    ps.ProductName,
    ps.TotalOrders,
    ps.TotalCustomers,
    FORMAT(ps.AvgOrderAmount, 'C', 'tr-TR') AS AvgOrderAmount,
    FORMAT(ps.TotalRevenue, 'C', 'tr-TR') AS TotalRevenue,
    ps.TotalQuantitySold,
    cpo.CustomerID,
    cpo.CustomerName,
    cpo.CustomerOrderCount,
    FORMAT(cpo.CustomerTotalSpent, 'C', 'tr-TR') AS CustomerTotalSpent,
    cpo.CustomerTotalQuantity,
    -- Müşterinin bu üründeki harcamasının toplam ürün gelirine oranı
    FORMAT(CAST(cpo.CustomerTotalSpent AS FLOAT) / NULLIF(ps.TotalRevenue, 0) * 100, 'N2') + '%' AS CustomerRevenueContribution,
    -- Pencere fonksiyonu ile kategorideki sıralama
    DENSE_RANK() OVER (PARTITION BY ps.CategoryName ORDER BY cpo.CustomerTotalSpent DESC) AS CustomerRankInCategory
FROM ProductStats ps
INNER JOIN CustomerProductOrders cpo ON ps.ProductID = cpo.ProductID
ORDER BY 
    ps.ParentCategoryName,
    ps.CategoryName,
    ps.ProductName,
    cpo.CustomerTotalSpent DESC;