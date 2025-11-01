SELECT * INTO TEST_SalesDetails  FROM Sales.SalesOrderDetail

-- index tan�m� olmad���ndan %7 lik bir performans kayb� var
SELECT * FROM TEST_SalesDetails


SELECT * FROM Sales.SalesOrderDetail
SELECT UnitPrice FROM Sales.SalesOrderDetail WHERE Sales.SalesOrderDetail.UnitPrice BETWEEN 100 AND 1000

SELECT * FROM Sales.SalesOrderHeader 

-- Not: Indeksi olan SalesOrderNumber alan�na indeksi olamayan bir PurchaseOrderNumber column ekleyerek select i�lemine tabi tuttuk. bu durumda PurchaseOrderNumber listerken Clustred Index yap�s�na girdi bu sebeple key lookup operat�r maaliyeti olu�tu.
SELECT SalesOrderNumber,PurchaseOrderNumber FROM Sales.SalesOrderHeader WHERE Sales.SalesOrderHeader.SalesOrderNumber = 'SO43660'
-- Ortadan kald�rmak i�in ne yapmal�y�z ? 
-- PurchaseOrderNumber SalesOrderNumber'a include column olarak ba�lanabilir. SalesOrderNumber indeksini bozmay�z ama PurchaseOrderNumber SalesOrderNumber ile birlikte �a��r�ld���nda olu�an key lookup maliyetini ortadan kald�r�r�z.
SELECT SalesOrderNumber,PurchaseOrderNumber,Comment FROM Sales.SalesOrderHeader WHERE Sales.SalesOrderHeader.SalesOrderNumber = 'SO43660'
-- ayn� sorguyu �al��t�r�nca key lookup kurtulduk
-- NVARCHAR(MAX) alanlara indeks at�lamaz bu sebeple bu tarz alanlar� Include Column yapabiliriz.



-- FULL TEXT SEARCH INDEX



-- *** Bu script bir test ortam�nda kullan�lmal�d�r. Ger�ek veritaban�nda kullanmadan �nce yedek alman�z �nerilir. ***

