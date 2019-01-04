USE vizsga

-- vizsga-tematika tábla létrehozása

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='vizsga-tematika' AND xtype='U')
BEGIN
	CREATE TABLE [vizsga-tematika]
	(
		vizsga int NOT NULL,
		szak char(3) NOT NULL,
		tárgy char(4) NOT NULL,
		CONSTRAINT [PK_vizsga-tematika] PRIMARY KEY (vizsga,szak,tárgy)
	)

	ALTER TABLE [vizsga-tematika] ADD CONSTRAINT [FK_vizsga-tematika_tematika] FOREIGN KEY (szak,tárgy) REFERENCES dbo.tematika (szak,tárgy)
	ALTER TABLE [vizsga-tematika] ADD CONSTRAINT [FK_vizsga-tematika_vizsga] FOREIGN KEY (vizsga) REFERENCES dbo.vizsga (vizsga)
	
	INSERT INTO [vizsga-tematika] SELECT vizsga, szak, tárgy FROM vizsga;
	
	ALTER TABLE [vizsga] DROP CONSTRAINT [FK_vizsga_tematika]
	ALTER TABLE [vizsga] DROP COLUMN szak, tárgy 
END
GO

-- új vizsga eljárás

IF object_id('uj_vizsga','p') IS NOT NULL
	DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@tárgy CHAR(4),@idő SMALLDATETIME,@tanár INT,@max_fő SMALLINT) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;

	IF @idő<convert(SMALLDATETIME,getdate())
	BEGIN
		RAISERROR('Már elmúlt dátum nem megadható!',16,1)
		SET @ok=0;
	END

	IF @tárgy NOT IN (SELECT tkód FROM tantárgy)
	BEGIN
		RAISERROR('Tárgy nem található!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN (SELECT szkód FROM szak)
	BEGIN
		RAISERROR('Szak nem található!',16,1)
		SET @ok=0;
	END

	IF @tanár IN (SELECT szkód FROM tanár WHERE szkód=@tanár)
	BEGIN
		RAISERROR('A tanár nem található!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND tárgy=@tárgy)
	BEGIN
		RAISERROR('Ezen a szakon nincs ilyen tárgy!',16,1)
		SET @ok=0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO vizsga VALUES(@idő,@tanár,@max_fő);
		DECLARE @vizsga INT
		SELECT @vizsga = SCOPE_IDENTITY();
		
		IF @vizsga IS NOT NULL
		BEGIN
			INSERT INTO [vizsga-tematika] VALUES (@vizsga,@szak,@tárgy)
		END
		ELSE
		BEGIN
			RAISERROR('A vizsga nem hozható létre',16,1)
			SET @ok=0;
		END
	END

	RETURN @ok
END;
GO

IF object_id('uj_vizsga_tematika','p') IS NOT NULL
	DROP PROCEDURE uj_vizsga_tematika
GO

CREATE PROCEDURE uj_vizsga_tematika(@vizsga INT,@szak CHAR(3),@tárgy CHAR(4)) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;

	IF @vizsga NOT IN (SELECT vizsga FROM vizsga WHERE vizsga=@vizsga)
	BEGIN
		RAISERROR('A vizsga nem található!',16,1)
		SET @ok=0;
	END

	IF @tárgy NOT IN (SELECT tkód FROM tantárgy)
	BEGIN
		RAISERROR('Tárgy nem található!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN (SELECT szkód FROM szak)
	BEGIN
		RAISERROR('Szak nem található!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND tárgy=@tárgy)
	BEGIN
		RAISERROR('Ezen a szakon nincs ilyen tárgy!',16,1)
		SET @ok=0;
	END
	
	IF @vizsga IN (SELECT vizsga FROM [vizsga-tematika] WHERE vizsga=@vizsga AND szak=@szak AND tárgy=@tárgy)
	BEGIN
		raiserror('A vizsgához az adott tematika már fel van véve',16,1)
		SET @ok=0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO [vizsga-tematika] VALUES (@vizsga,@szak,@tárgy)
	END

	RETURN @ok
END;
GO


----------------------------------------------

-- teszt
-- hibás dátum, a tanár nem tanítja az adott tárgyat, a szakon nincs tárgy
EXEC uj_vizsga @szak='IKT',@tárgy='ABC',@idő='2008-12-13 11:00:00',@tanár=403,@max_fő=60;
-- hibás nincs vizsga, az adott szakon nincs tárgy
EXEC uj_vizsga_tematika @vizsga=122,@szak='IKT',@tárgy='ABC';


-- helyes vizsga
EXEC uj_vizsga @szak='MIT',@tárgy='ABSZ',@idő='2019-01-13 11:00:00',@tanár=403,@max_fő=20;
EXEC uj_vizsga_tematika @vizsga=6,@szak='IKT',@tárgy='ABK';
