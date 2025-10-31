SELECT * INTO TEST_SalesDetails  FROM Sales.SalesOrderDetail

-- index tanýmý olmadýðýndan %7 lik bir performans kaybý var
SELECT * FROM TEST_SalesDetails


SELECT * FROM Sales.SalesOrderDetail
SELECT UnitPrice FROM Sales.SalesOrderDetail WHERE Sales.SalesOrderDetail.UnitPrice BETWEEN 100 AND 1000

SELECT * FROM Sales.SalesOrderHeader 

-- Not: Indeksi olan SalesOrderNumber alanýna indeksi olamayan bir PurchaseOrderNumber column ekleyerek select iþlemine tabi tuttuk. bu durumda PurchaseOrderNumber listerken Clustred Index yapýsýna girdi bu sebeple key lookup operatör maaliyeti oluþtu.
SELECT SalesOrderNumber,PurchaseOrderNumber FROM Sales.SalesOrderHeader WHERE Sales.SalesOrderHeader.SalesOrderNumber = 'SO43660'
-- Ortadan kaldýrmak için ne yapmalýyýz ? 
-- PurchaseOrderNumber SalesOrderNumber'a include column olarak baðlanabilir. SalesOrderNumber indeksini bozmayýz ama PurchaseOrderNumber SalesOrderNumber ile birlikte çaðýrýldýðýnda oluþan key lookup maliyetini ortadan kaldýrýrýz.
SELECT SalesOrderNumber,PurchaseOrderNumber,Comment FROM Sales.SalesOrderHeader WHERE Sales.SalesOrderHeader.SalesOrderNumber = 'SO43660'
-- ayný sorguyu çalýþtýrýnca key lookup kurtulduk
-- NVARCHAR(MAX) alanlara indeks atýlamaz bu sebeple bu tarz alanlarý Include Column yapabiliriz.



-- FULL TEXT SEARCH INDEX



-- *** Bu script bir test ortamýnda kullanýlmalýdýr. Gerçek veritabanýnda kullanmadan önce yedek almanýz önerilir. ***

