-- SQL Views
-- Parametre almayan ve sonuç kümesi döndüren sanal tablolar olarak tanýmlanabilir.


-- The ORDER BY clause is invalid in views, inline functions, derived tables, subqueries, and common table expressions, unless TOP, OFFSET or FOR XML is also specified.


GO
CREATE OR ALTER VIEW dbo.vmMonthlySales 
WITH ENCRYPTION 
AS
WITH MonthlySales AS (
    -- Step 1: Aggregate sales data by Product and Month
    SELECT 
        sod.ProductID,
        p.Name AS ProductName,
        YEAR(soh.OrderDate) AS SalesYear,
        MONTH(soh.OrderDate) AS SalesMonth,
        DATEFROMPARTS(YEAR(soh.OrderDate), MONTH(soh.OrderDate), 1) AS MonthDate,
        SUM(sod.LineTotal) AS MonthlySalesRevenue
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
    GROUP BY 
        sod.ProductID,
        p.Name,
        YEAR(soh.OrderDate),
        MONTH(soh.OrderDate)
),
MovingAverages AS (
    -- Step 2: Calculate moving averages using window functions
    SELECT 
        ProductID,
        ProductName,
        SalesYear,
        SalesMonth,
        MonthDate,
        MonthlySalesRevenue,
        -- 3-Month Rolling Average
        AVG(MonthlySalesRevenue) OVER (
            PARTITION BY ProductID 
            ORDER BY MonthDate 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS RollingAvg_3Month,
        -- 6-Month Rolling Average
        AVG(MonthlySalesRevenue) OVER (
            PARTITION BY ProductID 
            ORDER BY MonthDate 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS RollingAvg_6Month,
        -- 12-Month Rolling Average
        AVG(MonthlySalesRevenue) OVER (
            PARTITION BY ProductID 
            ORDER BY MonthDate 
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS RollingAvg_12Month
    FROM MonthlySales
),
VolatilityMetrics AS (
    -- Step 3: Calculate volatility metrics (Standard Deviation and Variance)
    SELECT 
        ProductID,
        ProductName,
        AVG(MonthlySalesRevenue) AS AvgMonthlySales,
        STDEV(MonthlySalesRevenue) AS SalesStdDev,
        VAR(MonthlySalesRevenue) AS SalesVariance
    FROM MonthlySales
    GROUP BY ProductID, ProductName
),
TrendIndicators AS (
    -- Step 4: Identify highest and lowest sales periods
    SELECT 
        ProductID,
        MAX(CASE WHEN RankHighest = 1 THEN MonthDate END) AS HighestSalesMonth,
        MAX(CASE WHEN RankHighest = 1 THEN MonthlySalesRevenue END) AS HighestSalesAmount,
        MAX(CASE WHEN RankLowest = 1 THEN MonthDate END) AS LowestSalesMonth,
        MAX(CASE WHEN RankLowest = 1 THEN MonthlySalesRevenue END) AS LowestSalesAmount
    FROM (
        SELECT 
            ProductID,
            MonthDate,
            MonthlySalesRevenue,
            ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY MonthlySalesRevenue DESC) AS RankHighest,
            ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY MonthlySalesRevenue ASC) AS RankLowest
        FROM MonthlySales
    ) Ranked
    WHERE RankHighest = 1 OR RankLowest = 1
    GROUP BY ProductID
),
LatestTrends AS (
    -- Step 5: Get the most recent 3-month and 12-month averages for trend direction
    SELECT 
        ProductID,
        ProductName,
        RollingAvg_3Month AS Latest_3MonthAvg,
        RollingAvg_12Month AS Latest_12MonthAvg,
        ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY MonthDate DESC) AS Recency
    FROM MovingAverages
)
-- Final output: Combine all metrics
SELECT 
    lt.ProductID,
    lt.ProductName,
    CAST(lt.Latest_3MonthAvg AS DECIMAL(18, 2)) AS Avg_3Month_Sales,
    CAST(lt.Latest_12MonthAvg AS DECIMAL(18, 2)) AS Avg_12Month_Sales,
    FORMAT(ti.HighestSalesMonth, 'yyyy-MM') AS HighestSalesMonth,
    CAST(ti.HighestSalesAmount AS DECIMAL(18, 2)) AS HighestSalesAmount,
    FORMAT(ti.LowestSalesMonth, 'yyyy-MM') AS LowestSalesMonth,
    CAST(ti.LowestSalesAmount AS DECIMAL(18, 2)) AS LowestSalesAmount,
    ms.MonthlySalesRevenue AS MostRecentMonthlySales,
    CAST(vm.SalesStdDev AS DECIMAL(18, 2)) AS SalesStandardDeviation,
    CAST(vm.SalesVariance AS DECIMAL(18, 2)) AS SalesVariance,
    -- Volatility Status Analysis (Coefficient of Variation - CV based)
    CASE 
        WHEN vm.AvgMonthlySales = 0 THEN 'No Sales Data'
        WHEN (vm.SalesStdDev / vm.AvgMonthlySales) < 0.15 THEN 'Satýþ Ýstikrarlý' -- CV < 15%: Very Stable
        WHEN (vm.SalesStdDev / vm.AvgMonthlySales) BETWEEN 0.15 AND 0.35 THEN 'Normal Dalgalanma' -- CV 15%-35%: Normal Fluctuation
        ELSE 'Çok Deðiþken Satýþlar' -- CV > 35%: High Volatility
    END AS VolatilityStatus,
    -- Trend Direction Logic
    CASE 
        WHEN lt.Latest_12MonthAvg IS NULL THEN 'Insufficient Data'
        WHEN lt.Latest_3MonthAvg > lt.Latest_12MonthAvg * 1.1 THEN 'Increasing'
        WHEN lt.Latest_3MonthAvg < lt.Latest_12MonthAvg * 0.9 THEN 'Decreasing'
        ELSE 'Stable'
    END AS SalesTrendDirection