-- 1. Sat�� Sipari� Numaras�n� rastgele bir aral�kta (1'den ba�layarak) g�ncellemek i�in kullan�l�r.
-- Ger�ek tabloda var olan ID'leri kullanman�z gerekti�ini unutmay�n.
DECLARE @CurrentID INT = 1;
DECLARE @TotalUpdates INT = 50;

-- 50 farkl� metin verisi
DECLARE @Comments TABLE (ID INT IDENTITY(43659,1), CommentText NVARCHAR(4000));

INSERT INTO @Comments (CommentText) VALUES
(N'�deme onayland�. **Ayn� g�n kargo** se�ene�i ile HIZLI teslimat planland�. M��teri memnuniyeti bizim i�in �nceliklidir.'),
(N'�r�n stokta (SKU: G2340). Depo 3A, raf 15�ten al�nd�. **�ade politikas�** bilgisi e-posta ile g�nderildi. Kalite kontrol� yap�ld�.'),
(N'Bu sipari�, **�zel indirim kuponu** (DISCOUNT2024) kullan�larak verildi. L�tfen fatura tutar�n� kontrol ediniz. M��teri sadakati y�ksektir.'),
(N'Kargo takip numaras� (TRK9012345) sisteme girildi. Tahmini teslimat s�resi 3-5 i� g�n�d�r. **K�r�labilir �r�n** i�erir, �zenle paketlendi.'),
(N'M��teri hizmetleri ile g�r���ld�; **fatura adresi de�i�ikli�i** talep edildi. Yeni adres: Istanbul/Ata�ehir. **Acil durum** olarak i�aretlendi.'),
(N'Sat�n al�nan **Ergonomik Klavye** hakk�nda teknik destek istendi. Destek talebi ID: TK456. **Garanti s�resi** 2 y�ld�r.'),
(N'B�y�k hacimli sipari�. **Lojistik departman�** taraf�ndan ek ta��ma plan� yap�ld�. M��teri, toplu al�m i�in fiyat teklifi istedi.'),
(N'Sipari�, yeni ��kan **Yapay Zeka** destekli �r�n serisinden. Tan�t�m ama�l� **hediye �eki** eklendi. Pazarlama ekibinin notu: **Beta test**.'),
(N'Teslimatta sorun ya�anmamas� i�in **telefonla teyit** al�nd�. M��teri, kargonun sabah saatlerinde gelmesini �zellikle rica etti. **Hassas ta��ma** gerekli.'),
(N'�deme, **kredi kart� taksitle** yap�ld�. Banka onay kodu: 887766. **�ptal etme** durumu d���k. Stok kontrol� tekrarland�.'),
(N'Bu sipari�, bir �nceki sipari�in **iade ve de�i�im** s�recinden sonra olu�turuldu. M��teriye **ekstra %10 indirim** uyguland�.'),
(N'T�m �r�nler **organik i�erikli** ve **�evre dostu** ambalajla g�nderiliyor. S�rd�r�lebilirlik raporuna dahil edilecek veri.'),
(N'Sistem hatas� nedeniyle sipari� 2 kez kesilmi�. �kinci sipari� **manuel olarak iptal edildi**. M��teri bilgilendirildi. **Sipari� birle�tirme** yap�lmad�.'),
(N'M��teri, **farkl� renk** se�ene�i olup olmad���n� sordu. Sadece mavi ve siyah mevcuttur. **Gelecek ay** yeni renkler eklenecek.'),
(N'�n sipari� �r�n�d�r. Stoklar **gelecek hafta �ar�amba** g�n� bekleniyor. Tahmini kargo tarihi 15.11.2025. **Gecikme uyar�s�** yap�ld�.'),
(N'Sipari�, �irket i�i kullan�m i�in verildi. **Muhasebe departman�** �deme onay� verdi. **Vergi muafiyeti** i�in belge talep edildi.'),
(N'Sat�� temsilcisi (ID: ST005) taraf�ndan girildi. **Komisyon hesaplamas�na** dahil edilmeli. **Y�ksek �ncelikli** m��teri.'),
(N'Teslimat s�ras�nda m��teriye **kurulum k�lavuzu** ve **video linki** verilmesi gerekiyor. Teknik d�k�mantasyon kontrol edildi.'),
(N'M��teri, **rakiplerin fiyatlar�n�** kar��la�t�rd�. �zel fiyat garantisi ile sat�ld�. **Rekabet analizi** verilerine kaydedildi.'),
(N'Bu sipari�in **risk skoru y�ksektir**; �deme teyidi bankadan bekleniyor. Doland�r�c�l�k tespiti (Fraud Detection) aktif edildi.'),
(N'**Eski model** bir �r�n sipari� edildi. **Yedek par�a** olarak kullan�lacak. M��teri, �r�n�n nadir oldu�unu biliyor. **�zel ilgi** g�sterilmesi gerekiyor.'),
(N'Kargo �irketi olarak **Yurti�i Kargo** se�ildi. Di�er kargo �irketleri bu b�lgeye teslimat yapm�yor. **Teslimat b�lgesi** k�s�tl�.'),
(N'M��teri, �r�n� teslim alacak ki�i ad�n� **farkl�** belirtti (Ahmet Y�lmaz). Kimlik kontrol� gerekli. **Vekaletname** kontrol�.'),
(N'Sipari�, **��le yeme�i tatilinde** sisteme girildi. M��teri, h�zl� cevap bekliyor. **Mesai saatleri** d���nda i�lem yap�ld�.'),
(N'**Promosyon kodu** ge�erlili�ini yitirmi�ti, ancak m��teri sadakati nedeniyle **manuel indirim** uyguland�. **�stisnai durum**.'),
(N'�r�n, **uzun s�reli depolama** sonras� g�nderildi. Kontrol edildi, **son kullanma tarihi** uygun. **Depo notu** eklendi.'),
(N'Bu sipari� i�in **�zel bir not** var: Paket �zerine **do�um g�n� hediyesi** yaz�lacak. Ambalajlama ekibi bilgilendirildi.'),
(N'Fiziksel ma�azadan al�nan ve **online sistemden faturalanan** bir sipari�tir. Fiziksel stoktan d���ld�. **Omni-channel** sat��.'),
(N'M��teri, **sipari� ge�mi�ini** kontrol ederek tekrar sipari� verdi. **Tekrarlayan m��teri** (Repeat Customer).'),
(N'**Para iadesi** yap�ld�ktan sonra ayn� �r�n� tekrar sipari� etti. �nceki iadenin nedeni **kargo hasar�** idi.'),
(N'Bu sipari�, 10 farkl� **alt �r�n** i�eriyor. **Karma��k paketleme** s�reci. Her birinin stok kodu (SKU) ayr� ayr� kontrol edildi.'),
(N'**Sezon sonu indirimi** �r�n�d�r. Stokta kalan son 3 adet. **Maliyet analizi** d���k k�r marj� g�steriyor.'),
(N'M��teri, **cep telefonu** ile sipari� verdi. **Mobil optimizasyon**un ba�ar�s�. D�n���m oranlar�na dahil edildi.'),
(N'**Yurt d��� teslimat** adresi i�eriyor. **G�mr�k beyannamesi** ve **ihracat prosed�rleri** ba�lat�ld�. **Uluslararas� sat��**.'),
(N'**�zel �retim** (customize) bir �r�n talebi var. �retim band�na **ek talimatlar** g�nderildi. Teslimat s�resi uzayacak.'),
(N'Bu sipari�, **e�itim materyali** olarak kullan�lacak. M��teri, bir �niversite veya okul. **Kurumsal sat��** kategorisinde.'),
(N'**M��teri Yorumu:** "M�kemmel hizmet, sipari�imi 24 saatten k�sa s�rede teslim ald�m." **Pozitif geri bildirim** al�nd�.'),
(N'Sat�n al�nan **ak�ll� saat** i�in **yaz�l�m g�ncelleme** bildirimi g�nderilmeli. Sat�� sonras� destek ekibi ilgilenecek.'),
(N'Sipari�, **hafta sonu** girildi. Pazartesi ilk i� olarak i�leme al�nacak. **Aciliyet** normal. Hafta sonu takibi.'),
(N'M��teri, **�deme y�ntemini** son anda **havale** olarak de�i�tirdi. �deme dekontu teyit edildi. **Finansal kontrol** yap�ld�.'),
(N'**�r�ne �zel montaj hizmeti** sat�n al�nd�. Teknik ekip randevu i�in m��teriyi arayacak. **Servis randevusu** olu�turuldu.'),
(N'M��teri, sipari�inin **gizli kalmas�n�** istedi. Paket �zerinde �irket logosu veya ismi olmayacak. **Anonim g�nderi** talebi.'),
(N'Sipari� tutar� **y�ksek**. Y�netim onay� (Manager Approval) al�nd�ktan sonra sevk edilecek. **�st d�zey m��teri**.'),
(N'**Demo** �r�n� indirimli fiyattan sat�ld�. �r�nde **k���k kozmetik hasar** olabilir. M��teri bilgilendirildi ve kabul etti.'),
(N'M��teri, **sosyal medya** �zerinden bir kampanya g�rerek geldi. **Kampanya kodu**: INSTA50. **Dijital pazarlama** takibi.'),
(N'**�kinci el** (Refurbished) kategorisinden bir �r�n sipari�i. **6 ay garanti** kapsam�ndad�r. **Yenilenmi� �r�n** stoku.'),
(N'**Tedarik zinciri** hatas� nedeniyle bu �r�n�n tedari�i 3 g�n gecikti. M��teriye **�z�r e-postas�** g�nderildi. **��letme riski** minimize edildi.'),
(N'Bu sipari�teki t�m �r�nler **ayn� renkte** (k�rm�z�) talep edildi. Stokta yeterli k�rm�z� �r�n var. **Renk tercihi** notu.'),
(N'M��teri, **s�k�a sorulan sorular (SSS)** b�l�m�ndeki bir hatay� bildirdi. Sipari�le birlikte **te�ekk�r notu** eklendi. **Web sitesi hatas�**.'),
(N'**B�lgesel da��t�m merkezi** (�zmir) �zerinden sevk edilecek. �stanbul deposu bu �r�n� tutmuyor. **Da��t�m optimizasyonu**.')
;

-- UPDATE ��LEM�N� GER�EKLE�T�RME
-- NOT: Bu UPDATE i�lemi, `SalesOrderHeader` tablosundaki mevcut sipari�lerin Comment s�tununu rastgele g�ncelleyecektir.
-- Ger�ek AdventureWorksLT2019 veritaban�nda SalesOrderID genellikle 71774'ten ba�lar. Bu script'i kullanmadan �nce ID'leri kontrol edin.

WITH RankedComments AS (
    SELECT
        CommentText,
        ID
    FROM @Comments
)
UPDATE soh
SET soh.Comment = rc.CommentText
FROM Sales.SalesOrderHeader soh
INNER JOIN RankedComments rc ON soh.SalesOrderID = rc.ID

-- ��lem tamamland� mesaj�
SELECT 'Sales.SalesOrderHeader tablosundaki ilk ' + CAST(@TotalUpdates AS NVARCHAR(10)) + ' sipari�in Comment s�tunu g�ncellendi.' AS Sonuc;



SELECT * FROM Sales.SalesOrderHeader



SELECT * INTO TEST_SalesOrderHeader FROM  Sales.SalesOrderHeader

-- c�mle olarak da arama yapabilir. iadew de�i�im iade de�i�im
SELECT *
FROM TEST_SalesOrderHeader
WHERE FREETEXT(Comment, '**iade de�i�im**');

-- Sadece kelime kelime aram yapar
-- like gibi �al���r iade veya de�i�im olanlar� getirir.
SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'iade') AND CONTAINS(Comment,'de�i�im');


