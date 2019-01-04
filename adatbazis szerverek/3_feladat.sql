USE vizsga
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='vizsga_tematika')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='vizsga_tematika' AND xtype='U')
BEGIN
CREATE TABLE [vizsga_tematika]
(
vizsga int NOT NULL,
szak char(3) NOT NULL,
t�rgy char(4) NOT NULL,
CONSTRAINT [PK_vizsga-tematika] PRIMARY KEY (vizsga,szak,t�rgy)
)

ALTER TABLE [vizsga_tematika] ADD CONSTRAINT [FK_vizsga-tematika_tematika] FOREIGN KEY (szak,t�rgy) REFERENCES dbo.tematika (szak,t�rgy)
ALTER TABLE [vizsga_tematika] ADD CONSTRAINT [FK_vizsga-tematika_vizsga] FOREIGN KEY (vizsga) REFERENCES dbo.vizsga (vizsga)

IF EXISTS (SELECT 1  FROM SYS.COLUMNS WHERE  
OBJECT_ID = OBJECT_ID(N'[dbo].[vizsga]') AND name = 'szak')  
INSERT INTO [vizsga_tematika] SELECT vizsga, szak, t�rgy FROM vizsga;
ALTER TABLE [vizsga] DROP CONSTRAINT [FK_vizsga_tematika]
ALTER TABLE [vizsga] DROP COLUMN szak, t�rgy
END
GO

CREATE PROCEDURE uj_vizsga (@szak CHAR(3),@t�rgy CHAR(4),@id� SMALLDATETIME, @tan�r INT, @max_f� SMALLINT )
AS 
	DECLARE @ok INT
	SET @ok=1;

IF @szak NOT IN (SELECT szk�d FROM szak )
	BEGIN 
	RAISERROR ('A szak nem l�tezik',16,1)
	SET @ok=0; 
	END
IF @t�rgy NOT IN (SELECT tk�d FROM tant�rgy)
	BEGIN 
	RAISERROR('A tant�rgy nem l�tezik',16,1)
	SET @ok=0;
	END
IF @id�<=CONVERT(smalldatetime, getdate())
	BEGIN
	RAISERROR('Legkor�bbra holnapra lehet vizsg�t ki�rni',16,1)
	SET @ok=0;
	END
IF @tan�r NOT IN(SELECT szk�d FROM szem�ly WHERE szk�d NOT IN (SELECT hk�d FROM hallgat�))
	BEGIN
	RAISERROR('TAN�R NEM L�TEZIK',16,1)
	SET @ok=0;
	END
IF @ok=1 
	BEGIN
	INSERT INTO vizsga VALUES (@id�,@tan�r,@max_f�)
	DECLARE @vizsga_sel INT
	SET @vizsga_sel= (SELECT vizsga FROM vizsga WHERE @tan�r=tan�r AND @id�=id�)
	INSERT INTO vizsga_tematika VALUES(@vizsga_sel,@szak,@t�rgy)
	RAISERROR ('A vizsga l�trej�tt',16,1)
	SET @ok=1;
	END
GO

IF OBJECT_ID('vizsga_�j_tematika') IS NOT NULL
DROP PROCEDURE vizsga_�j_tematika 
GO

CREATE PROCEDURE vizsga_�j_tematika (@vizsga INT ,@szak CHAR(3),@t�rgy CHAR(4))
	AS
	DECLARE @ok INT
	DECLARE @van INT
	SET @ok=1;
	SET @van=0;

IF @vizsga NOT IN (SELECT vizsga FROM vizsga)
	BEGIN
		RAISERROR('vizsga nem l�tezik',16,1)
		SET @ok=0;
	END
IF @szak NOT IN (SELECT szk�d FROM szak)
	BEGIN 
		RAISERROR('szak nem l�tezik',16,1)
		SET @ok=0;
	END
IF @t�rgy NOT IN (SELECT t�rgy FROM tematika WHERE szak=@szak )
	BEGIN
		RAISERROR('t�rgy nem l�tezik ezen a szakon',16,1)
		SET @ok=0;
	END
SET @van=(SELECT COUNT(*) FROM [vizsga_tematika] WHERE vizsga=@vizsga AND szak=@szak AND t�rgy=@t�rgy )

IF @ok=1 AND @van=0
	BEGIN
	INSERT INTO vizsga_tematika VALUES(@vizsga, @szak, @t�rgy)
	RAISERROR('A vizsga tematika b�v�t�se l�trej�tt',16,1)
	SET @ok=1;
	End
go

/*
�j vizsga teszt
L�tez� tan�r,id�pont,t�rgy a szakon
EXEC 	uj_vizsga 'MIT',ABK,'2019-10-01 00:00:00',406,20 
Nem l�tez� tan�r
EXEC 	uj_vizsga 'MIT',ABK,'2019-10-01 00:00:00',412,20 
Hib�s id�pont
EXEC 	uj_vizsga 'MIT',ABK,'2017-10-01 00:00:00',406,20 


Teszt b�vites
L�tez� t�rgy a szakon
EXEC vizsga_�j_tematika 1,MIT,ABK
Nem l�tez� t�rgy a szakon
EXEC vizsga_�j_tematika 1,MIT,ABSZ
*/
/*
DECLARE @tan�r INT
DECLARE @id� SMALLDATETIME
DECLARE @max_f� INT
SET @tan�r=412
SET @id�='2019-01-01 00:00:00'
SET @max_f�=10
INSERT INTO vizsga (id�,tan�r,max_f�) VALUES (@id�,@tan�r,@max_f�)
*/