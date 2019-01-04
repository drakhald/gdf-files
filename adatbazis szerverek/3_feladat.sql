USE vizsga
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='vizsga_tematika')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='vizsga_tematika' AND xtype='U')
BEGIN
CREATE TABLE [vizsga_tematika]
(
vizsga int NOT NULL,
szak char(3) NOT NULL,
tárgy char(4) NOT NULL,
CONSTRAINT [PK_vizsga-tematika] PRIMARY KEY (vizsga,szak,tárgy)
)

ALTER TABLE [vizsga_tematika] ADD CONSTRAINT [FK_vizsga-tematika_tematika] FOREIGN KEY (szak,tárgy) REFERENCES dbo.tematika (szak,tárgy)
ALTER TABLE [vizsga_tematika] ADD CONSTRAINT [FK_vizsga-tematika_vizsga] FOREIGN KEY (vizsga) REFERENCES dbo.vizsga (vizsga)

IF EXISTS (SELECT 1  FROM SYS.COLUMNS WHERE  
OBJECT_ID = OBJECT_ID(N'[dbo].[vizsga]') AND name = 'szak')  
INSERT INTO [vizsga_tematika] SELECT vizsga, szak, tárgy FROM vizsga;
ALTER TABLE [vizsga] DROP CONSTRAINT [FK_vizsga_tematika]
ALTER TABLE [vizsga] DROP COLUMN szak, tárgy
END
GO

CREATE PROCEDURE uj_vizsga (@szak CHAR(3),@tárgy CHAR(4),@idõ SMALLDATETIME, @tanár INT, @max_fõ SMALLINT )
AS 
	DECLARE @ok INT
	SET @ok=1;

IF @szak NOT IN (SELECT szkód FROM szak )
	BEGIN 
	RAISERROR ('A szak nem létezik',16,1)
	SET @ok=0; 
	END
IF @tárgy NOT IN (SELECT tkód FROM tantárgy)
	BEGIN 
	RAISERROR('A tantárgy nem létezik',16,1)
	SET @ok=0;
	END
IF @idõ<=CONVERT(smalldatetime, getdate())
	BEGIN
	RAISERROR('Legkorábbra holnapra lehet vizsgát kiírni',16,1)
	SET @ok=0;
	END
IF @tanár NOT IN(SELECT szkód FROM személy WHERE szkód NOT IN (SELECT hkód FROM hallgató))
	BEGIN
	RAISERROR('TANÁR NEM LÉTEZIK',16,1)
	SET @ok=0;
	END
IF @ok=1 
	BEGIN
	INSERT INTO vizsga VALUES (@idõ,@tanár,@max_fõ)
	DECLARE @vizsga_sel INT
	SET @vizsga_sel= (SELECT vizsga FROM vizsga WHERE @tanár=tanár AND @idõ=idõ)
	INSERT INTO vizsga_tematika VALUES(@vizsga_sel,@szak,@tárgy)
	RAISERROR ('A vizsga létrejött',16,1)
	SET @ok=1;
	END
GO

IF OBJECT_ID('vizsga_új_tematika') IS NOT NULL
DROP PROCEDURE vizsga_új_tematika 
GO

CREATE PROCEDURE vizsga_új_tematika (@vizsga INT ,@szak CHAR(3),@tárgy CHAR(4))
	AS
	DECLARE @ok INT
	DECLARE @van INT
	SET @ok=1;
	SET @van=0;

IF @vizsga NOT IN (SELECT vizsga FROM vizsga)
	BEGIN
		RAISERROR('vizsga nem létezik',16,1)
		SET @ok=0;
	END
IF @szak NOT IN (SELECT szkód FROM szak)
	BEGIN 
		RAISERROR('szak nem létezik',16,1)
		SET @ok=0;
	END
IF @tárgy NOT IN (SELECT tárgy FROM tematika WHERE szak=@szak )
	BEGIN
		RAISERROR('tárgy nem létezik ezen a szakon',16,1)
		SET @ok=0;
	END
SET @van=(SELECT COUNT(*) FROM [vizsga_tematika] WHERE vizsga=@vizsga AND szak=@szak AND tárgy=@tárgy )

IF @ok=1 AND @van=0
	BEGIN
	INSERT INTO vizsga_tematika VALUES(@vizsga, @szak, @tárgy)
	RAISERROR('A vizsga tematika bõvítése létrejött',16,1)
	SET @ok=1;
	End
go

/*
Új vizsga teszt
Létezõ tanár,idõpont,tárgy a szakon
EXEC 	uj_vizsga 'MIT',ABK,'2019-10-01 00:00:00',406,20 
Nem létezõ tanár
EXEC 	uj_vizsga 'MIT',ABK,'2019-10-01 00:00:00',412,20 
Hibás idõpont
EXEC 	uj_vizsga 'MIT',ABK,'2017-10-01 00:00:00',406,20 


Teszt bõvites
Létezõ tárgy a szakon
EXEC vizsga_új_tematika 1,MIT,ABK
Nem létezõ tárgy a szakon
EXEC vizsga_új_tematika 1,MIT,ABSZ
*/
/*
DECLARE @tanár INT
DECLARE @idõ SMALLDATETIME
DECLARE @max_fõ INT
SET @tanár=412
SET @idõ='2019-01-01 00:00:00'
SET @max_fõ=10
INSERT INTO vizsga (idõ,tanár,max_fõ) VALUES (@idõ,@tanár,@max_fõ)
*/