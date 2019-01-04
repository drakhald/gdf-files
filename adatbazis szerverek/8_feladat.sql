USE vizsga

-- Ha nem l�tezik a Archiv�lt_hallgat�k t�bla, akkor l�trehozza

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='Archiv�lt_hallgat�k')
-- IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Archiv�lt_hallgat�k' AND xtype='U')
BEGIN
	CREATE TABLE Archiv�lt_hallgat�k(hk�d INT NOT NULL PRIMARY KEY,szk�d CHAR(3), akt_szem TINYINT,
	CONSTRAINT fk_szak_Archiv�lt_hallgat�k FOREIGN KEY (szk�d) REFERENCES szak,
	CONSTRAINT fk_szem�ly_Archiv�lt_hallgat�k FOREIGN KEY (hk�d) REFERENCES szem�ly)
END
GO

-----------------------------------------------

--Archiv�l�s Procedure
IF object_id('Archivalas','p') IS NOT NULL
	DROP PROCEDURE Archivalas
GO

CREATE PROCEDURE Archivalas(@hallgato INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	IF @hallgato NOT IN(SELECT hk�d FROM hallgat� WHERE hk�d=@hallgato)
		BEGIN
			RAISERROR('Nincs ilyen hallgat�!',16,1)
			SET @ok=0;
		END

	IF @hallgato IN(SELECT hk�d FROM Archiv�lt_hallgat�k WHERE hk�d=@hallgato)
		BEGIN
			RAISERROR('Ez a hallgat� m�r archiv�lva van!',16,1)
			SET @ok=0;
		END

	IF @ok=1
		BEGIN
			DECLARE @targy_osszesen INT
			DECLARE @hallgato_osszesen INT

			SET @hallgato_osszesen= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
										tematika AS t WHERE j.jegy>1 AND 
										j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

			SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
										tematika AS t WHERE j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

			IF @hallgato_osszesen=@targy_osszesen
				BEGIN
					INSERT INTO Archiv�lt_hallgat�k (hk�d,szk�d,akt_szem)
					SELECT hk�d,szak,akt_szem FROM hallgat� WHERE
					hk�d=@hallgato

					RAISERROR('A hallgat�t archiv�l�sa siker�lt!',16,1)
				END
			ELSE
				BEGIN
					RAISERROR('A hallgat�t m�g nem lehet archiv�lni!',16,1)
				END
		END
GO
-----------------------------

--DECLARE @rc INT;EXEC @rc=Archivalas 1;SELECT @rc