SELECT *
FROM TEST_SalesOrderHeader
WHERE Comment LIKE '%iade%' OR Comment LIKE '%degisim%'


-- FULLTEXT SEARH ---

-- FREETEXT, belirli bir kelimeyi ya da kelime grubunu esnek bir �ekilde arar.
-- T�revler (kelime k�kleri, ekler) ve yak�n e�le�meler dikkate al�n�r. Yani, "developer" kelimesi, "developers", "developing", "developed" gibi t�revlerle de e�le�ir.

-- Kesin Arama (Exact Match): CONTAINS, belirli bir kelime veya kelime grubunu kesin olarak arar.
-- Belirtilen kelimenin ya da kelime grubunun veritaban�nda tam olarak ge�mesi gerekir.
-- CONTAINS, daha detayl� ve kesin aramalar yapman�za olanak tan�r. Ayr�ca, wildcard'lar (joker karakterler) ve Boolean operat�rleri gibi daha esnek arama yapman�za imkan verir.

SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'iade OR degisim')

-- Joker karakter aramas�
SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'kargo*') -- "developer", "developers", "developing" 


SELECT * FROM HumanResources.EmployeePayHistory



-- �al��aca��m�z veritaban�n� se�elim
USE AdventureWorks2019;
GO

-------------------------------------------
-- 1. DROP INDEX (�ndeksi Silme)
-------------------------------------------

