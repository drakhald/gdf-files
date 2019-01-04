USE vizsga

-- Ha nem létezik a terem tábla, akkor létrehozza és feltölti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='terem')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='terem' AND xtype='U')
BEGIN
	CREATE TABLE terem(terem_száma INT NOT NULL IDENTITY(1,1) PRIMARY KEY,bef_képesség INT NOT NULL, gépek_száma INT)
	ALTER TABLE vizsga ADD 
	terem INT REFERENCES terem(terem_száma),
	idõtartam TINYINT DEFAULT 1,
	gépes_e TINYINT
	INSERT INTO terem VALUES(10,10)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
END
GO

-----------------------------------------------

-- új vizsga eljárás, ha van olyan, akkor eldobja és megint megcsinálja

IF object_id('uj_vizsga','p') IS NOT NULL
   DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@tárgy CHAR(4),@idõ SMALLDATETIME,@tanár INT,
   @max_fõ SMALLINT,@terem INT,@idõtartam TINYINT,@gépes_e TINYINT) 
AS
	DECLARE @ok INT
		SET @ok=1;

		IF @idõ<convert(SMALLDATETIME,getdate())
		BEGIN
			RAISERROR('Ma elõtti idõpontot nem lehet adni!',16,1)
			SET @ok=0;
		END

		IF @terem NOT IN (SELECT terem_száma FROM terem)
		BEGIN
			RAISERROR('A terem nem található!',16,1)
			SET @ok=0;
		END

		IF @idõtartam<1
		BEGIN
			RAISERROR('Az idõtartam 1 perctõl többnek kell lennie!',16,1)
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

		IF (@gépes_e=1)
			IF @terem NOT IN (SELECT terem_száma FROM terem WHERE gépek_száma>0)
			BEGIN
				RAISERROR('A terem nem gépes!',16,1)
				SET @ok=0;
			END

		IF (@gépes_e=0)
			IF @terem NOT IN (SELECT terem_száma FROM terem WHERE gépek_száma=0)
			BEGIN
				RAISERROR('A terem gépes!',16,1)
				SET @ok=0;
			END	

		IF @idõ IN(SELECT idõ FROM vizsga WHERE terem=@terem)
		BEGIN		
			RAISERROR('Már van vizsga a teremben!',16,1)
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

		declare @bef_képesség INT 
			SELECT @bef_képesség=bef_képesség FROM terem WHERE terem_száma=@terem

		IF @max_fõ>@bef_képesség
		BEGIN
			RAISERROR('Ekkora létszám nem fér a terembe!',16,1) 
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO vizsga VALUES(@szak,@tárgy,@idõ,@tanár,@max_fõ,@terem,@idõtartam,@gépes_e)
			raiserror('A vizsga létrejött',16,1)
			SET @ok=1;
		end

GO
----------------------------------------------