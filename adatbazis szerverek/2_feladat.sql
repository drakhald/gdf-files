USE vizsga

-- Ha nem l�tezik a tan�r_tant�rgy t�bla, akkor l�trehozza �s felt�lti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='tan�r_tant�rgy')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tan�r_tant�rgy' AND xtype='U')
BEGIN
	CREATE TABLE tan�r_tant�rgy(szk�d INT NOT NULL ,tk�d CHAR(4) NOT NULL, Primary key (szk�d, tk�d))

	INSERT INTO tan�r_tant�rgy VALUES(402,'ABSZ')
	INSERT INTO tan�r_tant�rgy VALUES(403,'PRII')
	INSERT INTO tan�r_tant�rgy VALUES(404,'PRI')
	INSERT INTO tan�r_tant�rgy VALUES(402,'SZTA')
	INSERT INTO tan�r_tant�rgy VALUES(405,'PROB')
END
GO
--tan�r hozz�rendel�se a t�rgyhoz
IF object_id('tan�r_tant�rgy_hozz�','p') IS NOT NULL
	DROP PROCEDURE tan�r_tant�rgy_hozz�
GO

CREATE PROCEDURE tan�r_tant�rgy_hozz�(@t�rgy CHAR(4),@tan�r INT)
AS
	DECLARE @ok INT
	DECLARE @van INT

		SET @ok=1;

		IF @tan�r NOT IN (SELECT szk�d FROM szem�ly WHERE szk�d NOT IN(SELECT hk�d FROM hallgat�))
		BEGIN
			RAISERROR('Tan�r nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		IF @t�rgy NOT IN (SELECT tk�d FROM tant�rgy)
		BEGIN
			RAISERROR('T�rgy nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		SET @van=(SELECT COUNT(*) FROM tan�r_tant�rgy WHERE szk�d=@tan�r AND tk�d=@t�rgy)

		IF @van>0
		BEGIN
			RAISERROR('Ehez a Tan�rhoz m�r ez a t�rgy volt egyszer rendelve!',16,1)
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO tan�r_tant�rgy VALUES(@tan�r,@t�rgy)
			raiserror('A Tan�r-Tant�rgy kapcsolat l�trej�tt',16,1)
			SET @ok=1;
		end

GO
------------------------------

-- �j vizsga elj�r�s, ha van olyan, akkor eldobja �s megint megcsin�lja

IF object_id('uj_vizsga','p') IS NOT NULL
	DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@t�rgy CHAR(4),@id� SMALLDATETIME,@tan�r INT,
						   @max_f� SMALLINT)
AS
	DECLARE @ok INT
	DECLARE @van INT
		SET @ok=1;

		IF @id�<convert(SMALLDATETIME,getdate())
		BEGIN
			RAISERROR('Ma el�tti id�pontot nem lehet adni!',16,1)
			SET @ok=0;
		END

		IF @t�rgy NOT IN (SELECT tk�d FROM tant�rgy)
		BEGIN
			RAISERROR('T�rgy nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		IF @szak NOT IN (SELECT szk�d FROM szak)
		BEGIN
			RAISERROR('Szak nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		IF @tan�r NOT IN (SELECT szk�d FROM szem�ly WHERE szk�d NOT IN(SELECT hk�d FROM hallgat�))
		BEGIN
			RAISERROR('Tan�r nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		IF @tan�r IN(SELECT tan�r FROM vizsga WHERE id�=@id�)
		BEGIN
			RAISERROR('A tan�r m�sik vizsg�t tart!',16,1)
			SET @ok=0;
		END
				
		IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND t�rgy=@t�rgy)
		BEGIN
			RAISERROR('Ezen a szakon nincs ilyen t�rgy!',16,1)
			SET @ok=0;
		END

		SET @van=(SELECT COUNT(*) FROM tan�r_tant�rgy WHERE szk�d=@tan�r AND tk�d=@t�rgy)

		IF @van=0
		BEGIN
			RAISERROR('Nincs a tan�rhoz a tant�rgy rendelve!',16,1)
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO vizsga VALUES(@szak,@t�rgy,@id�,@tan�r,@max_f�)
			raiserror('A vizsga l�trej�tt',16,1)
			SET @ok=1;
		end

GO
----------------------------------------------