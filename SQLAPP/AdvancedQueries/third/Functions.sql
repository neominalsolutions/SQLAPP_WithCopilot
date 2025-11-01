-- SUM,COUNT,AVG,MIN,MAX AGGREGATE FUNCTIONS
-- STRING FUNCTIONS LEN,TRIM,UPPER,LOWER,SUBSTRING,REPLACE,CHARINDEX
-- DATE FUNCTIONS GETDATE,DATEADD,DATEDIFF,DAY,MONTH,YEAR
-- NUMERIC FUNCTIONS ROUND,CEILING,FLOOR,ABS

-- USER DEFINED FUNCTIONS 
-- SCALAR FUNCTION
-- TABLE VALUED FUNCTION
-- SCALAR FUNCTION SAMPLE
CREATE FUNCTION dbo.ufn_GetFullName -- FUNCTION NAME
(
		@FirstName NVARCHAR(50),
		@LastName NVARCHAR(50)
)
RETURNS NVARCHAR(101) -- FUNCTION RETURN TYPE
AS
BEGIN
		DECLARE @FullName NVARCHAR(101);
		SET @FullName = RTRIM(LTRIM(@FirstName)) + ' ' + RTRIM(LTRIM(@LastName));
		RETURN @FullName; -- RETURNING THE FULL NAME RESULT
END
GO
-- SCALAR FUNCTION SAMPLE USAGE
SELECT dbo.ufn_GetFullName(pe.FirstName, pe.LastName) AS FullName, *
FROM Sales.Customer JOIN Person.BusinessEntity p ON Sales.Customer.PersonID = p.BusinessEntityID
JOIN Person.Person pe ON p.BusinessEntityID = pe.BusinessEntityID;


SELECT RTRIM(LTRIM(pe.FirstName)) + ' ' + RTRIM(LTRIM(pe.LastName)) AS FullName, *
FROM Sales.Customer JOIN Person.BusinessEntity p ON Sales.Customer.PersonID = p.BusinessEntityID
JOIN Person.Person pe ON p.BusinessEntityID = pe.BusinessEntityID;

-- NOT : Execution Plan açýsýnda bir fark yok olarak gözlemledik.


SELECT dbo.ufnGetAccountingStartDate(),* FROM Sales.SalesOrderHeader s
WHERE s.TotalDue > 1000;

SELECT CONVERT(datetime, s.DueDate, 112),* FROM Sales.SalesOrderHeader s
WHERE s.TotalDue > 1000;

-- TABLE VALUED FUNCTION SAMPLE
SELECT * FROM dbo.ufnGetContactInformation(1);

-- TABLE VALUED FUNCTION SAMPLE DEFINITION, GET SALES ORDER BY ORDERNUMBER
GO
CREATE FUNCTION dbo.ufnGetSalesOrderByOrderNumber
(
		@OrderNumber NVARCHAR(25) -- INPUT PARAMETER
)
RETURNS TABLE -- RETURN TYPE, TABLE VALUED FUNCTION
AS
RETURN
(	

		SELECT sohd.SalesOrderID, sohd.OrderDate, sohd.DueDate, sohd.TotalDue, c.FirstName, c.LastName
		FROM Sales.SalesOrderHeader sohd
		JOIN Sales.Customer sc ON sohd.CustomerID = sc.CustomerID
		JOIN Person.Person c ON sc.PersonID = c.BusinessEntityID
		WHERE sohd.SalesOrderNumber = @OrderNumber -- Filtering by Order Number
);
GO

SELECT * FROM dbo.ufnGetSalesOrderByOrderNumber('SO43659');


-- ADVANCED SEARCHING,PAGING,FILTERING,SORTING ORDER BY DYNAMIC COLUMNS USING TABLE VALUED FUNCTIONS
GO
CREATE FUNCTION dbo.ufnGetPagedSalesOrders
(
		@PageNumber INT, -- Hangi sayfadayýz
		@RowsPerPage INT, -- Sayfa baþýna satýr sayýsý 25,50,100,200
		@SortColumn NVARCHAR(50), -- Sýralama yapýlacak sütun
		@SortDirection NVARCHAR(4) -- 'ASC' veya 'DESC'
)
RETURNS TABLE
AS
RETURN
(
		WITH OrderedSalesOrders AS
		(
				SELECT 
						sohd.SalesOrderID,
						sohd.OrderDate,
						sohd.TotalDue,
						c.FirstName,
						c.LastName,
						ROW_NUMBER() OVER (
								ORDER BY 
								CASE WHEN @SortColumn = 'OrderDate' AND @SortDirection = 'ASC' THEN sohd.OrderDate END ASC,
								CASE WHEN @SortColumn = 'OrderDate' AND @SortDirection = 'DESC' THEN sohd.OrderDate END DESC,
								CASE WHEN @SortColumn = 'TotalDue' AND @SortDirection = 'ASC' THEN sohd.TotalDue END ASC,
								CASE WHEN @SortColumn = 'TotalDue' AND @SortDirection = 'DESC' THEN sohd.TotalDue END DESC
						) AS RowNum
				FROM Sales.SalesOrderHeader sohd
				JOIN Sales.Customer sc ON sohd.CustomerID = sc.CustomerID
				JOIN Person.Person c ON sc.PersonID = c.BusinessEntityID
		)
		SELECT 
				SalesOrderID,
				OrderDate,
				TotalDue,
				FirstName,
				LastName
		FROM OrderedSalesOrders
		WHERE RowNum BETWEEN ((@PageNumber - 1) * @RowsPerPage + 1) AND (@PageNumber * @RowsPerPage)
);
GO
-- USAGE EXAMPLE
SELECT * FROM dbo.ufnGetPagedSalesOrders(2, 5, 'TotalDue', 'DESC');
SELECT * FROM dbo.ufnGetPagedSalesOrders(1, 10, 'TotalDue', 'DESC');
-- NOT: Dinamik sýralama için CASE WHEN kullanýmý performans açýsýndan ideal deðildir. Daha karmaþýk senaryolar için dinamik SQL kullanýmý tercih edilebilir.
-- END OF USER DEFINED FUNCTIONS SAMPLE




