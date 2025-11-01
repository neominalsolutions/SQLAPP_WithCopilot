
-- write T-SQL declarations and conditional statements and loops sample
DECLARE @Counter INT = 1;
DECLARE @MaxCount INT = 10;
DECLARE @Message NVARCHAR(50);
WHILE @Counter <= @MaxCount
BEGIN
		SET @Message = 'This is message number ' + CAST(@Counter AS NVARCHAR(10));
		PRINT @Message;
		SET @Counter = @Counter + 1;
END
-- End of T-SQL declarations and conditional statements and loops sample
GO
-- write T-SQL error handling sample

-- VIEW, STORED PROCEDURE, FUNCTION, TRIGGER, CURSOR, TEMP TABLE, TABLE VARIABLE samples are in separate files
-- TRANSACTION, TRY...CATCH amacý UPDATE,DELETE, INSERT gibi veri deðiþiklik iþlemlerinde hata yönetimi saðlamaktýr. Hata durumunda veri tabanýndaki kayýtlarýn geri alýnmasý yani ROLLBACK yapýlmasý için kullanýlýr.
-- Hata olmadýðý durumda ise COMMIT ile iþlemler kalýcý hale getirilir.
BEGIN TRANSACTION;
BEGIN TRY
		-- Intentionally cause a divide by zero error
		DECLARE @Numerator INT = 10;
		DECLARE @Denominator INT = 0;
		DECLARE @Result INT;

		INSERT INTO SalesLT.Customer (FirstName, LastName, EmailAddress) VALUES ('John', 'Doe', 'john.doe@example.com');

		SET @Result = @Numerator / @Denominator;
		COMMIT TRANSACTION;

END TRY
BEGIN CATCH
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(@ErrorNumber AS NVARCHAR(10));
		PRINT 'Error Message: ' + @ErrorMessage;
ROLLBACK TRANSACTION;
END CATCH
-- Not: Transaction ifadeleri genel olarak store procedure içinde kullanýlýr.
-- End of T-SQL error handling sample

SELECT * FROM SalesLT.Customer WHERE EmailAddress = 'john.doe@example.com';
GO



-- TRANSACTION ISOLATION LEVEL Nedir ?
-- Transaction Isolation Level, veri tabaný iþlemlerinin birbirleriyle nasýl etkileþime gireceðini belirleyen bir mekanizmadýr.
-- Bu seviye, bir iþlemin diðer iþlemler üzerindeki etkisini kontrol eder ve veri tutarlýlýðýný saðlamak için kullanýlýr.
-- SQL Server'da dört temel izolasyon seviyesi vardýr:
-- 1. READ UNCOMMITTED: Diðer iþlemler tarafýndan yapýlmýþ ancak henüz onaylanmamýþ deðiþiklikleri okumaya izin verir.
-- 2. READ COMMITTED: Sadece onaylanmýþ verileri okumaya izin verir.
-- 3. REPEATABLE READ: Bir iþlem, okuduðu verilerin baþka bir iþlem tarafýndan deðiþtirilmesini engeller.
-- 4. SERIALIZABLE: En yüksek izolasyon seviyesidir. Diðer iþlemlerin okuduðu veya yazdýðý verileri tamamen engeller.
-- DEFAULT Isolation Level SQL Server'da READ COMMITTED'tir.
-- WITH (NOLOCK) Ýfadesi, SQL Server'da kullanýlan bir sorgu ipucudur ve genellikle SELECT sorgularýnda kullanýlýr.
-- Bu ifade, okuma iþlemlerinin diðer iþlemler tarafýndan yapýlan deðiþikliklerden etkilenmemesini saðlar.
-- OPTIMISTIC UPDATE AND PESSIMISTIC UPDATE nedir ?
-- OPTIMISTIC UPDATE: Bu yaklaþýmda, verilerin güncellenmesi sýrasýnda kilitlenme olmaz. Ýþlemler, verilerin deðiþmediðini varsayar ve güncelleme iþlemi sýrasýnda baþka bir iþlem tarafýndan veri deðiþtirilirse, hata oluþur. Bu yöntem, düþük çatýþma olasýlýðý olan senaryolarda kullanýlýr.
-- PESSIMISTIC UPDATE: Bu yaklaþýmda, verilerin güncellenmesi sýrasýnda kilitlenme olur. Ýþlemler, verilerin baþka bir iþlem tarafýndan deðiþtirilmesini engellemek için kilitler kullanýr. Bu yöntem, yüksek çatýþma olasýlýðý olan senaryolarda kullanýlýr.
-- SQL Concurrency 
-- UPDATE Query Hint Samples
BEGIN TRANSACTION;
BEGIN TRY
		-- Using OPTIMISTIC concurrency control, READPAST diyerek okuma iþlemlerine engel olmadýðý için baþka sessionlar bu satýra dokunabilir.
		UPDATE SalesLT.Customer WITH (ROWLOCK, READPAST)
		SET FirstName = 'Jane'
		WHERE CustomerID = 1;
		COMMIT TRANSACTION;

	  -- Using PESSIMISTIC concurrency control, Baþka bir session okuma yada yazma bu satýra dokunamaz.
		
		BEGIN TRANSACTION;
		UPDATE SalesLT.Customer WITH (XLOCK, HOLDLOCK) -- Exclusive lock
		SET FirstName = 'Jane'
		WHERE CustomerID = 1;
		-- Baþka hiçbir session bu satýra dokunamaz
		COMMIT;


END TRY
BEGIN CATCH
		ROLLBACK TRANSACTION;
END CATCH

-- Optimistik güncelleme iþleminde bir satýrý iþlem bitene kadar kilitleyebiliriz.
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- End of TRANSACTION ISOLATION LEVEL sample , SET TRANSACTION ISOLATION LEVEL sample
GO
-- Clean up the test data
-- SERIALIZABLE update edilen verileri yada silinnen verileri okuma ve diðer transactiolar için önemli ise engellemek amaçlý kullanýlýr.
-- Performasý ciddi anlamda düþürebilir.
-- En tutarlý izolasyon seviyesidir.
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
BEGIN TRY
DELETE FROM SalesLT.Customer WHERE EmailAddress = 'john.doe@example.com';	
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
END CATCH