-- 1. Satýþ Sipariþ Numarasýný rastgele bir aralýkta (1'den baþlayarak) güncellemek için kullanýlýr.
-- Gerçek tabloda var olan ID'leri kullanmanýz gerektiðini unutmayýn.
DECLARE @CurrentID INT = 1;
DECLARE @TotalUpdates INT = 50;

-- 50 farklý metin verisi
DECLARE @Comments TABLE (ID INT IDENTITY(43659,1), CommentText NVARCHAR(4000));

INSERT INTO @Comments (CommentText) VALUES
(N'Ödeme onaylandý. **Ayný gün kargo** seçeneði ile HIZLI teslimat planlandý. Müþteri memnuniyeti bizim için önceliklidir.'),
(N'Ürün stokta (SKU: G2340). Depo 3A, raf 15’ten alýndý. **Ýade politikasý** bilgisi e-posta ile gönderildi. Kalite kontrolü yapýldý.'),
(N'Bu sipariþ, **özel indirim kuponu** (DISCOUNT2024) kullanýlarak verildi. Lütfen fatura tutarýný kontrol ediniz. Müþteri sadakati yüksektir.'),
(N'Kargo takip numarasý (TRK9012345) sisteme girildi. Tahmini teslimat süresi 3-5 iþ günüdür. **Kýrýlabilir ürün** içerir, özenle paketlendi.'),
(N'Müþteri hizmetleri ile görüþüldü; **fatura adresi deðiþikliði** talep edildi. Yeni adres: Istanbul/Ataþehir. **Acil durum** olarak iþaretlendi.'),
(N'Satýn alýnan **Ergonomik Klavye** hakkýnda teknik destek istendi. Destek talebi ID: TK456. **Garanti süresi** 2 yýldýr.'),
(N'Büyük hacimli sipariþ. **Lojistik departmaný** tarafýndan ek taþýma planý yapýldý. Müþteri, toplu alým için fiyat teklifi istedi.'),
(N'Sipariþ, yeni çýkan **Yapay Zeka** destekli ürün serisinden. Tanýtým amaçlý **hediye çeki** eklendi. Pazarlama ekibinin notu: **Beta test**.'),
(N'Teslimatta sorun yaþanmamasý için **telefonla teyit** alýndý. Müþteri, kargonun sabah saatlerinde gelmesini özellikle rica etti. **Hassas taþýma** gerekli.'),
(N'Ödeme, **kredi kartý taksitle** yapýldý. Banka onay kodu: 887766. **Ýptal etme** durumu düþük. Stok kontrolü tekrarlandý.'),
(N'Bu sipariþ, bir önceki sipariþin **iade ve deðiþim** sürecinden sonra oluþturuldu. Müþteriye **ekstra %10 indirim** uygulandý.'),
(N'Tüm ürünler **organik içerikli** ve **çevre dostu** ambalajla gönderiliyor. Sürdürülebilirlik raporuna dahil edilecek veri.'),
(N'Sistem hatasý nedeniyle sipariþ 2 kez kesilmiþ. Ýkinci sipariþ **manuel olarak iptal edildi**. Müþteri bilgilendirildi. **Sipariþ birleþtirme** yapýlmadý.'),
(N'Müþteri, **farklý renk** seçeneði olup olmadýðýný sordu. Sadece mavi ve siyah mevcuttur. **Gelecek ay** yeni renkler eklenecek.'),
(N'Ön sipariþ ürünüdür. Stoklar **gelecek hafta Çarþamba** günü bekleniyor. Tahmini kargo tarihi 15.11.2025. **Gecikme uyarýsý** yapýldý.'),
(N'Sipariþ, þirket içi kullaným için verildi. **Muhasebe departmaný** ödeme onayý verdi. **Vergi muafiyeti** için belge talep edildi.'),
(N'Satýþ temsilcisi (ID: ST005) tarafýndan girildi. **Komisyon hesaplamasýna** dahil edilmeli. **Yüksek öncelikli** müþteri.'),
(N'Teslimat sýrasýnda müþteriye **kurulum kýlavuzu** ve **video linki** verilmesi gerekiyor. Teknik dökümantasyon kontrol edildi.'),
(N'Müþteri, **rakiplerin fiyatlarýný** karþýlaþtýrdý. Özel fiyat garantisi ile satýldý. **Rekabet analizi** verilerine kaydedildi.'),
(N'Bu sipariþin **risk skoru yüksektir**; ödeme teyidi bankadan bekleniyor. Dolandýrýcýlýk tespiti (Fraud Detection) aktif edildi.'),
(N'**Eski model** bir ürün sipariþ edildi. **Yedek parça** olarak kullanýlacak. Müþteri, ürünün nadir olduðunu biliyor. **Özel ilgi** gösterilmesi gerekiyor.'),
(N'Kargo þirketi olarak **Yurtiçi Kargo** seçildi. Diðer kargo þirketleri bu bölgeye teslimat yapmýyor. **Teslimat bölgesi** kýsýtlý.'),
(N'Müþteri, ürünü teslim alacak kiþi adýný **farklý** belirtti (Ahmet Yýlmaz). Kimlik kontrolü gerekli. **Vekaletname** kontrolü.'),
(N'Sipariþ, **öðle yemeði tatilinde** sisteme girildi. Müþteri, hýzlý cevap bekliyor. **Mesai saatleri** dýþýnda iþlem yapýldý.'),
(N'**Promosyon kodu** geçerliliðini yitirmiþti, ancak müþteri sadakati nedeniyle **manuel indirim** uygulandý. **Ýstisnai durum**.'),
(N'Ürün, **uzun süreli depolama** sonrasý gönderildi. Kontrol edildi, **son kullanma tarihi** uygun. **Depo notu** eklendi.'),
(N'Bu sipariþ için **özel bir not** var: Paket üzerine **doðum günü hediyesi** yazýlacak. Ambalajlama ekibi bilgilendirildi.'),
(N'Fiziksel maðazadan alýnan ve **online sistemden faturalanan** bir sipariþtir. Fiziksel stoktan düþüldü. **Omni-channel** satýþ.'),
(N'Müþteri, **sipariþ geçmiþini** kontrol ederek tekrar sipariþ verdi. **Tekrarlayan müþteri** (Repeat Customer).'),
(N'**Para iadesi** yapýldýktan sonra ayný ürünü tekrar sipariþ etti. Önceki iadenin nedeni **kargo hasarý** idi.'),
(N'Bu sipariþ, 10 farklý **alt ürün** içeriyor. **Karmaþýk paketleme** süreci. Her birinin stok kodu (SKU) ayrý ayrý kontrol edildi.'),
(N'**Sezon sonu indirimi** ürünüdür. Stokta kalan son 3 adet. **Maliyet analizi** düþük kâr marjý gösteriyor.'),
(N'Müþteri, **cep telefonu** ile sipariþ verdi. **Mobil optimizasyon**un baþarýsý. Dönüþüm oranlarýna dahil edildi.'),
(N'**Yurt dýþý teslimat** adresi içeriyor. **Gümrük beyannamesi** ve **ihracat prosedürleri** baþlatýldý. **Uluslararasý satýþ**.'),
(N'**Özel üretim** (customize) bir ürün talebi var. Üretim bandýna **ek talimatlar** gönderildi. Teslimat süresi uzayacak.'),
(N'Bu sipariþ, **eðitim materyali** olarak kullanýlacak. Müþteri, bir üniversite veya okul. **Kurumsal satýþ** kategorisinde.'),
(N'**Müþteri Yorumu:** "Mükemmel hizmet, sipariþimi 24 saatten kýsa sürede teslim aldým." **Pozitif geri bildirim** alýndý.'),
(N'Satýn alýnan **akýllý saat** için **yazýlým güncelleme** bildirimi gönderilmeli. Satýþ sonrasý destek ekibi ilgilenecek.'),
(N'Sipariþ, **hafta sonu** girildi. Pazartesi ilk iþ olarak iþleme alýnacak. **Aciliyet** normal. Hafta sonu takibi.'),
(N'Müþteri, **ödeme yöntemini** son anda **havale** olarak deðiþtirdi. Ödeme dekontu teyit edildi. **Finansal kontrol** yapýldý.'),
(N'**Ürüne özel montaj hizmeti** satýn alýndý. Teknik ekip randevu için müþteriyi arayacak. **Servis randevusu** oluþturuldu.'),
(N'Müþteri, sipariþinin **gizli kalmasýný** istedi. Paket üzerinde þirket logosu veya ismi olmayacak. **Anonim gönderi** talebi.'),
(N'Sipariþ tutarý **yüksek**. Yönetim onayý (Manager Approval) alýndýktan sonra sevk edilecek. **Üst düzey müþteri**.'),
(N'**Demo** ürünü indirimli fiyattan satýldý. Üründe **küçük kozmetik hasar** olabilir. Müþteri bilgilendirildi ve kabul etti.'),
(N'Müþteri, **sosyal medya** üzerinden bir kampanya görerek geldi. **Kampanya kodu**: INSTA50. **Dijital pazarlama** takibi.'),
(N'**Ýkinci el** (Refurbished) kategorisinden bir ürün sipariþi. **6 ay garanti** kapsamýndadýr. **Yenilenmiþ ürün** stoku.'),
(N'**Tedarik zinciri** hatasý nedeniyle bu ürünün tedariði 3 gün gecikti. Müþteriye **özür e-postasý** gönderildi. **Ýþletme riski** minimize edildi.'),
(N'Bu sipariþteki tüm ürünler **ayný renkte** (kýrmýzý) talep edildi. Stokta yeterli kýrmýzý ürün var. **Renk tercihi** notu.'),
(N'Müþteri, **sýkça sorulan sorular (SSS)** bölümündeki bir hatayý bildirdi. Sipariþle birlikte **teþekkür notu** eklendi. **Web sitesi hatasý**.'),
(N'**Bölgesel daðýtým merkezi** (Ýzmir) üzerinden sevk edilecek. Ýstanbul deposu bu ürünü tutmuyor. **Daðýtým optimizasyonu**.')
;

-- UPDATE ÝÞLEMÝNÝ GERÇEKLEÞTÝRME
-- NOT: Bu UPDATE iþlemi, `SalesOrderHeader` tablosundaki mevcut sipariþlerin Comment sütununu rastgele güncelleyecektir.
-- Gerçek AdventureWorksLT2019 veritabanýnda SalesOrderID genellikle 71774'ten baþlar. Bu script'i kullanmadan önce ID'leri kontrol edin.

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

-- Ýþlem tamamlandý mesajý
SELECT 'Sales.SalesOrderHeader tablosundaki ilk ' + CAST(@TotalUpdates AS NVARCHAR(10)) + ' sipariþin Comment sütunu güncellendi.' AS Sonuc;



SELECT * FROM Sales.SalesOrderHeader



SELECT * INTO TEST_SalesOrderHeader FROM  Sales.SalesOrderHeader

-- cümle olarak da arama yapabilir. iadew deðiþim iade deðiþim
SELECT *
FROM TEST_SalesOrderHeader
WHERE FREETEXT(Comment, '**iade deðiþim**');

-- Sadece kelime kelime aram yapar
-- like gibi çalýþýr iade veya deðiþim olanlarý getirir.
SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'iade') AND CONTAINS(Comment,'deðiþim');


