USE [RestoranDb]
GO

-- Drop tables in correct order (reverse of foreign key dependencies)
DROP TABLE IF EXISTS KuryeSiparis
DROP TABLE IF EXISTS AskidaYemek
DROP TABLE IF EXISTS Siparisler
DROP TABLE IF EXISTS Kartlar
DROP TABLE IF EXISTS Adresler
DROP TABLE IF EXISTS Kurye
DROP TABLE IF EXISTS Menu
DROP TABLE IF EXISTS Kategoriler
DROP TABLE IF EXISTS Kullanici
DROP TABLE IF EXISTS Restaurant
DROP TABLE IF EXISTS Rol
GO

-- Drop existing triggers if any
DROP TRIGGER IF EXISTS tr_SiparisEklendiCiroGuncelle
DROP TRIGGER IF EXISTS tr_RestaurantSoftDelete
DROP TRIGGER IF EXISTS tr_MenuSoftDelete
DROP TRIGGER IF EXISTS tr_SiparisEklendiKuryeAta
DROP TRIGGER IF EXISTS tr_SiparisEklendiCuzdan
DROP TRIGGER IF EXISTS tr_AskidaYemekEklendiCuzdan
GO

CREATE TABLE Rol(
    RolId TINYINT IDENTITY(1,1) PRIMARY KEY,
    RolAdi NVARCHAR(50) NOT NULL UNIQUE
)
GO

CREATE TABLE Restaurant(
    RestaurantId INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantRol TINYINT NOT NULL,
    RestaurantAdi NVARCHAR(50) NOT NULL,
    RestaurantMail NVARCHAR(100) NOT NULL UNIQUE,
    RestaurantParola NVARCHAR(256) NOT NULL UNIQUE,
    RestaurantSehir NVARCHAR(20) NOT NULL,
    RestaurantAdres NVARCHAR(200) NOT NULL,
    RestaurantVergiNo NVARCHAR(11) NOT NULL UNIQUE,
    RestaurantTelNo NVARCHAR(11) NOT NULL,
    RestaurantLogoUrl NVARCHAR(500),
    RestaurantMinTutar DECIMAL(10,2),
    CHECK(RestaurantMinTutar>0),
    RestaurantTeslimSuresi NVARCHAR(2),
    CHECK(RestaurantTeslimSuresi>0),
    RestaurantAcilisSaati NVARCHAR(5),
    RestaurantKapanisSaati NVARCHAR(5),
    RestaurantAcikMi BIT NOT NULL,
    RestaurantAktifMi BIT DEFAULT 1,
    RestaurantToplamCiro INT NOT NULL,
    FOREIGN KEY (RestaurantRol) REFERENCES Rol(RolId)
)
GO

CREATE TABLE Kategoriler(
    KategoriId INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantId INT NOT NULL,
    KategoriAdi NVARCHAR(100) NOT NULL,
    KategoriAciklama NVARCHAR(300) NOT NULL,
    FOREIGN KEY (RestaurantId) REFERENCES Restaurant(RestaurantId)
)
GO

CREATE TABLE Menu(
    MenuId INT IDENTITY(1,1) PRIMARY KEY,
    KategoriId INT NOT NULL,
    MenuAdi NVARCHAR(50) NOT NULL,
    MenuFiyat DECIMAL(10,2) NOT NULL,
    CHECK(MenuFiyat>0),
    MenuAciklama NVARCHAR(300) NOT NULL,
    MenuVarMi BIT NOT NULL,
    MenuAktifMi BIT DEFAULT 1,
    FOREIGN KEY (KategoriId) REFERENCES Kategoriler(KategoriId)
)
GO

CREATE TABLE Kullanici(
    KullaniciId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciRol TINYINT NOT NULL,
    KullaniciAdi NVARCHAR(50) NOT NULL,
    KullaniciSoyadi NVARCHAR(50) NOT NULL,
    KullaniciMail NVARCHAR(100) NOT NULL UNIQUE,
    KullaniciParola NVARCHAR(256) NOT NULL UNIQUE,
    KullaniciCuzdan INT NOT NULL ,
	CHECK(KullaniciCuzdan>0),
    FOREIGN KEY (KullaniciRol) REFERENCES Rol(RolId)
)
GO

CREATE TABLE AskidaYemek(
    AskidaYemekId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT NOT NULL,
    MenuId INT NOT NULL,
    FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId),
    FOREIGN KEY (MenuId) REFERENCES Menu(MenuId)
)
GO

CREATE TABLE Kartlar(
    KartId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT NOT NULL,
    Isim NVARCHAR(50) NOT NULL,
    SoyIsim NVARCHAR(50) NOT NULL,
    KartNumarasi NVARCHAR(16) NOT NULL UNIQUE,
    Tarih NVARCHAR(5) NOT NULL,
    CVC2No NVARCHAR(3) NOT NULL,
    FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId)
)
GO

CREATE TABLE Adresler(
    AdresId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT NOT NULL,
    AdresBaslik NVARCHAR(50) NOT NULL,
    AdresSehir NVARCHAR(20) NOT NULL,
    AdresIlce NVARCHAR(30) NOT NULL,
    AcikAdres NVARCHAR(300) NOT NULL,
    FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId)
)
GO

CREATE TABLE Siparisler(
    SiparisId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT NOT NULL,
    MenuId INT NOT NULL,
    AdresId INT NOT NULL,
    SiparisAdet TINYINT NOT NULL,
    SiparisTarihi AS GETDATE(),
    FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId),
    FOREIGN KEY (MenuId) REFERENCES Menu(MenuId),
    FOREIGN KEY (AdresId) REFERENCES Adresler(AdresId)
)
GO

CREATE TABLE Kurye(
    KuryeId INT IDENTITY(1,1) PRIMARY KEY,
    KuryeRol TINYINT NOT NULL,
    KuryeAdi NVARCHAR(50) NOT NULL,
    KuryeSoyadi NVARCHAR(50) NOT NULL,
    KuryeTCNO NVARCHAR(11) NOT NULL UNIQUE,
    KuryeMail NVARCHAR(256) NOT NULL UNIQUE,
    KuryeParola NVARCHAR(256) NOT NULL UNIQUE,
    KuryeAktifMi BIT NOT NULL,
    FOREIGN KEY (KuryeRol) REFERENCES Rol(RolId)
)
GO

CREATE TABLE KuryeSiparis(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    KuryeId INT,
    SiparisId INT,
    FOREIGN KEY (KuryeId) REFERENCES Kurye(KuryeId),
    FOREIGN KEY(SiparisId) REFERENCES Siparisler(SiparisId)
)
GO