FROM LatestTrends lt
INNER JOIN VolatilityMetrics vm ON lt.ProductID = vm.ProductID
INNER JOIN TrendIndicators ti ON lt.ProductID = ti.ProductID
INNER JOIN MonthlySales ms ON lt.ProductID = ms.ProductID
WHERE lt.Recency = 1  -- Get only the most recent month's calculations

-- Raporu buradan çalýþtýrýyoruz.
SELECT * FROM dbo.vmMonthlySales
SELECT * FROM dbo.vmMonthlySales WHERE ProductID = 776 ORDER BY ProductID DESC;

-- Ortak verilerin bulunduðu tablolara baðlantý kurmamýzý saðlayan sanal görüntüler.
SELECT * FROM Sales.SalesOrderDetail sd  JOIN dbo.vmMonthlySales ms ON sd.ProductID=ms.ProductID WHERE sd.SalesOrderID=71774 ORDER BY sd.SalesOrderID DESC;
GO


CREATE OR ALTER FUNCTION dbo.ufnGetMonthlySalesByProduct
(
    @ProductID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM dbo.vmMonthlySales WHERE ProductID = @ProductID
);
GO
-- Usage Example
SELECT * FROM dbo.ufnGetMonthlySalesByProduct(776);


-- CREATE SAMPLE WITHSCHEMA BINDING VIEW
-- View þemasýný koruma altýna alýr ve bu nedenle, temel tablolarda yapýlan deðiþiklikler (örneðin, sütun ekleme veya silme) bu görünümü etkileyebilir.Bunu yapýlmasýna izin vermez.
GO
CREATE OR ALTER VIEW dbo.vmProductSalesSummary
WITH SCHEMABINDING -- ÞEMAYI KORUMA ALTINA ALIR
AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalQuantitySold,
    SUM(sod.LineTotal) AS TotalSalesAmount
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
GROUP BY p.ProductID, p.Name;
GO
-- Usage Example
SELECT * FROM dbo.vmProductSalesSummary WHERE ProductID = 776;
ALTER TABLE Sales.SalesOrderDetail 
ALTER COLUMN OrderQty INT NULL;
-- 'vmProductSalesSummary' is dependent on column 'OrderQty'.
-- Viewde kullanýlan bir sutunun tipini alter ile güncelleyemeyiz veya sutunu drop edemeyiz.
-- ALTER TABLE Production.Product

ALTER TABLE Production.Product
ALTER COLUMN Name NVARCHAR(100) NOT NULL;

-- Note: Views created with SCHEMABINDING cannot reference objects outside their own schema and prevent changes to the underlying tables that would affect the view.
GO
-- DROP VIEWS AND FUNCTIONS
DROP VIEW IF EXISTS dbo.vmMonthlySales;
DROP VIEW IF EXISTS dbo.vmProductSalesSummary;
DROP FUNCTION IF EXISTS dbo.ufnGetMonthlySalesByProduct;
GO
-- End of SQL Views sample
-- End of T-SQL error handling sample
-- End of T-SQL declarations and conditional statements and loops sample