SELECT *
FROM TEST_SalesOrderHeader
WHERE Comment LIKE '%iade%' OR Comment LIKE '%degisim%'


-- FULLTEXT SEARH ---

-- FREETEXT, belirli bir kelimeyi ya da kelime grubunu esnek bir þekilde arar.
-- Türevler (kelime kökleri, ekler) ve yakýn eþleþmeler dikkate alýnýr. Yani, "developer" kelimesi, "developers", "developing", "developed" gibi türevlerle de eþleþir.

-- Kesin Arama (Exact Match): CONTAINS, belirli bir kelime veya kelime grubunu kesin olarak arar.
-- Belirtilen kelimenin ya da kelime grubunun veritabanýnda tam olarak geçmesi gerekir.
-- CONTAINS, daha detaylý ve kesin aramalar yapmanýza olanak tanýr. Ayrýca, wildcard'lar (joker karakterler) ve Boolean operatörleri gibi daha esnek arama yapmanýza imkan verir.

SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'iade OR degisim')

-- Joker karakter aramasý
SELECT *
FROM TEST_SalesOrderHeader
WHERE CONTAINS(Comment, 'kargo*') -- "developer", "developers", "developing" 


SELECT * FROM HumanResources.EmployeePayHistory



-- Çalýþacaðýmýz veritabanýný seçelim
USE AdventureWorks2019;
GO

