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
		PRINT 'Yeni kayýt eklendi. LocationID: ' + CAST(@LocationID AS NVARCHAR(10));
	END
	ELSE IF EXISTS(SELECT * FROM DELETED)
	BEGIN
	    PRINT 'Kayýt Silindi';
		SELECT @LocationID = DELETED.LocationID FROM DELETED;
		PRINT 'Yeni kayýt silindi. LocationID: ' + CAST(@LocationID AS NVARCHAR(10));
	END
    -- OVERRIDE iþlemi kayýt geri alýnsýn.
    -- ROLLBACK TRANSACTION; -- Bu satýr, tetikleyicinin yaptýðý iþlemi geri alýr. Gerçek senaryoda bu satýr kaldýrýlmalýdýr.
    INSERT INTO dbo.ProductInventoryLogg (LocationID, LogDate)
    VALUES (@LocationID, GETDATE());
END

-- Triggerin izlediði tabloya bir kayýt girilirse bu kayýt INSERTED tablosuna eklenir.
-- Triggerin izlediði tabloya bir kayýt silinirse bu kayýt DELETED tablosuna eklenir.

CREATE TABLE dbo.ProductInventoryLogg
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    LocationID INT,
    LogDate DATETIME
);

INSERT INTO Production.ProductInventory (ProductID, LocationID, Shelf, Bin, Quantity, rowguid, ModifiedDate) VALUES (708, 5, 'B', 1, 11, NEWID(), GETDATE());
-- Trigger tetiklenir ve ROLLBACK nedeniyle kayýt eklenmez.

SELECT * FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;
DELETE FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;

SELECT * FROM Production.ProductInventory WHERE ProductID = 708 AND LocationID = 5;

SELECT * FROM dbo.ProductInventoryLogg;