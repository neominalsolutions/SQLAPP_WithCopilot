--- Advaced SQL Queries


-- "Her ürün için, o ürünle birlikte en çok satın alınan diğer 5 ürünü bul (market basket analysis). Her kombinasyon için birlikte satın alma sayısını ve toplam satış tutarını göster."

-- Pazar Sepet Analizi: 

-- Amaç: Bu analizde amacımız, bir müşteri sepetine herhangi bir ürün (A) konulduğunda, onunla birlikte en sık hangi diğer ürünün (B) satın alındığını görmektir.

-- Prompt: 

-- Advanced query: Market Basket Analysis
-- Identifies top 5 products frequently purchased together in the same order
-- "Using the SalesLT schema reference (SalesLT.Product and SalesLT.SalesOrderDetail), generate an advanced T-SQL query to perform a Market Basket Analysis.
-- For each distinct product (Product A), the query must identify the Top 5 other products (Product B) that were most frequently purchased within the same sales order.
-- The final output should show:
-- 1. Product A Details (ID and Name).
-- 2. Product B Details (ID and Name - the co-purchased item).
-- 3. Co-purchase Count: The number of unique sales orders where Product A and Product B appeared together.
-- 4. Total Sales Revenue (Toplam Satış Geliri): The total revenue generated from the sales of Product B in those co-purchase (birlikte satın alma) orders.
-- Utilize self-joins on the SalesOrderDetail table to find product pairs and apply Window Functions (e.g., ROW_NUMBER() or RANK()) to effectively determine the 'Top 5' co-purchased items for each Product A."




--- Advaced SQL Queries


-- "Her ürün için, o ürünle birlikte en çok satın alınan diğer 5 ürünü bul (market basket analysis). Her kombinasyon için birlikte satın alma sayısını ve toplam satış tutarını göster."

-- Pazar Sepet Analizi: 

-- Amaç: Bu analizde amacımız, bir müşteri sepetine herhangi bir ürün (A) konulduğunda, onunla birlikte en sık hangi diğer ürünün (B) satın alındığını görmektir.

-- Prompt: 

-- Advanced query: Market Basket Analysis
-- Identifies top 5 products frequently purchased together in the same order
-- "Using the SalesLT schema reference (SalesLT.Product and SalesLT.SalesOrderDetail), generate an advanced T-SQL query to perform a Market Basket Analysis.
-- For each distinct product (Product A), the query must identify the Top 5 other products (Product B) that were most frequently purchased within the same sales order.
-- The final output should show:
-- 1. Product A Details (ID and Name).
-- 2. Product B Details (ID and Name - the co-purchased item).
-- 3. Co-purchase Count: The number of unique sales orders where Product A and Product B appeared together.
-- 4. Total Sales Revenue (Toplam Satış Geliri): The total revenue generated from the sales of Product B in those co-purchase (birlikte satın alma) orders.
-- Utilize self-joins on the SalesOrderDetail table to find product pairs and apply Window Functions (e.g., ROW_NUMBER() or RANK()) to effectively determine the 'Top 5' co-purchased items for each Product A."

WITH ProductPairs AS (
    -- Self-join to find all product pairs in the same order
    SELECT 
        sod1.ProductID AS ProductA_ID,
        sod2.ProductID AS ProductB_ID,
        sod1.SalesOrderID,
        sod2.LineTotal AS ProductB_Revenue
    FROM SalesLT.SalesOrderDetail sod1
    INNER JOIN SalesLT.SalesOrderDetail sod2
        ON sod1.SalesOrderID = sod2.SalesOrderID
        AND sod1.ProductID < sod2.ProductID  -- Bisiklet alırken kask alınır ama tam tersi kask alınırken bisiklet alınır mı raporda 2 kez aynı ürün çifti gözükmesin diye
),
AggregatedPairs AS (
    -- Aggregate co-purchase metrics
    SELECT 
        ProductA_ID,
        ProductB_ID,
        COUNT(DISTINCT SalesOrderID) AS CoPurchaseCount,
        SUM(ProductB_Revenue) AS TotalProductB_Revenue
    FROM ProductPairs
    GROUP BY ProductA_ID, ProductB_ID
),
RankedPairs AS (
    -- Apply window function to rank top 5 products for each Product A
    SELECT 
        ProductA_ID,
        ProductB_ID,
        CoPurchaseCount,
        TotalProductB_Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY ProductA_ID 
            ORDER BY CoPurchaseCount DESC, TotalProductB_Revenue DESC
        ) AS Rank
    FROM AggregatedPairs
)
-- Final output with product details
SELECT 
    rp.ProductA_ID,
rp.Rank,
    pa.Name AS ProductA_Name,
    rp.ProductB_ID,
    pb.Name AS ProductB_Name,
    rp.CoPurchaseCount AS CoPurchaseCount,
    CAST(rp.TotalProductB_Revenue AS DECIMAL(18, 2)) AS TotalSalesRevenue
FROM RankedPairs rp
INNER JOIN SalesLT.Product pa ON rp.ProductA_ID = pa.ProductID
INNER JOIN SalesLT.Product pb ON rp.ProductB_ID = pb.ProductID
WHERE rp.Rank <= 5
ORDER BY rp.ProductA_ID, rp.Rank;