-------------------------------------------
-- 1. DROP INDEX (Ýndeksi Silme)
-------------------------------------------

-- Bir indeksi kalýcý olarak siler.
-- Dikkat: Bu iþlem geri alýnamaz.

-- Söz Dizimi:
-- DROP INDEX [ÝndeksAdý] ON [ÞemaAdý].[TabloAdý];

DROP INDEX IF EXISTS [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader];
GO

-- Ýndeksi silmeden önce kontrol için, eðer daha önce sildiyseniz tekrar oluþturalým:
CREATE NONCLUSTERED INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] ([CustomerID]);
GO

-------------------------------------------
-- 2. DISABLE INDEX (Ýndeksi Devre Dýþý Býrakma)
-------------------------------------------

-- Ýndeksi devre dýþý býrakýr. Ýndeks verisi diskte kalýr ancak kullanýlamaz 
-- ve güncellenmez. Ýndeks anahtarlarý üzerindeki birincil veya benzersiz kýsýtlamalar (Primary/Unique Key) devre dýþý býrakýlmaz.

-- Söz Dizimi:
-- ALTER INDEX [ÝndeksAdý] ON [ÞemaAdý].[TabloAdý] DISABLE;

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
DISABLE;
GO

-- Ýndeksin durumunu kontrol etme: is_disabled sütunu 1 olmalýdýr.
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
-- 3. REBUILD INDEX (Ýndeksi Yeniden Oluþturma)
-------------------------------------------

