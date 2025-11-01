DROP TRIGGER IF EXISTS trgAfterInsert;
GO
CREATE OR ALTER TRIGGER trgAfterInsert ON Production.ProductInventory
AFTER INSERT -- ,UPDATE,DELETE
 
 -- Trigger tipi: AFTER (INSERT,DELETE,UPDATE), INSTEAD OF
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocationID INT;

	IF EXISTS(SELECT * FROM INSERTED)
	BEGIN 
	    SELECT @LocationID = INSERTED.LocationID FROM INSERTED;
		PRINT 'Yeni kay�t eklendi. LocationID: ' + CAST(@LocationID AS NVARCHAR(10));
	END
	ELSE IF EXISTS(SELECT * FROM DELETED)
	BEGIN
	    PRINT 'Kay�t Silindi';
		SELECT @LocationID = DELETED.LocationID FROM DELETED;
		PRINT 'Yeni kay�t silindi. LocationID: ' + CAST(@LocationID AS NVARCHAR(10));
	END
    -- OVERRIDE i�lemi kay�t geri al�ns�n.
    -- ROLLBACK TRANSACTION; -- Bu sat�r, tetikleyicinin yapt��� i�lemi geri al�r. Ger�ek senaryoda bu sat�r kald�r�lmal�d�r.
    INSERT INTO dbo.ProductInventoryLogg (LocationID, LogDate)
    VALUES (@LocationID, GETDATE());
END

-- Triggerin izledi�i tabloya bir kay�t girilirse bu kay�t INSERTED tablosuna eklenir.
-- Triggerin izledi�i tabloya bir kay�t silinirse bu kay�t DELETED tablosuna eklenir.

CREATE TABLE dbo.ProductInventoryLogg
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    LocationID INT,
    LogDate DATETIME
);

INSERT INTO Production.ProductInventory (ProductID, LocationID, Shelf, Bin, Quantity, rowguid, ModifiedDate) VALUES (708, 5, 'B', 1, 11, NEWID(), GETDATE());
-- Trigger tetiklenir ve ROLLBACK nedeniyle kay�t eklenmez.

SELECT * FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;
DELETE FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;

SELECT * FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;

SELECT * FROM dbo.ProductInventoryLogg;