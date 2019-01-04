USE vizsga

-- Ha nem l�tezik a terem t�bla, akkor l�trehozza �s felt�lti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='terem')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='terem' AND xtype='U')
BEGIN
	CREATE TABLE terem(terem_sz�ma INT NOT NULL IDENTITY(1,1) PRIMARY KEY,bef_k�pess�g INT NOT NULL, g�pek_sz�ma INT)
	ALTER TABLE vizsga ADD 
	terem INT REFERENCES terem(terem_sz�ma),
	id�tartam TINYINT DEFAULT 1,
	g�pes_e TINYINT
	INSERT INTO terem VALUES(10,10)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
	INSERT INTO terem VALUES(20,0)
END
GO

-----------------------------------------------

-- �j vizsga elj�r�s, ha van olyan, akkor eldobja �s megint megcsin�lja

IF object_id('uj_vizsga','p') IS NOT NULL
   DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@t�rgy CHAR(4),@id� SMALLDATETIME,@tan�r INT,
   @max_f� SMALLINT,@terem INT,@id�tartam TINYINT,@g�pes_e TINYINT) 
AS
	DECLARE @ok INT
		SET @ok=1;

		IF @id�<convert(SMALLDATETIME,getdate())
		BEGIN
			RAISERROR('Ma el�tti id�pontot nem lehet adni!',16,1)
			SET @ok=0;
		END

		IF @terem NOT IN (SELECT terem_sz�ma FROM terem)
		BEGIN
			RAISERROR('A terem nem tal�lhat�!',16,1)
			SET @ok=0;
		END

		IF @id�tartam<1
		BEGIN
			RAISERROR('Az id�tartam 1 perct�l t�bbnek kell lennie!',16,1)
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

		IF (@g�pes_e=1)
			IF @terem NOT IN (SELECT terem_sz�ma FROM terem WHERE g�pek_sz�ma>0)
			BEGIN
				RAISERROR('A terem nem g�pes!',16,1)
				SET @ok=0;
			END

		IF (@g�pes_e=0)
			IF @terem NOT IN (SELECT terem_sz�ma FROM terem WHERE g�pek_sz�ma=0)
			BEGIN
				RAISERROR('A terem g�pes!',16,1)
				SET @ok=0;
			END	

		IF @id� IN(SELECT id� FROM vizsga WHERE terem=@terem)
		BEGIN		
			RAISERROR('M�r van vizsga a teremben!',16,1)
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

		declare @bef_k�pess�g INT 
			SELECT @bef_k�pess�g=bef_k�pess�g FROM terem WHERE terem_sz�ma=@terem

		IF @max_f�>@bef_k�pess�g
		BEGIN
			RAISERROR('Ekkora l�tsz�m nem f�r a terembe!',16,1) 
			SET @ok=0;
		END

		IF @ok = 1
		begin
			INSERT INTO vizsga VALUES(@szak,@t�rgy,@id�,@tan�r,@max_f�,@terem,@id�tartam,@g�pes_e)
			raiserror('A vizsga l�trej�tt',16,1)
			SET @ok=1;
		end

GO
----------------------------------------------