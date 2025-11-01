
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
-- TRANSACTION, TRY...CATCH amac� UPDATE,DELETE, INSERT gibi veri de�i�iklik i�lemlerinde hata y�netimi sa�lamakt�r. Hata durumunda veri taban�ndaki kay�tlar�n geri al�nmas� yani ROLLBACK yap�lmas� i�in kullan�l�r.
-- Hata olmad��� durumda ise COMMIT ile i�lemler kal�c� hale getirilir.
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
-- Not: Transaction ifadeleri genel olarak store procedure i�inde kullan�l�r.
-- End of T-SQL error handling sample

SELECT * FROM SalesLT.Customer WHERE EmailAddress = 'john.doe@example.com';
GO



-- TRANSACTION ISOLATION LEVEL Nedir ?
-- Transaction Isolation Level, veri taban� i�lemlerinin birbirleriyle nas�l etkile�ime girece�ini belirleyen bir mekanizmad�r.
-- Bu seviye, bir i�lemin di�er i�lemler �zerindeki etkisini kontrol eder ve veri tutarl�l���n� sa�lamak i�in kullan�l�r.
-- SQL Server'da d�rt temel izolasyon seviyesi vard�r:
-- 1. READ UNCOMMITTED: Di�er i�lemler taraf�ndan yap�lm�� ancak hen�z onaylanmam�� de�i�iklikleri okumaya izin verir.
-- 2. READ COMMITTED: Sadece onaylanm�� verileri okumaya izin verir.
-- 3. REPEATABLE READ: Bir i�lem, okudu�u verilerin ba�ka bir i�lem taraf�ndan de�i�tirilmesini engeller.
-- 4. SERIALIZABLE: En y�ksek izolasyon seviyesidir. Di�er i�lemlerin okudu�u veya yazd��� verileri tamamen engeller.
-- DEFAULT Isolation Level SQL Server'da READ COMMITTED'tir.
-- WITH (NOLOCK) �fadesi, SQL Server'da kullan�lan bir sorgu ipucudur ve genellikle SELECT sorgular�nda kullan�l�r.
-- Bu ifade, okuma i�lemlerinin di�er i�lemler taraf�ndan yap�lan de�i�ikliklerden etkilenmemesini sa�lar.
-- OPTIMISTIC UPDATE AND PESSIMISTIC UPDATE nedir ?
-- OPTIMISTIC UPDATE: Bu yakla��mda, verilerin g�ncellenmesi s�ras�nda kilitlenme olmaz. ��lemler, verilerin de�i�medi�ini varsayar ve g�ncelleme i�lemi s�ras�nda ba�ka bir i�lem taraf�ndan veri de�i�tirilirse, hata olu�ur. Bu y�ntem, d���k �at��ma olas�l��� olan senaryolarda kullan�l�r.
-- PESSIMISTIC UPDATE: Bu yakla��mda, verilerin g�ncellenmesi s�ras�nda kilitlenme olur. ��lemler, verilerin ba�ka bir i�lem taraf�ndan de�i�tirilmesini engellemek i�in kilitler kullan�r. Bu y�ntem, y�ksek �at��ma olas�l��� olan senaryolarda kullan�l�r.
-- SQL Concurrency 
-- UPDATE Query Hint Samples
BEGIN TRANSACTION;
BEGIN TRY
		-- Using OPTIMISTIC concurrency control, READPAST diyerek okuma i�lemlerine engel olmad��� i�in ba�ka sessionlar bu sat�ra dokunabilir.
		UPDATE SalesLT.Customer WITH (ROWLOCK, READPAST)
		SET FirstName = 'Jane'
		WHERE CustomerID = 1;
		COMMIT TRANSACTION;

	  -- Using PESSIMISTIC concurrency control, Ba�ka bir session okuma yada yazma bu sat�ra dokunamaz.
		
		BEGIN TRANSACTION;
		UPDATE SalesLT.Customer WITH (XLOCK, HOLDLOCK) -- Exclusive lock
		SET FirstName = 'Jane'
		WHERE CustomerID = 1;
		-- Ba�ka hi�bir session bu sat�ra dokunamaz
		COMMIT;


END TRY
BEGIN CATCH
		ROLLBACK TRANSACTION;
END CATCH

-- Optimistik g�ncelleme i�leminde bir sat�r� i�lem bitene kadar kilitleyebiliriz.
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- End of TRANSACTION ISOLATION LEVEL sample , SET TRANSACTION ISOLATION LEVEL sample
GO
-- Clean up the test data
-- SERIALIZABLE update edilen verileri yada silinnen verileri okuma ve di�er transactiolar i�in �nemli ise engellemek ama�l� kullan�l�r.
-- Performas� ciddi anlamda d���rebilir.
-- En tutarl� izolasyon seviyesidir.
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
BEGIN TRY
DELETE FROM SalesLT.Customer WHERE EmailAddress = 'john.doe@example.com';	
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
END CATCH
