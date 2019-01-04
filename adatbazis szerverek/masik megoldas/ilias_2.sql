USE vizsga

-- tanár-tantárgy tábla létrehozása

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tanár-tantárgy' AND xtype='U')
BEGIN
	CREATE TABLE [tanár-tantárgy]
	(
		szkód int NOT NULL,
		tkód char(4) NOT NULL,
		CONSTRAINT [PK_tanár-tantárgy] PRIMARY KEY (szkód,tkód)
	)

	ALTER TABLE [tanár-tantárgy] ADD CONSTRAINT [FK_tanár-tantárgy_személy] FOREIGN KEY (szkód) REFERENCES dbo.személy (szkód)
	ALTER TABLE [tanár-tantárgy] ADD CONSTRAINT [FK_tanár-tantárgy_tantárgy] FOREIGN KEY (tkód) REFERENCES tantárgy (tkód)
END
ELSE  
	ALTER TABLE [tanár-tantárgy] DROP CONSTRAINT [CK_tanár-tantárgy_szkód]
GO

-- tanár check

IF object_id('tanar_e','fn') IS NOT NULL
	DROP FUNCTION tanar_e
GO

CREATE FUNCTION tanar_e(@szkód INT) RETURNS INT
AS
BEGIN
	DECLARE @return INT
	SET @return = 1;

	IF @szkód NOT IN (SELECT szkód FROM személy WHERE szkód NOT IN(SELECT hkód FROM hallgató))
	BEGIN
		SET @return=0;
	END
	
	RETURN @return;
END
GO

ALTER TABLE [tanár-tantárgy] ADD CONSTRAINT [CK_tanár-tantárgy_szkód] CHECK (dbo.tanar_e(szkód) = 1)

--tanár hozzárendelése a tárgyhoz
IF object_id('tanár_tantárgy_hozzá','p') IS NOT NULL
	DROP PROCEDURE tanár_tantárgy_hozzá
GO

CREATE PROCEDURE tanár_tantárgy_hozzá(@tárgy CHAR(4),@tanár INT)
AS
BEGIN
	DECLARE @ok INT
	DECLARE @van INT

	SET @ok=1;

	IF @tanár NOT IN (SELECT szkód FROM személy WHERE szkód NOT IN(SELECT hkód FROM hallgató))
	BEGIN
		RAISERROR('Tanár nem található!',16,1)
		SET @ok=0;
	END

	IF @tárgy NOT IN (SELECT tkód FROM tantárgy)
	BEGIN
		RAISERROR('Tárgy nem található!',16,1)
		SET @ok=0;
	END

	IF EXISTS (SELECT szkód FROM tanár_tantárgy WHERE szkód=@tanár AND tkód=@tárgy)
	BEGIN
		RAISERROR('Ehez a Tanárhoz már ez a tárgy volt egyszer rendelve!',16,1)
		SET @ok=0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO tanár_tantárgy VALUES(@tanár,@tárgy)
	END

	RETURN @ok
END;
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

	IF @tanár NOT IN (SELECT szkód FROM személy WHERE szkód NOT IN(SELECT hkód FROM hallgató))
	BEGIN
		RAISERROR('A tanár nem található!',16,1)
		SET @ok=0;
	END

	IF @tárgy NOT IN (SELECT tkód FROM [tanár-tantárgy] WHERE szkód=@tanár AND tkód=@tárgy)
	BEGIN
		RAISERROR('A tanár nem tanítja ezt a tárgyat!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND tárgy=@tárgy)
	BEGIN
		RAISERROR('Ezen a szakon nincs ilyen tárgy!',16,1)
		SET @ok=0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO vizsga VALUES(@szak,@tárgy,@idő,@tanár,@max_fő)
	END

	RETURN @ok
END;
GO
----------------------------------------------

-- tanár-tantárgy
IF NOT EXISTS (SELECT * FROM [tanár-tantárgy] WHERE szkód = 403 AND tkód = 'ABSZ')
	INSERT INTO [tanár-tantárgy] VALUES (403,'ABSZ');


-- teszt
-- hibás dátum, a tanár nem tanítja az adott tárgyat, a szakon nincs tárgy
EXEC uj_vizsga @szak='IKT',@tárgy='ABC',@idő='2008-12-13 11:00:00',@tanár=403,@max_fő=60;
-- helyes vizsga
EXEC uj_vizsga @szak='MIT',@tárgy='ABSZ',@idő='2019-01-13 11:00:00',@tanár=403,@max_fő=20;