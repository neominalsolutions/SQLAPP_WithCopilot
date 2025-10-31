

-- "Her ürün için, o ürünü sipariş eden tüm müşterilerin toplam sipariş sayısını ve ortalama sipariş tutarını hesapla. Ayrıca her müşteri için, bu ürünü kaç kez sipariş ettiğini ve toplam harcamasını göster. Sonuçları ürün kategorisi ve alt kategorisine göre grupla." AdventureWorksLT2019 versiyonunu kullanarak sorguyu yaz. MS SQL Server 2019 Functionları kullan.


WITH ProductCustomerSales AS (
    -- Calculate sales data for each customer and product combination
    SELECT
        C.CustomerID,
        P.ProductID,
        PC_Sub.ProductCategoryID AS SubCategoryID,
        PC_Parent.ProductCategoryID AS ParentCategoryID,
        COUNT(DISTINCT SOH.SalesOrderID) AS CustomerProductOrderCount,
        SUM(SOD.LineTotal) AS CustomerProductTotalSpending
    FROM SalesLT.SalesOrderDetail AS SOD
    JOIN SalesLT.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    JOIN SalesLT.Product AS P ON SOD.ProductID = P.ProductID
    JOIN SalesLT.Customer AS C ON SOH.CustomerID = C.CustomerID
    LEFT JOIN SalesLT.ProductCategory AS PC_Sub ON P.ProductCategoryID = PC_Sub.ProductCategoryID
    LEFT JOIN SalesLT.ProductCategory AS PC_Parent ON PC_Sub.ParentProductCategoryID = PC_Parent.ProductCategoryID
    GROUP BY
        C.CustomerID,
        P.ProductID,
        PC_Sub.ProductCategoryID,
        PC_Parent.ProductCategoryID
),
ProductTotalSales AS (
    -- Calculate total and average sales data for each product across all customers
    SELECT
        SOD.ProductID,
        COUNT(DISTINCT SOD.SalesOrderID) AS TotalProductOrderCount,
        AVG(SOH.TotalDue) AS AverageOrderAmount
    FROM SalesLT.SalesOrderDetail AS SOD
    JOIN SalesLT.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    GROUP BY
        SOD.ProductID
)
-- Final SELECT to combine and present the data
SELECT
    ISNULL(PC_Parent.Name, 'N/A') AS ProductCategory,
    ISNULL(PC_Sub.Name, 'N/A') AS ProductSubCategory,
    P.Name AS ProductName,
    PTS.TotalProductOrderCount,
    FORMAT(PTS.AverageOrderAmount, 'C', 'en-US') AS AverageOrderAmount,
    C.FirstName + ' ' + C.LastName AS CustomerName,
    PCS.CustomerProductOrderCount,
    FORMAT(PCS.CustomerProductTotalSpending, 'C', 'en-US') AS CustomerProductTotalSpending
FROM ProductCustomerSales AS PCS
JOIN ProductTotalSales AS PTS ON PCS.ProductID = PTS.ProductID
JOIN SalesLT.Product AS P ON PCS.ProductID = P.ProductID
JOIN SalesLT.Customer AS C ON PCS.CustomerID = C.CustomerID
LEFT JOIN SalesLT.ProductCategory AS PC_Sub ON PCS.SubCategoryID = PC_Sub.ProductCategoryID
LEFT JOIN SalesLT.ProductCategory AS PC_Parent ON PCS.ParentCategoryID = PC_Parent.ProductCategoryID
ORDER BY
    ProductCategory,
    ProductSubCategory,
    ProductName,
    CustomerProductTotalSpending DESC;