CREATE TRIGGER tr_SiparisEklendiCiroGuncelle
ON Siparisler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Restaurant
    SET RestaurantToplamCiro = ISNULL(RestaurantToplamCiro, 0) + (
        SELECT ISNULL(SUM(m.MenuFiyat * i.SiparisAdet), 0)
        FROM inserted i
        INNER JOIN Menu m ON i.MenuId = m.MenuId
        INNER JOIN Kategoriler k ON m.KategoriId = k.KategoriId
        WHERE k.RestaurantId = Restaurant.RestaurantId
    )
    WHERE RestaurantId IN (
        SELECT DISTINCT k.RestaurantId
        FROM inserted i
        INNER JOIN Menu m ON i.MenuId = m.MenuId
        INNER JOIN Kategoriler k ON m.KategoriId = k.KategoriId
    )
END
GO

CREATE TRIGGER tr_RestaurantSoftDelete
ON Restaurant
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Restaurant
    SET RestaurantAktifMi = 0
    WHERE RestaurantId IN (SELECT RestaurantId FROM deleted)
END
GO

CREATE TRIGGER tr_MenuSoftDelete
ON Menu
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Menu
    SET MenuAktifMi = 0
    WHERE MenuId IN (SELECT MenuId FROM deleted)
END
GO

DROP TRIGGER IF EXISTS tr_SiparisEklendiKuryeAta
GO

CREATE TRIGGER tr_SiparisEklendiKuryeAta
ON Siparisler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AktifKuryeSayisi INT
    SELECT @AktifKuryeSayisi = COUNT(*) FROM Kurye WHERE KuryeAktifMi = 1
    
    IF @AktifKuryeSayisi > 0
    BEGIN
        INSERT INTO KuryeSiparis (KuryeId, SiparisId)
        SELECT TOP 1 
            (SELECT TOP 1 KuryeId FROM Kurye WHERE KuryeAktifMi = 1 ORDER BY NEWID()),
            i.SiparisId
        FROM inserted i
    END
END
GO

-- Trigger: Siparis Eklendiginde Kullanici Cuzdanından Bakiye Düşme
CREATE TRIGGER tr_SiparisEklendiCuzdan
ON Siparisler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Kullanici
    SET KullaniciCuzdan = KullaniciCuzdan - (
        SELECT ISNULL(SUM(m.MenuFiyat * i.SiparisAdet), 0)
        FROM inserted i
        INNER JOIN Menu m ON i.MenuId = m.MenuId
        WHERE i.KullaniciId = Kullanici.KullaniciId
    )
    WHERE KullaniciId IN (SELECT DISTINCT KullaniciId FROM inserted)
END
GO

-- Trigger: Askida Yemek Eklendiginde Kullanici Cuzdanından Bakiye Düşme ve Restoran Cirosuna Ekleme
CREATE TRIGGER tr_AskidaYemekEklendiCuzdan
ON AskidaYemek
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Yemek fiyatını al
    DECLARE @YemekFiyat DECIMAL(10,2)
    DECLARE @KullaniciId INT
    DECLARE @MenuId INT
    DECLARE @RestaurantId INT
    
    SELECT @YemekFiyat = m.MenuFiyat, @KullaniciId = i.KullaniciId, @MenuId = i.MenuId
    FROM inserted i
    INNER JOIN Menu m ON i.MenuId = m.MenuId
    
    SELECT @RestaurantId = k.RestaurantId
    FROM Menu m
    INNER JOIN Kategoriler k ON m.KategoriId = k.KategoriId
    WHERE m.MenuId = @MenuId
    
    -- Kullanıcının cüzdanından düş
    UPDATE Kullanici
    SET KullaniciCuzdan = KullaniciCuzdan - @YemekFiyat
    WHERE KullaniciId = @KullaniciId
    
    -- Restoranın cirosuna ekle
    UPDATE Restaurant
    SET RestaurantToplamCiro = RestaurantToplamCiro + @YemekFiyat
    WHERE RestaurantId = @RestaurantId
END
GO

-- VERI EKLEME
INSERT INTO Rol (RolAdi) VALUES ('Restaurant')
INSERT INTO Rol (RolAdi) VALUES ('Kullanici')
INSERT INTO Rol (RolAdi) VALUES ('Kurye')
GO

INSERT INTO Restaurant (RestaurantRol, RestaurantAdi, RestaurantMail, RestaurantParola, RestaurantSehir, RestaurantAdres, RestaurantVergiNo, RestaurantTelNo, RestaurantLogoUrl, RestaurantMinTutar, RestaurantTeslimSuresi, RestaurantAcilisSaati, RestaurantKapanisSaati, RestaurantAcikMi, RestaurantAktifMi, RestaurantToplamCiro)
VALUES 
(1, 'Lezzetli Pizzaci', 'pizza@example.com', 'sifre123', 'Istanbul', 'Taksim, Beyoglu', '12345678901', '05551234567', 'https://logo1.png', 25.00, '30', '11:00', '23:00', 1, 1, 0),
(1, 'Burger House', 'burger@example.com', 'sifre456', 'Ankara', 'Cankiri, Cayyolu', '98765432109', '05552345678', 'https://logo2.png', 30.00, '35', '10:00', '24:00', 1, 1, 0),
(1, 'Asya Tat Sarayi', 'asia@example.com', 'sifre789', 'Izmir', 'Alsancak, Konak', '11223344556', '05553456789', 'https://logo3.png', 20.00, '40', '12:00', '22:00', 1, 1, 0),
(1, 'Doner Express', 'doner@example.com', 'sifre404', 'Bursa', 'Osmangazi, Nilüfer', '44556677889', '05554567890', 'https://logo4.png', 22.00, '32', '10:30', '22:30', 1, 1, 0),
(1, 'Vegan Paradise', 'vegan@example.com', 'sifre505', 'Antalya', 'Muratpasa, Lara', '55667788990', '05555678901', 'https://logo5.png', 28.00, '38', '11:30', '23:30', 1, 1, 0),
(1, 'Balık Evi', 'balik@example.com', 'sifre606', 'Bodrum', 'Bodrum Merkez, Turgutreis', '66778899001', '05556789012', 'https://logo6.png', 35.00, '45', '12:00', '24:00', 1, 1, 0)
GO

