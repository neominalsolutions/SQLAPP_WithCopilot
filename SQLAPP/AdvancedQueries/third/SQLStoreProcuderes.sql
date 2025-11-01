-- STORE PRODURE NEDIR ?
-- SQL STORE PROCEDURE (SQL STORED PROCEDURE) NEDIR ?
-- SQL Stored Procedure, SQL Server veritabanında saklanan ve belirli bir görevi yerine getiren önceden derlenmiş bir SQL kodu bloğudur.
-- Stored Procedure'ler, veritabanı işlemlerini otomatikleştirmek, kod tekrarını azaltmak ve performansı artırmak için kullanılır.
-- Stored Procedure'ler, parametreler alabilir, kontrol akışı ifadeleri içerebilir ve sonuç setleri döndürebilir.
-- Stored Procedure'ler, SQL Server Management Studio (SSMS) veya T-SQL komutları kullanılarak oluşturulabilir ve yönetilebilir.
-- Stored Procedure'ler, veritabanı sunucusunda saklandıkları için, istemci uygulamalar tarafından çağrılabilir ve kullanılabilir.
-- Stored Procedure'ler, genellikle veri ekleme, güncelleme, silme ve sorgulama işlemlerini gerçekleştirmek için kullanılır.
-- Stored Procedure'ler, güvenlik açısından da avantaj sağlar, çünkü kullanıcıların doğrudan tablo erişimi yerine, belirli işlemleri gerçekleştirmek için prosedürleri çağırmaları sağlanabilir.
-- Aşağıda basit bir Stored Procedure örneği bulunmaktadır:

-- TABLE VALUED FUNCTION BENZERI BIR ÖRNEK

CREATE OR ALTER PROCEDURE GetCustomerByEmail
		@EmailAddress NVARCHAR(255)
AS
BEGIN
		SET NOCOUNT ON; -- Prevent extra result sets from interfering with SELECT statements.
		SELECT * FROM Sales.Customer 
			JOIN Person.Person p ON p.BusinessEntityID = Sales.Customer.PersonID
			JOIN Person.BusinessEntity pb ON p.BusinessEntityID = pb.BusinessEntityID
			JOIN Person.EmailAddress ea ON pb.BusinessEntityID = ea.BusinessEntityID WHERE ea.EmailAddress = @EmailAddress;
END
GO

EXEC GetCustomerByEmail @EmailAddress = 'terri0@adventure-works.com';
SELECT * FROM Person.EmailAddress

-- CREATE INTERMEDIATE LEVEL STORED PROCEDURE WITH IF EXISTS CONDITION RETURN SELECT RUSULTS
-- Öğrendiğimiz herşeyi store procudure içerisinde kullanabiliriz.
GO
CREATE OR ALTER PROCEDURE CheckCustomerExists
		@EmailAddress NVARCHAR(255)
AS
BEGIN
		SET NOCOUNT ON; -- Prevent extra result sets from interfering with SELECT statements.
		IF EXISTS (SELECT 1 FROM Person.EmailAddress WHERE EmailAddress = @EmailAddress)
		BEGIN
				SELECT 'Customer exists with email: ' + @EmailAddress AS Message;
		END
		ELSE
		BEGIN
				SELECT 'No customer found with email: ' + @EmailAddress AS Message;
		END
END
GO
EXEC CheckCustomerExists @EmailAddress = ''

-- SAYFALANDIRILMIŞ SATIŞ SİPARİŞLERİ STORED PROCEDURE
-- Table Valued Function'dan Stored Procedure'e dönüştürülmüş örnek
GO
CREATE OR ALTER PROCEDURE GetPagedSalesOrders
		@PageNumber INT, -- Hangi sayfadayız
		@RowsPerPage INT, -- Sayfa başına satır sayısı 25,50,100,200
		@SortColumn NVARCHAR(50), -- Sıralama yapılacak sütun
		@SortDirection NVARCHAR(4) -- 'ASC' veya 'DESC'
AS
BEGIN
		SET NOCOUNT ON;
		
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
		WHERE RowNum BETWEEN ((@PageNumber - 1) * @RowsPerPage + 1) AND (@PageNumber * @RowsPerPage);
END
GO

-- Kullanım örneği:
EXEC GetPagedSalesOrders @PageNumber = 1, @RowsPerPage = 10, @SortColumn = 'OrderDate', @SortDirection = 'DESC'

GO