-- Bir indeksi kal�c� olarak siler.
-- Dikkat: Bu i�lem geri al�namaz.

-- S�z Dizimi:
-- DROP INDEX [�ndeksAd�] ON [�emaAd�].[TabloAd�];

DROP INDEX IF EXISTS [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader];
GO

-- �ndeksi silmeden �nce kontrol i�in, e�er daha �nce sildiyseniz tekrar olu�tural�m:
CREATE NONCLUSTERED INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] ([CustomerID]);
GO

-------------------------------------------
-- 2. DISABLE INDEX (�ndeksi Devre D��� B�rakma)
-------------------------------------------

-- �ndeksi devre d��� b�rak�r. �ndeks verisi diskte kal�r ancak kullan�lamaz 
-- ve g�ncellenmez. �ndeks anahtarlar� �zerindeki birincil veya benzersiz k�s�tlamalar (Primary/Unique Key) devre d��� b�rak�lmaz.

-- S�z Dizimi:
-- ALTER INDEX [�ndeksAd�] ON [�emaAd�].[TabloAd�] DISABLE;

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
DISABLE;
GO

-- �ndeksin durumunu kontrol etme: is_disabled s�tunu 1 olmal�d�r.
SELECT 
    name, 
    is_disabled
FROM 
    sys.indexes 
WHERE 
    object_id = OBJECT_ID('Sales.SalesOrderHeader') 
    AND name = 'IX_SalesOrderHeader_CustomerID';
GO

-- INDEX SCRIPTS

-------------------------------------------
-- 3. REBUILD INDEX (�ndeksi Yeniden Olu�turma)
-------------------------------------------