-- Ýndeksi silip baþtan oluþturur. Ýndeksin fragmentation'ýný (parçalanmasýný) ortadan kaldýrýr. 
-- Devre dýþý býrakýlmýþ bir indeksi tekrar kullanýlabilir hale getirmenin tek yolu REBUILD etmektir.
-- Bu iþlem genellikle bir kesinti (downtime) gerektirir, ancak ONLINE seçeneði ile kesintisiz yapýlabilir (Enterprise veya Developer sürümü gerektirir).

-- Söz Dizimi:
-- ALTER INDEX [ÝndeksAdý] ON [ÞemaAdý].[TabloAdý] REBUILD [WITH (...)];

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
REBUILD 
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, ONLINE = ON); 
-- ONLINE = ON özelliði, iþlem sýrasýnda tabloya eriþimi sürdürmeyi saðlar.

-- Ýndeks artýk etkin olmalýdýr (is_disabled sütunu 0 olmalýdýr).
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
-- 4. REORGANIZE INDEX (Ýndeksi Yeniden Düzenleme)
-------------------------------------------

-- Ýndeks yaprak düzeyindeki sayfalarý mantýksal sýraya göre yeniden düzenler. 
-- Çok parçalanmýþ (fragmented) indeksler için REBUILD'e göre daha hafif bir iþlemdir.
-- Her zaman çevrimiçi (ONLINE) olarak çalýþýr, yani tabloya eriþimi engellemez. 
-- Genellikle düþük veya orta düzeyde parçalanma için kullanýlýr (%5 ile %30 arasý).

-- Söz Dizimi:
-- ALTER INDEX [ÝndeksAdý] ON [ÞemaAdý].[TabloAdý] REORGANIZE;

ALTER INDEX [IX_SalesOrderHeader_CustomerID] 
ON [Sales].[SalesOrderHeader] 
REORGANIZE;
GO

-------------------------------------------
-- BONUS: Tüm Ýndeksleri Yönetme
-------------------------------------------

-- Tablodaki tüm indeksleri yeniden oluþturma
ALTER INDEX ALL 
ON [Sales].[SalesOrderHeader] 
REBUILD 
WITH (SORT_IN_TEMPDB = ON);
GO

-- Tablodaki tüm indeksleri yeniden düzenleme
ALTER INDEX ALL 
ON [Sales].[SalesOrderHeader] 
REORGANIZE;
GO


-- INDEX FRAGMENTATION VIEWS ----

-- ROW STORE INDEX
-- CLUSTERED INDEX PK alanlar için
-- NON_CLUSTRED INDEX FK ve diðer alanlar için
-- UNIQUE INDEX
-- COMPOSITE_INDEX
-- FILTERED INDEX
-- FULL TEXT SEARCH

-- HANGI DURUMLARDA INDEKS KULLANMAYALIM

-- Küçük tablolarda gereksiz
-- Çok fazla INSERT, UPDATE, DELETE olan tablolarda çok fazla indeks kullanýmý performas sorunu yaratýr
-- Bir tabloda az sayýda sutun varsa kullanýmý performans saðlamayabilir
-- Öngürülemeyen sorgularda gereksiz yere indeks tanýmý yapmayalým.
-- Sýralama ve Gruplama iþlemlerinin olduðu tablolarda dikkatli olalým.
-- IMAGE, TEXT ,NTEXT, NVARCHAR(MAX),JSON indekslenmez bu tipleri olabildiðince kullanmayalým.

GO
CREATE OR ALTER VIEW  FRAGMENTATIONVIEW
AS
SELECT dbschemas.[name] as 'Schema', dbtables.[name] as 'Table', dbindexes.[name] as 'Index', indexstats.avg_fragmentation_in_percent as fragmentation, indexstats.page_count as pageCount
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id] 
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id] 
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id] AND indexstats.index_id = dbindexes.index_id WHERE indexstats.database_id = DB_ID() 


SELECT * FROM FRAGMENTATIONVIEW

-- Tablo üzerinde Indekslerin Ne kadarlýk bir alan kapladýðý
exec sp_spaceused 'Sales.SalesOrderHeader'