-- [Diğer INSERT'ler önceki sağladığım tam koddan... Devam edin]

-- 3. KATEGORI VERILERI (Her restaurant için 4 kategori)

-- Restaurant 1 Kategorileri (Lezzetli Pizzaci)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(1, 'Klasik Pizzalar', 'Geleneksel ve lezzetli pizza cesitleri'),
(1, 'Ozel Pizzalar', 'Sefimizin ozel hazirladdigi pizzalar'),
(1, 'Pasta Yemekleri', 'Italyan usulu nefis pastalar'),
(1, 'Icecekler', 'Mesrubat ve sicak icecekler')
GO

-- Restaurant 2 Kategorileri (Burger House)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(2, 'Premium Burgerler', 'Sicak ve taze malzemeli burgerler'),
(2, 'Cicek Sogan Degirmeni', 'Cicek soganlar ve kizartmalar'),
(2, 'Salata Seckisi', 'Saglikli ve tatli salatalar'),
(2, 'Tatlılar ve Atistirmalar', 'Lezzetli atistirimalikar ve tatlilar')
GO

-- Restaurant 3 Kategorileri (Asya Tat Sarayi)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(3, 'Cin Yemekleri', 'Otantik Cin mutfagi ogle'),
(3, 'Japon Yemekleri', 'Sushi ve ramen secksii'),
(3, 'Tayland Yemekleri', 'Baharatsız ve lezzetli Tayland yemekleri'),
(3, 'Tatli Sonrasilar', 'Asyas en unlu tatlilaari')
GO

-- Restaurant 4 Kategorileri (Doner Express)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(4, 'Doner Cesitleri', 'Tavuk, kuzu ve biftek donerleri'),
(4, 'Sandwich Lezzetleri', 'Farkli soslu sandwichler'),
(4, 'Mezeler', 'Geleneksel Turk mezeleri'),
(4, 'Yan Yemekler', 'Kizartma ve pilav cesitleri')
GO

-- Restaurant 5 Kategorileri (Vegan Paradise)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(5, 'Vegan Burgerler', '100 porsent vejetaryen burgerler'),
(5, 'Veganbol Salatalar', 'Saglikli ve organik salatalar'),
(5, 'Tahillar ve Sebzeler', 'Quinoa, mercimek ve sebze yemekleri'),
(5, 'Vegan Tatlılar', 'Hayvan urunleri icsiz tatlilar')
GO

-- Restaurant 6 Kategorileri (Balık Evi)
INSERT INTO Kategoriler (RestaurantId, KategoriAdi, KategoriAciklama) VALUES
(6, 'Izgara Balik', 'Taze izgarada pisirilen baliklar'),
(6, 'Deniz Urunleri Mezesi', 'Karides, midye ve oktopus'),
(6, 'Balik Corbasi', 'Geleneksel balik corbasi turleri'),
(6, 'Deniz Salatalari', 'Taze deniz malzemesi salatalar')
GO

-- 4. MENU VERILERI (Her kategori için 5 menü)

-- RESTAURANT 1 - KATEGORI 1: Klasik Pizzalar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(1, 'Margherita', 45.00, 'Domates, mozzarella ve feslegenler', 1, 1),
(1, 'Pepperoni', 50.00, 'Domates, mozzarella ve pepperoni', 1, 1),
(1, 'Quattro Formaggi', 60.00, 'Dort cesit peynir ile hazirlmis', 1, 1),
(1, 'Carbonara', 55.00, 'Pancetta, yumurta ve parmasan peyniri', 1, 1),
(1, 'Vegetariana', 48.00, 'Mevsim sebzeleri ile hazirlmis', 1, 1)
GO

-- RESTAURANT 1 - KATEGORI 2: Ozel Pizzalar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(2, 'Sef Ozel Tavuk Pizza', 65.00, 'Steak, tavuk, peynir ve ozel sos', 1, 1),
(2, 'Seafood Pizza', 75.00, 'Karides, midye ve deniz urunleri', 1, 1),
(2, 'BBQ Chicken Pizza', 62.00, 'Tavuk gogsu ve barbeque sosu', 1, 1),
(2, 'Ispanak ve Feta Pizza', 58.00, 'Taze ispanak ve feta peyniri', 1, 1),
(2, 'Luxs Meat Pizza', 70.00, 'Sucuk, pastirma ve soslili pizza', 1, 1)
GO

-- RESTAURANT 1 - KATEGORI 3: Pasta Yemekleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(3, 'Fettucine Alfredo', 52.00, 'Kremsantili parmesan sosu ile', 1, 1),
(3, 'Spaghetti Bolognese', 50.00, 'Et soslu klasik spaghetti', 1, 1),
(3, 'Penne Arrabiata', 48.00, 'Biber ve domates soslu penne', 1, 1),
(3, 'Lasagna Classico', 58.00, 'Katmanli et ve peynirli lasanya', 1, 1),
(3, 'Ravioli Pesto', 55.00, 'Manti sekli paste ve pesto sosu', 1, 1)
GO

-- RESTAURANT 1 - KATEGORI 4: Icecekler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(4, 'Kola (330ml)', 6.00, 'Soguk kola', 1, 1),
(4, 'Meyve Suyu (250ml)', 8.00, 'Dogal meyve suyu', 1, 1),
(4, 'Limonata', 7.00, 'Ev yapim limonata', 1, 1),
(4, 'Turk Kahvesi', 10.00, 'Geleneksel Turk kahvesi', 1, 1),
(4, 'Cay Bardagi', 3.00, 'Sicak cay servisi', 1, 1)
GO

-- RESTAURANT 2 - KATEGORI 5: Premium Burgerler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(5, 'Classic Burger', 40.00, 'Et, marul, domates ve sos', 1, 1),
(5, 'Double Deluxe', 55.00, 'Cift kofte ile luxs burger', 1, 1),
(5, 'Cheese Lover Burger', 48.00, 'Uc cesit peynir ile burger', 1, 1),
(5, 'Bacon Bliss', 52.00, 'Bacon, cheddar ve caramelized sogan', 1, 1),
(5, 'Spicy Inferno', 50.00, 'Ekstra aci marinated kofte', 1, 1)
GO

-- RESTAURANT 2 - KATEGORI 6: Cicek Sogan Degirmeni
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(6, 'Cıtır Cicek Sogan', 28.00, 'Ev yapim cicek sogan crisps', 1, 1),
(6, 'Kızartılmış Patates Porsiyonu', 18.00, 'Golden patates kizartmasi', 1, 1),
(6, 'Mozzarella Cubugu (6 adet)', 22.00, 'Peynirli cubuklar', 1, 1),
(6, 'Tuz Biber Tavuk Kanadi', 32.00, 'Wok ede pisirilen tavuk', 1, 1),
(6, 'Karışık Kızartma Tabagi', 38.00, 'Tavuk, balik, cicek sogan ve patates', 1, 1)
GO

-- RESTAURANT 2 - KATEGORI 7: Salata Secksii
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(7, 'Sezar Salatasi', 35.00, 'Maru, parmesan ve kesme ekmek', 1, 1),
(7, 'Yesil Salata', 28.00, 'Mevsim yesilikleri ve vinaigrette', 1, 1),
(7, 'Tavuk Salatasi', 42.00, 'Taze tavuk gogsu ve sebzeler', 1, 1),
(7, 'Ciftci Salatasi', 32.00, 'Domates, salatalik ve sogan', 1, 1),
(7, 'Ton Balikli Salata', 45.00, 'Taze ton baligi ve yesillikler', 1, 1)
GO

-- RESTAURANT 2 - KATEGORI 8: Tatlılar ve Atistirmalar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(8, 'Cocolatali Brownie', 18.00, 'Sicak cocolatali kek', 1, 1),
(8, 'Cheesecake', 20.00, 'New York usulu peynirli pasta', 1, 1),
(8, 'Dondurma Sundae', 22.00, 'Dondurma ve sos topping ile', 1, 1),
(8, 'Elma Turta', 16.00, 'Ev yapimi elma tatliasi', 1, 1),
(8, 'Popcorn Kova', 12.00, 'Tatli veya tuzlu popcorn', 1, 1)
GO

-- RESTAURANT 3 - KATEGORI 9: Cin Yemekleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(9, 'Tavuk Teriyaki', 52.00, 'Teriyaki soslu tavuk filesi', 1, 1),
(9, 'Soy Sos Noodle', 48.00, 'Wok ede pisirilen cin eristleleri', 1, 1),
(9, 'Sogan Tavuk Salatasi', 46.00, 'Karamelize sogan ve tavuk', 1, 1),
(9, 'Pirinc Icinde Balik', 58.00, 'Pirinc icinde pisirilen balik', 1, 1),
(9, 'Mok Sau Gai', 50.00, 'Beyaz soslu tavuk yemegi', 1, 1)
GO

-- RESTAURANT 3 - KATEGORI 10: Japon Yemekleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(10, 'Philly Roll Sushi', 55.00, 'Somon, peynir ve mangal soslu', 1, 1),
(10, 'California Roll', 48.00, 'Kepekli yengen ve avokadolu', 1, 1),
(10, 'Spicy Tuna Roll', 52.00, 'Aci ton baligi ve sos', 1, 1),
(10, 'Ramen Bowl', 50.00, 'Geleneksel Japon ramen', 1, 1),
(10, 'Tempura Tavuk', 54.00, 'Hafif kizartilmis tavuk tempura', 1, 1)
GO

-- RESTAURANT 3 - KATEGORI 11: Tayland Yemekleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(11, 'Pad Thai', 48.00, 'Tayland usulu eriste yemegi', 1, 1),
(11, 'Green Curry Chicken', 52.00, 'Yesil aci kori soslu tavuk', 1, 1),
(11, 'Tom Yum Soup', 44.00, 'Acili ve eksi Tayland corbasi', 1, 1),
(11, 'Mango Sticky Rice', 42.00, 'Mangolu yapişkan pirinc', 1, 1),
(11, 'Satay Tavuk Sisleri', 50.00, 'Fisik soslu tavuk sisceleri', 1, 1)
GO

-- RESTAURANT 3 - KATEGORI 12: Tatli Sonrasilar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(12, 'Pamapuan Pasta', 22.00, 'Hindistan cevizi ve pandan tadinda', 1, 1),
(12, 'Mango Tatliesi', 24.00, 'Meyve salatasinda mango serbeti', 1, 1),
(12, 'Tapioca Pudding', 20.00, 'Hindistan cevizi sutle pudding', 1, 1),
(12, 'Durian Dondurma', 26.00, 'Eksotik durian meyvesi dondurma', 1, 1),
(12, 'Sesame Kurabiye', 18.00, 'Susamli gevrek kurabiye', 1, 1)
GO

-- RESTAURANT 4 - KATEGORI 13: Doner Cesitleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(13, 'Tavuk Doner', 38.00, 'Taze tavuk etinden doner', 1, 1),
(13, 'Kuzu Doner', 48.00, 'Ozel baharatlı kuzu etinden doner', 1, 1),
(13, 'Karisan Doner', 42.00, 'Tavuk ve kuzu karisi doner', 1, 1),
(13, 'Biftek Doner', 52.00, 'Hassas biftek etinden doner', 1, 1),
(13, 'Sos Doneri', 40.00, 'Sos icinde pisirilen doner', 1, 1),
(13, 'Cit Doner Tabagi', 55.00, 'Dogalin sos ve sebzeli doner', 1, 1)
GO

-- RESTAURANT 4 - KATEGORI 14: Sandwich Lezzetleri
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(14, 'Klasik Sandwich', 25.00, 'Doner eti ve standart soslar', 1, 1),
(14, 'Sarimsakli Sandwich', 28.00, 'Sarimsakli mayonez ile sandwich', 1, 1),
(14, 'Acili Sandwich', 26.00, 'Ekstra aci biber ve soslar', 1, 1),
(14, 'Peynirli Sandwich', 32.00, 'Kasar peyniri ile zenginlestirilmis', 1, 1),
(14, 'Maleme Sandwich', 34.00, 'Humus, sarımsaklı yoğurt ve doner', 1, 1),
(14, 'Ozel Sos Sandwich', 30.00, 'Sefin ozel tarif sosu ile', 1, 1),
(14, 'Avokadolu Sandwich', 36.00, 'Avokado ve doner kombinasyonu', 1, 1)
GO

-- RESTAURANT 4 - KATEGORI 15: Mezeler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(15, 'Hummus', 16.00, 'Nohuttan yapilan humus', 1, 1),
(15, 'Baba Ganoush', 18.00, 'Patlicanından yapilan mezes', 1, 1),
(15, 'Tabbule', 20.00, 'Persil ve bulgurdan yapilan mezes', 1, 1),
(15, 'Cacık', 14.00, 'Yoğurtlu ve taze sebzeli mezes', 1, 1),
(15, 'Ezme', 15.00, 'Domates ve biberden yapilan mezes', 1, 1),
(15, 'Muttabal', 22.00, 'Patlicanı ve tahini karısı mezes', 1, 1),
(15, 'Muhammara', 21.00, 'Kirmizi biber ve cevizden mezes', 1, 1)
GO

-- RESTAURANT 4 - KATEGORI 16: Yan Yemekler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(16, 'Kizartma Tabagi', 24.00, 'Tavuk, balık ve patatesi kizartmali', 1, 1),
(16, 'Ozel Pilav', 20.00, 'Soslu ve sebzeli pilav', 1, 1),
(16, 'Patates Salatasi', 16.00, 'Sicak patates ve mayonez karisi', 1, 1),
(16, 'Nohut Pilavi', 22.00, 'Geleneksel nohut pilavi', 1, 1),
(16, 'Sebzeli Bulgur', 18.00, 'Sebze ve baharatlı bulgur', 1, 1),
(16, 'Icli Kofte', 26.00, 'Ic dolgulu bulgur kofte', 1, 1)
GO

-- RESTAURANT 5 - KATEGORI 17: Vegan Burgerler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(17, 'Mercimek Burger', 42.00, 'Mercimekten yapilan kofte burger', 1, 1),
(17, 'Mantarli Burger', 45.00, 'Mantar ve sebze icadı burger', 1, 1),
(17, 'Quinoa Burger', 48.00, 'Quinoa ve fasulye karışı burger', 1, 1),
(17, 'Nopal Burger', 50.00, 'Sabır dikeni bitki burger', 1, 1),
(17, 'Avokado Burger', 52.00, 'Taze avokado ve veganbol acılı', 1, 1),
(17, 'Super Vegan Burger', 55.00, 'Tum veganbol malzemelerle dolu', 1, 1)
GO

-- RESTAURANT 5 - KATEGORI 18: Veganbol Salatalar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(18, 'Organik Yeşil Salata', 32.00, 'Taze yeşil yapraklı malzemeler', 1, 1),
(18, 'Kinoali Sebze Salata', 38.00, 'Quinoa ve mevsim sebzeleri', 1, 1),
(18, 'Avokado Salatasi', 40.00, 'Avokado ve lime dressing ile', 1, 1),
(18, 'Cikli Turp Salata', 35.00, 'Beetroot ve turp karışı', 1, 1),
(18, 'Tabbule Salatasi', 33.00, 'Persil ve bulgurdan yapilan salata', 1, 1),
(18, 'Kale Salatasi', 39.00, 'Lahana ve tahini dressing', 1, 1),
(18, 'Makarna Salata', 36.00, 'Tahini ve zeytinyağı soslu pasta salata', 1, 1)
GO

-- RESTAURANT 5 - KATEGORI 19: Tahillar ve Sebzeler
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(19, 'Mercimek Corbasi', 26.00, 'Klasik turk mercimek corbasi', 1, 1),
(19, 'Kirmizi Fasulye Pilavi', 28.00, 'Fasulye ve pirinc karişı', 1, 1),
(19, 'Kinoali Sebze Tabagi', 34.00, 'Quinoa ve sebzeler', 1, 1),
(19, 'Misir Bulguru', 25.00, 'Misir ve bulgur pilavi', 1, 1),
(19, 'Tulum Peyniri Alternatifi', 32.00, 'Beslenmiş tahini ile makarna', 1, 1),
(19, 'Mantar Risotto', 36.00, 'Mantar ve veganbol risotto', 1, 1)
GO

-- RESTAURANT 5 - KATEGORI 20: Vegan Tatlılar
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(20, 'Acacılı Brownie', 20.00, 'Aci vegan chocolate brownie', 1, 1),
(20, 'Muz Pasta', 22.00, 'Muz ve tahin pastasi', 1, 1),
(20, 'Fram Tatlisi', 24.00, 'Frambuaz ve coco islagi', 1, 1),
(20, 'Tahini Kurabiye', 16.00, 'Tahini ve coco ile yapilan kurabiye', 1, 1),
(20, 'Vegan Cheesecake', 26.00, 'Tahini ve tofu kullanarak yapilan pasta', 1, 1),
(20, 'Hindistan Cevizi Tatlı', 25.00, 'Taze hindistan cevizi tatlilarim', 1, 1),
(20, 'Avokado Puding', 28.00, 'Avokado ve cacao ile yapilan puding', 1, 1)
GO

-- RESTAURANT 6 - KATEGORI 21: Izgara Balik
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(21, 'Levrek Izgara', 65.00, 'Taze Akdeniz levrek', 1, 1),
(21, 'Dorada Izgara', 62.00, 'Dorada baligi izgara', 1, 1),
(21, 'Barbunya Izgara', 58.00, 'Kirmizi barbunya baligi', 1, 1),
(21, 'Palamut Izgara', 70.00, 'Bahar palamut baligi', 1, 1),
(21, 'Kefal Izgara', 55.00, 'Kefal baligi izgara', 1, 1),
(21, 'Turna Balik Izgara', 75.00, 'Ozel sahin turna baligi', 1, 1),
(21, 'Balık Tepsisi (2 Kişi)', 120.00, '2 kişi için arakik balik tepsisi', 1, 1)
GO

-- RESTAURANT 6 - KATEGORI 22: Deniz Urunleri Mezesi
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(22, 'Karidesli Garnitür', 52.00, 'Taze baliklandirılan karidesleri', 1, 1),
(22, 'Midye Dolma', 48.00, 'Midyeler ici dolgulu', 1, 1),
(22, 'Calinir Karides', 58.00, 'Sarımsak soyunda pislmis karidesi', 1, 1),
(22, 'Deniz Salyangozu', 44.00, 'Taze deniz salyangozleri', 1, 1),
(22, 'Oktopus Salatasi', 55.00, 'Haş ve limonal oktopus', 1, 1),
(22, 'Karakol Meyvesi', 50.00, 'Deniz meyvesi karişı', 1, 1),
(22, 'Kalamar Tavasin', 60.00, 'Taze kalamar kizartmasi', 1, 1)
GO

-- RESTAURANT 6 - KATEGORI 23: Balik Corbasi
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(23, 'Balik Suyu Corbasi', 38.00, 'Geleneksel balik suyu', 1, 1),
(23, 'Levrek Corbasi', 42.00, 'Levrek ve sebzeli corbа', 1, 1),
(23, 'Deniz Mahsulleri Corbasi', 48.00, 'Karışık deniz urunleri corbası', 1, 1),
(23, 'Midye Corbasi', 40.00, 'Midye icinde corbа', 1, 1),
(23, 'Balik Ekmeği Corbasi', 35.00, 'Balik ve ekmek ile yapilan corbа', 1, 1),
(23, 'Espesyal Deniz Corbasi', 52.00, 'Sef ozel deniz corbası', 1, 1)
GO

-- RESTAURANT 6 - KATEGORI 24: Deniz Salatalari
INSERT INTO Menu (KategoriId, MenuAdi, MenuFiyat, MenuAciklama, MenuVarMi, MenuAktifMi) VALUES
(24, 'Deniz Mahsuleri Salatasi', 58.00, 'Taze karides ve balık salatası', 1, 1),
(24, 'Okra Salatasi', 48.00, 'Ağır ve deniz sebzesi', 1, 1),
(24, 'Limanli Salata', 52.00, 'Limon sos ve taze deniz şuff', 1, 1),
(24, 'Midye ve Domates Salata', 50.00, 'Midye ve sebzeler', 1, 1),
(24, 'Somon Salatasi', 62.00, 'Taze Norveç somon', 1, 1),
(24, 'Uskumru Salatasi', 54.00, 'Uskumru ve limon aromasi', 1, 1),
(24, 'Kepekli Ton Balığı Salata', 56.00, 'Ton balığı ve yesil yapraklı', 1, 1)
GO

-- ============================================
-- KULLANICI VERILERI (25 Kullanıcı)
-- ============================================

INSERT INTO Kullanici (KullaniciRol, KullaniciAdi, KullaniciSoyadi, KullaniciMail, KullaniciParola, KullaniciCuzdan) VALUES
(2, 'Ahmet', 'Yilmaz', 'ahmet@example.com', 'sifre123', 25000),
(2, 'Fatih', 'Demir', 'fatih@example.com', 'sifre456', 15000),
(2, 'Zeynep', 'Kaya', 'zeynep@example.com', 'sifre789', 30000),
(2, 'Mustafa', 'Ates', 'mustafa@example.com', 'sifre101', 10000),
(2, 'Ayse', 'Sahin', 'ayse@example.com', 'sifre202', 20000),
(2, 'Emre', 'Cetin', 'emre@example.com', 'sifre303', 18000),
(2, 'Merve', 'Gunes', 'merve@example.com', 'sifre404', 22000),
(2, 'Serkan', 'Koyuncu', 'serkan@example.com', 'sifre505', 27000),
(2, 'Duygu', 'Aydin', 'duygu@example.com', 'sifre606', 1400),
(2, 'Burak', 'Yildiz', 'burak@example.com', 'sifre707', 310),
(2, 'Ozlem', 'Ozcan', 'ozlem@example.com', 'sifre808', 2800),
(2, 'Hasan', 'Kalkan', 'hasan@example.com', 'sifre909', 1600),
(2, 'Emine', 'Yağız', 'emine@example.com', 'sifre1010', 3200),
(2, 'Samet', 'Basaran', 'samet@example.com', 'sifre1111', 1900),
(2, 'Ipek', 'Sahan', 'ipek@example.com', 'sifre1212', 2400),
(2, 'Cem', 'Dagcioglu', 'cem@example.com', 'sifre1313', 1200),
(2, 'Sebnem', 'Kus', 'sebnem@example.com', 'sifre1414', 3500),
(2, 'Sinan', 'Yarım', 'sinan@example.com', 'sifre1515', 2100),
(2, 'Nuran', 'Tepe', 'nuran@example.com', 'sifre1616', 2900),
(2, 'Volkan', 'Uygun', 'volkan@example.com', 'sifre1717', 1700),
(2, 'Leyla', 'Isik', 'leyla@example.com', 'sifre1818', 3300),
(2, 'Ari', 'Goksu', 'ari@example.com', 'sifre1919', 1300),
(2, 'Filiz', 'Aydogan', 'filiz@example.com', 'sifre2020', 2600),
(2, 'Malik', 'Tural', 'malik@example.com', 'sifre2121', 2000),
(2, 'Cigdem', 'Unal', 'cigdem@example.com', 'sifre2222', 3400)
GO

-- ============================================
-- KART VERILERI (7 Kart - Kullanıcılara Bağlı)
-- ============================================

INSERT INTO Kartlar (KullaniciId, Isim, SoyIsim, KartNumarasi, Tarih, CVC2No) VALUES
(1, 'Ahmet', 'Yilmaz', '4532123456789012', '12/26', '123'),
(2, 'Fatih', 'Demir', '5425234567890123', '08/25', '456'),
(3, 'Zeynep', 'Kaya', '4024456789012345', '06/27', '789'),
(4, 'Mustafa', 'Ates', '5534567890123456', '10/26', '234'),
(5, 'Ayse', 'Sahin', '4916678901234567', '03/25', '567'),
(6, 'Emre', 'Cetin', '5045789012345678', '11/26', '890'),
(7, 'Merve', 'Gunes', '4111890123456789', '09/27', '345')
GO

-- ============================================
-- ADRES VERILERI (35 Adres)
-- ============================================

-- Istanbul Adresler (Lezzetli Pizzaci'ya yakın - Beyoglu, Taksim)
INSERT INTO Adresler (KullaniciId, AdresBaslik, AdresSehir, AdresIlce, AcikAdres) VALUES
(1, 'Ev', 'Istanbul', 'Beyoglu', 'Ortakoy Caddesi No: 42, Daire: 3'),
(1, 'Is', 'Istanbul', 'Taksim', 'Nisantasi Caddesi No: 125'),
(2, 'Ev', 'Istanbul', 'Beyoglu', 'Yapi Kredi Cad. No: 78, Daire: 5'),
(3, 'Ev', 'Istanbul', 'Taksim', 'Gumussuy Cad. No: 55, Daire: 7'),
(4, 'Ev', 'Istanbul', 'Beyoglu', 'Mesrutiyet Cad. No: 45, Daire: 2'),
(11, 'Ev', 'Istanbul', 'Taksim', 'Akdere Cad. No: 20, Daire: 1'),
(12, 'Is', 'Istanbul', 'Beyoglu', 'Tomtom Kapı Cad. No: 55'),
(13, 'Ev', 'Istanbul', 'Taksim', 'Sıraselviler Cad. No: 77, Daire: 4'),

-- Ankara Adresler (Burger House'a yakın - Cayyolu, Cankiri)
(5, 'Ev', 'Ankara', 'Cayyolu', 'Tunali Hilmi Cad. No: 100, Daire: 4'),
(5, 'Otel', 'Ankara', 'Cankiri', 'Ataturk Bulvari No: 300'),
(6, 'Ev', 'Ankara', 'Cayyolu', 'Ataturk Cad. No: 67, Daire: 1'),
(7, 'Ev', 'Ankara', 'Cankiri', 'Izzettasa Cad. No: 89'),
(14, 'Ev', 'Ankara', 'Cayyolu', 'Çankırı Cad. No: 150, Daire: 6'),
(15, 'Yazlik', 'Ankara', 'Cayyolu', 'Yüksek Cad. No: 88'),
(16, 'Is', 'Ankara', 'Cankiri', 'Ticari Alan No: 22'),

-- Izmir Adresler (Asya Tat Sarayi'na yakın - Konak, Alsancak)
(8, 'Ev', 'Izmir', 'Konak', 'Gazi Bulvari No: 55, Daire: 7'),
(8, 'Yazlik', 'Izmir', 'Alsancak', 'Deniz Kenari No: 15'),
(9, 'Ev', 'Izmir', 'Konak', 'Cumhuriyet Meydani No: 88'),
(10, 'Calisma Alani', 'Izmir', 'Alsancak', 'Alsancak Caddesi No: 200, Daire: 6'),
(3, 'Yazlik', 'Izmir', 'Konak', 'Alsancak Yolu No: 33, Daire: 3'),
(4, 'Dukkan', 'Izmir', 'Alsancak', 'Kapili Carsi No: 12'),
(6, 'Buro', 'Izmir', 'Konak', 'Ticari Merkez No: 75, Daire: 8'),
(17, 'Ev', 'Izmir', 'Alsancak', 'Kıbrıs Şehitleri Cad. No: 110'),
(18, 'Yazlik', 'Izmir', 'Konak', 'Ege Blv. No: 245'),

-- Bursa Adresler (Doner Express'e yakın - Osmangazi, Nilüfer)
(19, 'Ev', 'Bursa', 'Osmangazi', 'Cekirge Cad. No: 35, Daire: 2'),
(19, 'Is', 'Bursa', 'Nilüfer', 'Nilüfer Bulvari No: 120'),
(20, 'Ev', 'Bursa', 'Osmangazi', 'Atatürk Cad. No: 90'),
(21, 'Ev', 'Bursa', 'Nilüfer', 'Fen Bilim Cad. No: 50, Daire: 8'),

-- Antalya Adresler (Vegan Paradise'e yakın - Muratpasa, Lara)
(22, 'Ev', 'Antalya', 'Muratpasa', 'Barınlı Mah. No: 65, Daire: 3'),
(22, 'Yazlik', 'Antalya', 'Lara', 'Lara Plajı Cad. No: 150'),
(23, 'Ev', 'Antalya', 'Muratpasa', 'Yüksek Cad. No: 88'),
(24, 'Ev', 'Antalya', 'Lara', 'Turizm Cad. No: 200, Daire: 5'),

-- Bodrum Adresler (Balık Evi'ne yakın - Bodrum Merkez, Turgutreis)
(25, 'Ev', 'Bodrum', 'Bodrum Merkez', 'Konacık Mah. No: 45, Daire: 2'),
(25, 'Yazlik', 'Bodrum', 'Turgutreis', 'Turgutreis Cad. No: 88')
GO

-- ============================================
-- KURYE VERILERI (3 Kurye)
-- ============================================

INSERT INTO Kurye (KuryeRol, KuryeAdi, KuryeSoyadi, KuryeTCNO, KuryeMail, KuryeParola, KuryeAktifMi) VALUES
(3, 'Hakan', 'Ozkan', '12345678901', 'hakan@example.com', 'kuryesifre123', 1),
(3, 'Gokhan', 'Topuz', '98765432109', 'gokhan@example.com', 'kuryesifre456', 1),
(3, 'Cengiz', 'Acar', '55544433221', 'cengiz@example.com', 'kuryesifre789', 1)
GO

-- ============================================
-- TRIGGER: Siparis Eklendìğinde Aktif Kuryeye Atama
-- ============================================
-- Her yeni siparis eklendinde, aktif olan kuryelerden
-- biri otomatik olarak siparis'e atanir
-- ============================================


-- ============================================
-- SIPARIS VERILERI (120 Siparis)
-- ============================================

-- RESTAURANT 1 (Lezzetli Pizzaci) - Siparişler (MenuId 1-20)
INSERT INTO Siparisler (KullaniciId, MenuId, AdresId, SiparisAdet) VALUES
(1, 1, 1, 2), (1, 3, 2, 1), (1, 6, 1, 3), (1, 12, 2, 2),
(2, 2, 3, 1), (2, 8, 3, 2), (2, 15, 3, 1), (2, 20, 2, 3),
(3, 4, 4, 2), (3, 5, 4, 1), (3, 13, 4, 2), (3, 22, 1, 1),
(4, 7, 5, 3), (4, 9, 5, 2), (4, 14, 5, 1), (4, 24, 2, 2),
(5, 2, 6, 1), (5, 7, 6, 3), (5, 11, 6, 2), (5, 16, 7, 1),
(6, 3, 8, 2), (6, 15, 8, 1), (6, 19, 8, 3), (6, 21, 7, 2),
(7, 4, 1, 2), (7, 8, 1, 1), (7, 12, 2, 2), (7, 17, 3, 1),
(8, 2, 4, 3), (8, 10, 5, 2), (8, 14, 6, 1), (8, 18, 7, 2),

-- RESTAURANT 2 (Burger House) - Siparişler (MenuId 21-40)
(5, 25, 9, 2), (5, 27, 9, 1), (5, 30, 10, 2),
(6, 23, 11, 1), (6, 28, 11, 3), (6, 35, 12, 2),
(7, 24, 13, 2), (7, 29, 13, 1), (7, 33, 14, 3),
(11, 26, 9, 1), (11, 31, 10, 2), (11, 36, 11, 1),
(12, 25, 12, 2), (12, 32, 13, 1), (12, 37, 14, 2),
(13, 23, 15, 3), (13, 28, 9, 1), (13, 39, 10, 2),
(14, 24, 11, 2), (14, 30, 12, 1), (14, 34, 13, 3),
(15, 27, 14, 1), (15, 35, 15, 2), (15, 38, 9, 1),
(16, 26, 10, 2), (16, 33, 11, 3), (16, 40, 12, 1),

-- RESTAURANT 3 (Asya Tat Sarayi) - Siparişler (MenuId 41-60)
(3, 41, 8, 2), (3, 45, 8, 1), (8, 43, 17, 2), (8, 48, 18, 1),
(9, 42, 19, 3), (9, 46, 20, 2), (10, 44, 21, 1), (10, 50, 22, 2),
(17, 49, 23, 2), (17, 47, 24, 1), (18, 45, 25, 3), (18, 52, 16, 2),
(19, 42, 17, 1), (19, 54, 18, 2), (20, 43, 19, 3), (20, 51, 20, 1),
(21, 44, 21, 2), (21, 53, 22, 1), (22, 41, 23, 1), (22, 49, 24, 2),

-- RESTAURANT 4 (Doner Express) - Siparişler (MenuId 61-86)
(19, 65, 26, 2), (19, 75, 26, 1), (19, 77, 27, 2), (19, 83, 27, 1),
(20, 61, 28, 3), (20, 71, 28, 2), (20, 80, 29, 1), (20, 84, 26, 2),
(21, 62, 27, 1), (21, 73, 28, 2), (21, 78, 29, 3), (21, 86, 26, 1),
(22, 64, 27, 2), (22, 74, 28, 1), (22, 81, 29, 2), (22, 85, 26, 3),
(19, 63, 26, 2), (20, 70, 27, 1), (21, 76, 28, 2), (22, 79, 29, 1),
(19, 66, 26, 3), (20, 72, 27, 1), (21, 82, 28, 2),

-- RESTAURANT 5 (Vegan Paradise) - Siparişler (MenuId 87-112)
(22, 95, 30, 2), (22, 100, 30, 1), (22, 110, 31, 2), (22, 105, 31, 1),
(23, 93, 32, 1), (23, 103, 32, 2), (24, 107, 33, 3), (24, 97, 32, 1),
(22, 91, 30, 2), (23, 99, 31, 1), (24, 108, 32, 2), (22, 101, 33, 1),

-- RESTAURANT 6 (Balık Evi) - Siparişler (MenuId 113-139)
(25, 115, 34, 2), (25, 120, 34, 1), (25, 127, 34, 2), (25, 130, 34, 1),
(25, 116, 34, 3), (25, 125, 34, 1), (25, 128, 34, 2), (25, 131, 34, 2),
(25, 117, 34, 1), (25, 122, 34, 2), (25, 132, 34, 1), (25, 135, 34, 3),

-- ADDITIONAL ORDERS - Tüm Restaurantlar
(1, 5, 3, 1), (2, 11, 5, 2), (3, 16, 6, 1), (4, 18, 7, 3),
(5, 9, 8, 2), (6, 13, 1, 1), (7, 17, 2, 2), (8, 20, 3, 1),
(1, 4, 4, 3), (2, 10, 5, 1), (3, 19, 6, 2), (4, 21, 7, 1),
(6, 32, 8, 2), (7, 26, 9, 1), (11, 29, 10, 3), (12, 34, 11, 1),
(13, 36, 12, 2), (14, 37, 13, 1), (15, 38, 14, 2), (16, 25, 15, 1),
(17, 49, 23, 2), (18, 53, 24, 1), (19, 48, 25, 3), (20, 52, 16, 2),
(21, 46, 17, 1), (22, 54, 18, 2), (3, 47, 19, 1), (8, 55, 20, 3),
(9, 44, 21, 2), (10, 51, 22, 1), (17, 42, 23, 2), (18, 48, 24, 1),
(19, 61, 26, 2), (20, 63, 27, 1), (21, 67, 28, 3), (22, 70, 29, 2),
(19, 76, 26, 1), (20, 78, 27, 2), (21, 80, 28, 1), (22, 87, 29, 3),
(22, 92, 30, 2), (23, 99, 31, 1), (24, 107, 32, 2), (22, 109, 33, 1)
GO

-- ============================================
-- ASKIDA YEMEK VERILERI (15 Askida Yemek)
-- ============================================

INSERT INTO AskidaYemek (KullaniciId, MenuId) VALUES
(2, 4),      -- Fatih - Carbonara (Restaurant 1)
(4, 12),     -- Mustafa - Fettucine Alfredo (Restaurant 1)
(7, 47),     -- Merve - Philly Roll Sushi (Restaurant 3)
(9, 52),     -- Duygu - Green Curry Chicken (Restaurant 3)
(11, 25),    -- Ozlem - Classic Burger (Restaurant 2)
(12, 72),    -- Hasan - Acili Sandwich (Restaurant 4)
(13, 95),    -- Emine - Mantarli Burger (Restaurant 5)
(14, 120),   -- Samet - Karidesli Garnitür (Restaurant 6)
(15, 20),    -- Ipek - Cay Bardagi (Restaurant 1)
(16, 30),    -- Cem - Karışık Kızartma (Restaurant 2)
(17, 46),    -- Sebnem - Philly Roll Sushi (Restaurant 3)
(18, 103),   -- Sinan - Kinoali Sebze Salata (Restaurant 5)
(19, 70),    -- Nuran - Sarimsakli Sandwich (Restaurant 4)
(20, 100),   -- Volkan - Kinoali Sebze Salata (Restaurant 5)
(25, 127)    -- Cigdem - Balik Suyu Corbasi (Restaurant 6)
GO


USE [RestoranDb] 
GO
WITH SatisSirala AS (
    SELECT
        r.RestaurantAdi,
        m.MenuAdi,
        SUM(s.SiparisAdet)  AS ToplamSatis,
        k.KullaniciAdi,
        k.KullaniciSoyadi,
        ROW_NUMBER() OVER (
            PARTITION BY r.RestaurantId
            ORDER BY SUM(s.SiparisAdet) DESC
        ) AS SiraNo
    FROM Siparisler s
    INNER JOIN Menu m         ON s.MenuId       = m.MenuId
    INNER JOIN Kategoriler kt ON m.KategoriId   = kt.KategoriId
    INNER JOIN Restaurant r   ON kt.RestaurantId = r.RestaurantId
    INNER JOIN Kullanici k    ON s.KullaniciId  = k.KullaniciId
    GROUP BY
        r.RestaurantId,
        r.RestaurantAdi,
        m.MenuId,
        m.MenuAdi,
        k.KullaniciId,
        k.KullaniciAdi,
        k.KullaniciSoyadi
)
SELECT
    RestaurantAdi,
    MenuAdi,
    ToplamSatis,
    KullaniciAdi,
    KullaniciSoyadi
FROM SatisSirala
WHERE SiraNo = 1
ORDER BY ToplamSatis DESC

SELECT
    r.RestaurantAdi,
    COUNT(DISTINCT kt.KategoriId)  AS ToplamKategoriSayisi,
    COUNT(DISTINCT m.MenuId)       AS ToplamMenuSayisi
FROM Restaurant r
LEFT JOIN Kategoriler kt ON r.RestaurantId = kt.RestaurantId
LEFT JOIN Menu m         ON kt.KategoriId  = m.KategoriId
GROUP BY
    r.RestaurantId,
    r.RestaurantAdi
HAVING
    COUNT(DISTINCT kt.KategoriId) > 0
 OR COUNT(DISTINCT m.MenuId)     > 0
ORDER BY ToplamKategoriSayisi DESC, ToplamMenuSayisi DESC

SELECT
    kur.KuryeAdi,
    kur.KuryeSoyadi,
    kur.KuryeMail
FROM Kurye kur
WHERE kur.KuryeId IN (
    -- Sipariş almış restoranlarla eşleşen kuryeler
    SELECT DISTINCT ks.KuryeId
    FROM KuryeSiparis ks
    INNER JOIN Siparisler s   ON ks.SiparisId   = s.SiparisId
    INNER JOIN Menu m         ON s.MenuId        = m.MenuId
    INNER JOIN Kategoriler kt ON m.KategoriId    = kt.KategoriId
    WHERE EXISTS (
        -- O restoranın aktif menüsü var mı?
        SELECT 1
        FROM Menu m2
        WHERE m2.KategoriId  = kt.KategoriId
          AND m2.MenuAktifMi = 1
    )
)
AND kur.KuryeAktifMi = 1
ORDER BY kur.KuryeAdi