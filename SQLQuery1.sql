USE [RestoranDb]
GO 

IF OBJECT_ID('Menu', 'U') IS NOT NULL DROP TABLE Menu
IF OBJECT_ID('Kategoriler', 'U') IS NOT NULL DROP TABLE Kategoriler
IF OBJECT_ID('Restaurant', 'U') IS NOT NULL DROP TABLE Restaurant
IF OBJECT_ID('Kullanici', 'U') IS NOT NULL DROP TABLE Kullanici
IF OBJECT_ID('Adresler', 'U') IS NOT NULL DROP TABLE Adresler
IF OBJECT_ID('Siparisler', 'U') IS NOT NULL DROP TABLE Siparisler

CREATE TABLE Rol(
	RolId TINYINT IDENTITY(1,1) PRIMARY KEY,
	RolAdi NVARCHAR(50) NOT NULL UNIQUE,

)

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
	RestaurantToplamCiro INT NULL,
	FOREIGN KEY (RestaurantRol) REFERENCES Rol(RolId)
)
--RESTAURANT CÝRO ÝÇÝN TRÝGGER GEREKLÝ

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
	CHECK(MenuFiyat>0),
	MenuAciklama NVARCHAR(300) NOT NULL,
	MenuVarMi BIT NOT NULL,
	MenuAktifMi BIT DEFAULT 1,
	FOREIGN KEY (KategoriId) REFERENCES Kategoriler(KategoriId)
)

CREATE TABLE Kullanici(
	KullaniciId INT IDENTITY(1,1) PRIMARY KEY,
	KullaniciRol TINYINT NOT NULL,
	KullaniciAdi NVARCHAR(50) NOT NULL,
	KullaniciSoyadi NVARCHAR(50) NOT NULL,
	KullaniciMail NVARCHAR(100) NOT NULL UNIQUE,
	KullaniciParola NVARCHAR(256) NOT NULL UNIQUE,
	KullaniciCuzdan INT DEFAULT 0,
	FOREIGN KEY (KullaniciRol) REFERENCES Rol(RolId)
)
CREATE TABLE Kartlar(
	KartId INT IDENTITY(1,1) PRIMARY KEY,
	KullaniciId INT NOT NULL,
	Isim NVARCHAR(50) NOT NULL,
	SoyIsim NVARCHAR (50) NOT NULL,
	KartNumarasi NVARCHAR(16) NOT NULL UNIQUE,
	Tarih NVARCHAR(5) NOT NULL,
	CVC2No NVARCHAR(3) NOT NULL,
	FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId)
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
	SiparisTarihi AS GETDATE(),
	FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciId),
	FOREIGN KEY (MenuId) REFERENCES Menu(MenuId),
	FOREIGN KEY (AdresId) REFERENCES Adresler(AdresId),
)


CREATE TABLE Kurye(
	KuryeId INT IDENTITY(1,1) PRIMARY KEY,
	KuryeRol TINYINT NOT NULL,
	KuryeAdi NVARCHAR(50) NOT NULL,
	KuryeSoyadi NVARCHAR(50) NOT NULL,
	KuryeTCNO NVARCHAR(11) NOT NULL UNIQUE,
	KuryeMail NVARCHAR(256) NOT NULL UNIQUE,
	KuryeParola NVARCHAR(256) NOT NULL UNIQUE,
	FOREIGN KEY (KuryeRol) REFERENCES Rol(RolId)
)

CREATE TABLE KuryeSiparis(
	Id INT IDENTITY(1,1) PRIMARY KEY,
	KuryeId INT,
	SiparisId INT,
	FOREIGN KEY (KuryeId) REFERENCES Kurye(KuryeId),
	FOREIGN KEY(SiparisId) REFERENCES Siparisler(SiparisId)
)



