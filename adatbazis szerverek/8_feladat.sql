USE vizsga

-- Ha nem létezik a Archivált_hallgatók tábla, akkor létrehozza

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='Archivált_hallgatók')
-- IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Archivált_hallgatók' AND xtype='U')
BEGIN
	CREATE TABLE Archivált_hallgatók(hkód INT NOT NULL PRIMARY KEY,szkód CHAR(3), akt_szem TINYINT,
	CONSTRAINT fk_szak_Archivált_hallgatók FOREIGN KEY (szkód) REFERENCES szak,
	CONSTRAINT fk_személy_Archivált_hallgatók FOREIGN KEY (hkód) REFERENCES személy)
END
GO

-----------------------------------------------

--Archiválás Procedure
IF object_id('Archivalas','p') IS NOT NULL
	DROP PROCEDURE Archivalas
GO

CREATE PROCEDURE Archivalas(@hallgato INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	IF @hallgato NOT IN(SELECT hkód FROM hallgató WHERE hkód=@hallgato)
		BEGIN
			RAISERROR('Nincs ilyen hallgató!',16,1)
			SET @ok=0;
		END

	IF @hallgato IN(SELECT hkód FROM Archivált_hallgatók WHERE hkód=@hallgato)
		BEGIN
			RAISERROR('Ez a hallgató már archiválva van!',16,1)
			SET @ok=0;
		END

	IF @ok=1
		BEGIN
			DECLARE @targy_osszesen INT
			DECLARE @hallgato_osszesen INT

			SET @hallgato_osszesen= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
										tematika AS t WHERE j.jegy>1 AND 
										j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

			SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
										tematika AS t WHERE j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

			IF @hallgato_osszesen=@targy_osszesen
				BEGIN
					INSERT INTO Archivált_hallgatók (hkód,szkód,akt_szem)
					SELECT hkód,szak,akt_szem FROM hallgató WHERE
					hkód=@hallgato

					RAISERROR('A hallgatót archiválása sikerült!',16,1)
				END
			ELSE
				BEGIN
					RAISERROR('A hallgatót még nem lehet archiválni!',16,1)
				END
		END
GO
-----------------------------

--DECLARE @rc INT;EXEC @rc=Archivalas 1;SELECT @rc