-- �ndeksi silip ba�tan olu�turur. �ndeksin fragmentation'�n� (par�alanmas�n�) ortadan kald�r�r. 
-- Devre d��� b�rak�lm�� bir indeksi tekrar kullan�labilir hale getirmenin tek yolu REBUILD etmektir.
-- Bu i�lem genellikle bir kesinti (downtime) gerektirir, ancak ONLINE se�ene�i ile kesintisiz yap�labilir (Enterprise veya Developer s�r�m� gerektirir).

-- S�z Dizimi:
-- ALTER INDEX [�ndeksAd�] ON [�emaAd�].[TabloAd�] REBUILD [WITH (...)];

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
REBUILD 
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, ONLINE = ON); 
-- ONLINE = ON �zelli�i, i�lem s�ras�nda tabloya eri�imi s�rd�rmeyi sa�lar.

-- �ndeks art�k etkin olmal�d�r (is_disabled s�tunu 0 olmal�d�r).
SELECT 
    name, 
    is_disabled
FROM 
    sys.indexes 
WHERE 
    object_id = OBJECT_ID('Sales.SalesOrderHeader') 
    AND name = 'IX_SalesOrderHeader_CustomerID';
GO

-------------------------------------------
-- 4. REORGANIZE INDEX (�ndeksi Yeniden D�zenleme)
-------------------------------------------

-- �ndeks yaprak d�zeyindeki sayfalar� mant�ksal s�raya g�re yeniden d�zenler. 
-- �ok par�alanm�� (fragmented) indeksler i�in REBUILD'e g�re daha hafif bir i�lemdir.
-- Her zaman �evrimi�i (ONLINE) olarak �al���r, yani tabloya eri�imi engellemez. 
-- Genellikle d���k veya orta d�zeyde par�alanma i�in kullan�l�r (%5 ile %30 aras�).

-- S�z Dizimi:
-- ALTER INDEX [�ndeksAd�] ON [�emaAd�].[TabloAd�] REORGANIZE;

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
REORGANIZE;
GO

-------------------------------------------
-- BONUS: T�m �ndeksleri Y�netme
-------------------------------------------

-- Tablodaki t�m indeksleri yeniden olu�turma
ALTER INDEX ALL 
ON [Sales].[SalesOrderHeader] 
REBUILD 
WITH (SORT_IN_TEMPDB = ON);
GO

-- Tablodaki t�m indeksleri yeniden d�zenleme
ALTER INDEX ALL 
ON [Sales].[SalesOrderHeader] 
REORGANIZE;
GO


-- INDEX FRAGMENTATION VIEWS ----

-- ROW STORE INDEX
-- CLUSTERED INDEX PK alanlar i�in
-- NON_CLUSTRED INDEX FK ve di�er alanlar i�in
-- UNIQUE INDEX
-- COMPOSITE_INDEX
-- FILTERED INDEX
-- FULL TEXT SEARCH

-- HANGI DURUMLARDA INDEKS KULLANMAYALIM

-- K���k tablolarda gereksiz
-- �ok fazla INSERT, UPDATE, DELETE olan tablolarda �ok fazla indeks kullan�m� performas sorunu yarat�r
-- Bir tabloda az say�da sutun varsa kullan�m� performans sa�lamayabilir
-- �ng�r�lemeyen sorgularda gereksiz yere indeks tan�m� yapmayal�m.
-- S�ralama ve Gruplama i�lemlerinin oldu�u tablolarda dikkatli olal�m.
-- IMAGE, TEXT ,NTEXT, NVARCHAR(MAX),JSON indekslenmez bu tipleri olabildi�ince kullanmayal�m.

GO
CREATE OR ALTER VIEW  FRAGMENTATIONVIEW
AS
SELECT dbschemas.[name] as 'Schema', dbtables.[name] as 'Table', dbindexes.[name] as 'Index', indexstats.avg_fragmentation_in_percent as fragmentation, indexstats.page_count as pageCount
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id] 
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id] 
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id] AND indexstats.index_id = dbindexes.index_id WHERE indexstats.database_id = DB_ID() 


SELECT * FROM FRAGMENTATIONVIEW

-- Tablo �zerinde Indekslerin Ne kadarl�k bir alan kaplad���
exec sp_spaceused 'Sales.SalesOrderHeader'