-- Sipariş Store Procudure oluşturulalım. Sipariş oluşturulduktan sonra Sipariş ID'sini döndürelim. SiparişID si SalesOrderHeader tablosunda identity olarak tanımlanmıştır. SalesOrderDetail tablosuna ekleme yapabilmek için bu ID'ye ihtiyacımız var. Production.Product tablosundan ürün bilgilerini alalım ve sipariş detaylarını ekleyelim.Sipariş deki adet bilgisini Stoktan düşelim. Bu işlemleri yaparkenden Transaction kullanarak hata durumunda rollback yapalım. Try Catch blokları ile hata yönetimi yapalım. Sipariş edilen ürünün stok değerini kontrol edelim. Yeterli stok yoksa hata mesajı döndürelim. 
GO
CREATE OR ALTER PROCEDURE CreateSalesOrder
		@CustomerID INT, -- Müşteri ID
		@OrderDate DATETIME, -- Sipariş tarihi
		@DueDate DATETIME, -- Teslim tarihi
		@ProductID INT,-- Ürün ID
		@OrderQty INT -- Sipariş edilen adet
AS
BEGIN
		SET NOCOUNT ON; -- Dönen result seti sayma
		DECLARE @SalesOrderID INT; -- Yeni oluşturulan sipariş ID'si için değişken
		DECLARE @AvailableQty INT; -- Mevcut stok miktarı için değişken
		BEGIN TRANSACTION;
		BEGIN TRY
				-- Stok kontrolü
			 SET @AvailableQty = 	(SELECT SUM(pInv.Quantity)  --	Mevcut stok miktarını alıp @AvailableQty değişkenine atıyoruz
				FROM Production.ProductInventory pInv
				WHERE ProductID = @ProductID); -- Farklı lokasyonlardaki stokları topluyoruz.
				
				-- Sipariş başlığı ekleme
				INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, DueDate, Status, OnlineOrderFlag, BillToAddressID, ShipToAddressID, ShipMethodID)
				VALUES (@CustomerID, @OrderDate, @DueDate, 1, 1, 1, 1, 1);

				-- ROLLBACK Kodu girmeye zorlamak için buraya ekleyebilirsiniz.
				IF (@AvailableQty < 0 OR @AvailableQty < @OrderQty) -- Yeterli stok yoksa hata fırlat
				BEGIN
			      PRINT 'HATA ->' +  CAST(@SalesOrderID AS NVARCHAR(10));
						SELECT @SalesOrderID AS NewSalesOrderID; -- Yeni sipariş ID'sini döndür, Program tarafına dönen OrderID değerini alabiliriz.
						-- RAISERROR('Hata oluştu: %s', 16, 1, @ErrorMessage); -- Hata mesajı olarak message döndürüyoruz. Ama bu Catch düşürmez bizi.
						THROW 50001, N'Stok Yetersiz', 1; -- 50001 hata kodu ile THROW kullanarak hata fırlatıyoruz. Bu Catch bloğuna düşer.
				END

				SET @SalesOrderID = SCOPE_IDENTITY(); -- Yeni eklenen siparişin ID'sini al
				-- Sipariş detayı ekleme
				INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, OrderQty, UnitPrice, SpecialOfferID) -- Alt bir select ile insert into ya values dinamik olarak sorgudan çektik.
				SELECT @SalesOrderID, @ProductID, @OrderQty, ListPrice, 1
				FROM Production.Product
				WHERE ProductID = @ProductID;
				-- Stok güncelleme
				UPDATE Production.ProductInventory
				SET Quantity = Quantity - @OrderQty
				WHERE ProductID = @ProductID;
				COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
				ROLLBACK TRANSACTION;
				DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
				RAISERROR('Hata oluştu: %s', 16, 1, @ErrorMessage);
		END CATCH
END
GO


DECLARE @SiparisTarihi DATETIME = GETDATE();
DECLARE @TeslimTarihi DATETIME = DATEADD(DAY, 7, @SiparisTarihi);

-- Kullanım örneği:
EXEC CreateSalesOrder 
		@CustomerID = 1,
		@OrderDate = @SiparisTarihi,
		@DueDate = @TeslimTarihi,
		@ProductID = 10,
		@OrderQty = 10;
-- Not: Ürün ID'si ve Müşteri ID'si veritabanında mevcut olan değerler olmalıdır.

SELECT * FROM Sales.SalesOrderHeader WHERE SalesOrderID = 75130
SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = 75130
SELECT * FROM Production.ProductInventory p WHERE p.Quantity < 0

-- Quantity > 0 CK tanımlı olsaydı direkt olarak hata fırlatacaktı. Bu sebeple IF kontrolü ile 0 < stok kontrolü yaptık.
-- End of Stored Procedure samples

