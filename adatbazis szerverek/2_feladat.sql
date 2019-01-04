USE vizsga

-- Ha nem létezik a tanár_tantárgy tábla, akkor létrehozza és feltölti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='tanár_tantárgy')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tanár_tantárgy' AND xtype='U')
BEGIN
	CREATE TABLE tanár_tantárgy(szkód INT NOT NULL ,tkód CHAR(4) NOT NULL, Primary key (szkód, tkód))

	INSERT INTO tanár_tantárgy VALUES(402,'ABSZ')
	INSERT INTO tanár_tantárgy VALUES(403,'PRII')
	INSERT INTO tanár_tantárgy VALUES(404,'PRI')
	INSERT INTO tanár_tantárgy VALUES(402,'SZTA')
	INSERT INTO tanár_tantárgy VALUES(405,'PROB')
END
GO
--tanár hozzárendelése a tárgyhoz
IF object_id('tanár_tantárgy_hozzá','p') IS NOT NULL
	DROP PROCEDURE tanár_tantárgy_hozzá
GO

CREATE PROCEDURE tanár_tantárgy_hozzá(@tárgy CHAR(4),@tanár INT)
AS
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

		SET @van=(SELECT COUNT(*) FROM tanár_tantárgy WHERE szkód=@tanár AND tkód=@tárgy)

		IF @van>0
		BEGIN
			RAISERROR('Ehez a Tanárhoz már ez a tárgy volt egyszer rendelve!',16,1)
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO tanár_tantárgy VALUES(@tanár,@tárgy)
			raiserror('A Tanár-Tantárgy kapcsolat létrejött',16,1)
			SET @ok=1;
		end

GO
------------------------------

-- új vizsga eljárás, ha van olyan, akkor eldobja és megint megcsinálja

IF object_id('uj_vizsga','p') IS NOT NULL
	DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@tárgy CHAR(4),@idõ SMALLDATETIME,@tanár INT,
						   @max_fõ SMALLINT)
AS
	DECLARE @ok INT
	DECLARE @van INT
		SET @ok=1;

		IF @idõ<convert(SMALLDATETIME,getdate())
		BEGIN
			RAISERROR('Ma elõtti idõpontot nem lehet adni!',16,1)
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
			RAISERROR('Tanár nem található!',16,1)
			SET @ok=0;
		END

		IF @tanár IN(SELECT tanár FROM vizsga WHERE idõ=@idõ)
		BEGIN
			RAISERROR('A tanár másik vizsgát tart!',16,1)
			SET @ok=0;
		END
				
		IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND tárgy=@tárgy)
		BEGIN
			RAISERROR('Ezen a szakon nincs ilyen tárgy!',16,1)
			SET @ok=0;
		END

		SET @van=(SELECT COUNT(*) FROM tanár_tantárgy WHERE szkód=@tanár AND tkód=@tárgy)

		IF @van=0
		BEGIN
			RAISERROR('Nincs a tanárhoz a tantárgy rendelve!',16,1)
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO vizsga VALUES(@szak,@tárgy,@idõ,@tanár,@max_fõ)
			raiserror('A vizsga létrejött',16,1)
			SET @ok=1;
		end

GO
----------------------------------------------