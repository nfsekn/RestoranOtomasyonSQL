USE [RestoranDb]
GO 

IF OBJECT_ID('Menu', 'U') IS NOT NULL DROP TABLE Menu
IF OBJECT_ID('Kategoriler', 'U') IS NOT NULL DROP TABLE Kategoriler
IF OBJECT_ID('Restaurant', 'U') IS NOT NULL DROP TABLE Restaurant
IF OBJECT_ID('Kullanici', 'U') IS NOT NULL DROP TABLE Kullanici
IF OBJECT_ID('Adresler', 'U') IS NOT NULL DROP TABLE Adresler
IF OBJECT_ID('Siparisler', 'U') IS NOT NULL DROP TABLE Siparisler


CREATE TABLE Restaurant(
	RestaurantId INT IDENTITY(1,1) PRIMARY KEY,
	RestaurantAdi NVARCHAR(50) NOT NULL,
	RestaurantMail NVARCHAR(100) NOT NULL,
	RestaurantParola NVARCHAR(256) NOT NULL,
	RestaurantSehir NVARCHAR(20) NOT NULL,
	RestaurantAdres NVARCHAR(200) NOT NULL,
	RestaurantVergiNo NVARCHAR(11) NOT NULL,
	RestaurantTelNo NVARCHAR(11) NOT NULL,
	RestaurantLogoUrl NVARCHAR(500),
	RestaurantMinTutar DECIMAL(10,2),
	RestaurantTeslimSuresi NVARCHAR(2),
	RestaurantAcilisSaati TIME,
	RestaurantKapanisSaati TIME,
	RestaurantAcikMi BIT NOT NULL,
	RestaurantAktifMi BIT DEFAULT 1,
)

CREATE TABLE Kategoriler(
	KategoriId INT IDENTITY(1,1) PRIMARY KEY,
	RestaurantId INT NOT NULL,
	KategoriAdi NVARCHAR(20) NOT NULL,
	KategoriAciklama NVARCHAR(300) NOT NULL,
	FOREIGN KEY (RestaurantId) REFERENCES Restaurant(RestaurantId)
)

CREATE TABLE Menu(
	MenuId INT IDENTITY(1,1) PRIMARY KEY,
	KategoriId INT NOT NULL,
	MenuAdi NVARCHAR(50) NOT NULL,
	MenuFiyat DECIMAL(10,2) NOT NULL,
	MenuAciklama NVARCHAR(300) NOT NULL,
	MenuVarMi BIT NOT NULL,
	MenuAktifMi BIT DEFAULT 1,
	FOREIGN KEY (KategoriId) REFERENCES Kategoriler(KategoriId)
)
CREATE TABLE Kullanici(
	KullaniciId INT IDENTITY(1,1) PRIMARY KEY,
	KullaniciAdi NVARCHAR(50) NOT NULL,
	KullaniciSoyadi NVARCHAR(50) NOT NULL,
	KullaniciMail NVARCHAR(100) NOT NULL,
	KullaniciParola NVARCHAR(256) NOT NULL,
)

CREATE TABLE Adresler(
	AdresId INT IDENTITY(1,1) PRIMARY KEY,
	KullaniciId INT NOT NULL,
	AdresBaslik NVARCHAR(50) NOT NULL,
	AdresSehir NVARCHAR(20) NOT NULL,
	AdresIlce NVARCHAR(30) NOT NULL,
	AcikAdres NVARCHAR(300) NOT NULL,
	FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId)

)

CREATE TABLE Siparisler(
	SiparisId INT IDENTITY(1,1) PRIMARY KEY,
	KullaniciId INT NOT NULL,
	MenuId INT NOT NULL,
	AdresId INT NOT NULL,
	SiparisAdet TINYINT NOT NULL,
	FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId),
	FOREIGN KEY (MenuId) REFERENCES Menu(MenuId),
	FOREIGN KEY (AdresId) REFERENCES Adresler(AdresId),
)
