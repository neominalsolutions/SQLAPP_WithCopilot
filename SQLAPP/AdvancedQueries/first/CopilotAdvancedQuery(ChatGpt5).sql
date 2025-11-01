/* AdventureWorksLT2019 – Per product and per-customer metrics, grouped by Category/Subcategory
   - For each product: total order count (across all customers), avg order amount (orders containing that product), distinct customer count
   - For each customer: how many times they ordered the product, and their total spending for that product
*/
USE AdventureWorksLT2019;
GO

WITH Base AS
(
    SELECT
        d.SalesOrderID,
        h.OrderDate,
        h.TotalDue,
        h.SubTotal,
        h.CustomerID,
        c.FirstName,
        c.LastName,
        c.CompanyName,
        d.ProductID,
        p.Name AS ProductName,
        -- Category/Subcategory (LT uses a self-referencing ProductCategory hierarchy)
        COALESCE(pcCat.ProductCategoryID, pcSub.ProductCategoryID) AS CategoryID,
        COALESCE(pcCat.Name, pcSub.Name) AS CategoryName,
        CASE WHEN pcCat.ProductCategoryID IS NULL THEN NULL ELSE pcSub.ProductCategoryID END AS SubcategoryID,
        CASE WHEN pcCat.ProductCategoryID IS NULL THEN NULL ELSE pcSub.Name END AS SubcategoryName,
        -- Line-level economics
        d.UnitPrice,
        d.UnitPriceDiscount,
        d.OrderQty,
        d.LineTotal
    FROM SalesLT.SalesOrderDetail AS d
    INNER JOIN SalesLT.SalesOrderHeader AS h ON h.SalesOrderID = d.SalesOrderID
    INNER JOIN SalesLT.Product AS p ON p.ProductID = d.ProductID
    INNER JOIN SalesLT.Customer AS c ON c.CustomerID = h.CustomerID
    LEFT JOIN SalesLT.ProductCategory AS pcSub ON pcSub.ProductCategoryID = p.ProductCategoryID
    LEFT JOIN SalesLT.ProductCategory AS pcCat ON pcCat.ProductCategoryID = pcSub.ParentProductCategoryID
),
-- Distinct (Product, Order) rows so order-level metrics are not duplicated if a product ever spans multiple detail lines
ProductOrders AS
(
    SELECT DISTINCT
        b.CategoryID,
        b.CategoryName,
        b.SubcategoryID,
        b.SubcategoryName,
        b.ProductID,
        b.ProductName,
        b.SalesOrderID,
        b.TotalDue,
        b.CustomerID
    FROM Base AS b
),
-- Product-level aggregates across all customers
ProductStats AS
(
    SELECT
        po.CategoryID,
        po.CategoryName,
        po.SubcategoryID,
        po.SubcategoryName,
        po.ProductID,
        po.ProductName,
        COUNT(DISTINCT po.SalesOrderID) AS ProductTotalOrderCount,
        COUNT(DISTINCT po.CustomerID)    AS ProductDistinctCustomerCount,
        AVG(CAST(po.TotalDue AS decimal(19,4))) AS ProductAvgOrderAmount
    FROM ProductOrders AS po
    GROUP BY
        po.CategoryID, po.CategoryName,
        po.SubcategoryID, po.SubcategoryName,
        po.ProductID, po.ProductName
),
-- Customer x Product metrics
CustomerProductStats AS
(
    SELECT
        b.CategoryID,
        b.CategoryName,
        b.SubcategoryID,
        b.SubcategoryName,
        b.ProductID,
        b.ProductName,
        b.CustomerID,
        CONCAT(ISNULL(b.FirstName, ''), ' ', ISNULL(b.LastName, '')) AS CustomerName,
        COUNT(DISTINCT b.SalesOrderID) AS CustomerOrderCountForProduct,
        SUM(b.LineTotal)               AS CustomerTotalSpendingForProduct
    FROM Base AS b
    GROUP BY
        b.CategoryID, b.CategoryName,
        b.SubcategoryID, b.SubcategoryName,
        b.ProductID, b.ProductName,
        b.CustomerID,
        CONCAT(ISNULL(b.FirstName, ''), ' ', ISNULL(b.LastName, ''))
)
SELECT
    cps.CategoryName,
    cps.SubcategoryName,
    cps.ProductID,
    cps.ProductName,
    ps.ProductDistinctCustomerCount,
    ps.ProductTotalOrderCount,
    ps.ProductAvgOrderAmount,
    cps.CustomerID,
    cps.CustomerName,
    cps.CustomerOrderCountForProduct,
    cps.CustomerTotalSpendingForProduct
FROM CustomerProductStats AS cps
INNER JOIN ProductStats AS ps
    ON ps.CategoryID = cps.CategoryID
   AND ISNULL(ps.SubcategoryID, -1) = ISNULL(cps.SubcategoryID, -1)
   AND ps.ProductID = cps.ProductID
ORDER BY
    cps.CategoryName,
    cps.SubcategoryName,
    cps.ProductName,
    cps.CustomerName;