-- Ürün Satış Trendi ve İstikrar Analizi
-- Amaç: Bu tür bir analiz, bir ürünün pazar performansını ve satış istikrarını (tahmin edilebilirliğini) anlamak için kritik öneme sahiptir.


-- Advanced query: Product Sales Trend and Volatility Analysis

-- SQL SERVER 2019 COMPATIBILITY NOTE: The solution MUST AVOID using functions introduced in SQL Server 2022 (e.g., LEAST, GREATEST). Use standard T-SQL CASE expressions for minimum value comparisons."


-- Calculates moving averages, trend indicators, and volatility metrics for each product
-- "Using the SalesLT schema reference (SalesLT.Product, SalesLT.SalesOrderHeader, SalesLT.SalesOrderDetail), generate an advanced T-SQL query to perform a comprehensive historical sales trend and volatility analysis for every product.
-- The query must calculate the following metrics for EACH product, based on monthly sales revenue (Sum of LineTotal):
-- 1. Moving Averages:
--    * 3-Month Rolling Average Sales.
--    * 6-Month Rolling Average Sales.
--    * 12-Month (Annual) Average Sales (where applicable).
-- 2. Trend Indicators: (Eğilim Göstergeleri)
--    * Identify the month and sales amount corresponding to the Highest Sales period.
--    * Identify the month and sales amount corresponding to the Lowest Sales period.
-- 3. Sales Volatility: (Satış Değişkenliği, Satışlardaki İstikrarsızlık)
--    * Calculate the Standard Deviation (STDEV) of monthly sales revenue.
--    * Calculate the Variance (VAR) of monthly sales revenue. (Aylık satış gelirinin Varyansını (VAR) hesapla.)
-- 4. Sales Trend Direction: Determine the general trend of sales (e.g., 'Increasing', 'Decreasing', 'Stable') based on comparing the 3-month average to the 12-month average, or by analyzing recent linear regression (if feasible with T-SQL, otherwise simplify to period comparison).
-- Utilize CTEs to first aggregate sales data by Product and Month, and then apply advanced Window Functions (e.g., AVG OVER, ROW_NUMBER OVER) and T-SQL Statistical Functions (STDEV, VAR) for the final calculations. Format all monetary values and statistical results as DECIMAL(18, 2)."



-- Advanced query: Product Sales Trend and Volatility Analysis

-- SQL SERVER 2019 COMPATIBILITY NOTE: The solution MUST AVOID using functions introduced in SQL Server 2022 (e.g., LEAST, GREATEST). Use standard T-SQL CASE expressions for minimum value comparisons."


-- Calculates moving averages, trend indicators, and volatility metrics for each product
-- "Using the SalesLT schema reference (SalesLT.Product, SalesLT.SalesOrderHeader, SalesLT.SalesOrderDetail), generate an advanced T-SQL query to perform a comprehensive historical sales trend and volatility analysis for every product.
-- The query must calculate the following metrics for EACH product, based on monthly sales revenue (Sum of LineTotal):
-- 1. Moving Averages:
--    * 3-Month Rolling Average Sales.
--    * 6-Month Rolling Average Sales.
--    * 12-Month (Annual) Average Sales (where applicable).
-- 2. Trend Indicators: (Eğilim Göstergeleri)
--    * Identify the month and sales amount corresponding to the Highest Sales period.
--    * Identify the month and sales amount corresponding to the Lowest Sales period.
-- 3. Sales Volatility: (Satış Değişkenliği, Satışlardaki İstikrarsızlık)
--    * Calculate the Standard Deviation (STDEV) of monthly sales revenue.
--    * Calculate the Variance (VAR) of monthly sales revenue. (Aylık satış gelirinin Varyansını (VAR) hesapla.)
-- 4. Sales Trend Direction: Determine the general trend of sales (e.g., 'Increasing', 'Decreasing', 'Stable') based on comparing the 3-month average to the 12-month average, or by analyzing recent linear regression (if feasible with T-SQL, otherwise simplify to period comparison).
-- Utilize CTEs to first aggregate sales data by Product and Month, and then apply advanced Window Functions (e.g., AVG OVER, ROW_NUMBER OVER) and T-SQL Statistical Functions (STDEV, VAR) for the final calculations. Format all monetary values and statistical results as DECIMAL(18, 2)."

USE AdventureWorks2019
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
WHERE lt.Recency = 1  -- Get only the most recent month's calculations, Son Değerlere göre olanları filtrelemiş
ORDER BY lt.ProductID;

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
        WHEN (vm.SalesStdDev / vm.AvgMonthlySales) < 0.15 THEN 'Satış İstikrarlı' -- CV < 15%: Very Stable
        WHEN (vm.SalesStdDev / vm.AvgMonthlySales) BETWEEN 0.15 AND 0.35 THEN 'Normal Dalgalanma' -- CV 15%-35%: Normal Fluctuation
        ELSE 'Çok Değişken Satışlar' -- CV > 35%: High Volatility
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
ORDER BY lt.ProductID;


