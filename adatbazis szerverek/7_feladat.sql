USE vizsga

-- Ha nem létezik a félévi_eredmények tábla, akkor létrehozza és feltölti azt, tematikához tesz egy oszlopot

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='félévi_eredmények')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='félévi_eredmények' AND xtype='U')
BEGIN
	CREATE TABLE félévi_eredmények(hallgató INT NOT NULL,szemeszter INT NOT NULL, összkredit INT, PRIMARY KEY(hallgató,szemeszter))
	ALTER TABLE tematika ADD kreditérték INT,
	CONSTRAINT ck_kreditérték CHECK (kreditérték>= 1 AND kreditérték<=10)

END
go

-----------------------------------------------

-- új félév zárása, ha van olyan, akkor eldobja és megint megcsinálja

IF object_id('felev_zaras','p') IS NOT NULL
	DROP PROCEDURE felev_zaras
GO

-- Ha a ki változóban 1-est kap, akkor lezár mindenkit, különben a hallgatót és hallgató 0-a
CREATE PROCEDURE felev_zaras(@hall INT,@ki INT)
AS
	
	declare @db INT
	declare @tol INT
	declare @hallgato_szem INT 
	declare @szak CHAR(3) 
	declare @szak_szem INT 
	SET @tol=1;
	DECLARE @ok INT
	declare @kredit INT
	declare @hallgato INT
		IF @ki=1 AND @hall=0
			BEGIN
				SET @db= (SELECT COUNT(*) FROM hallgató)
			END
		ELSE
			BEGIN
				SET @db=1
			END

	WHILE @tol<=@db
		BEGIN
			SET @hallgato_szem=0;
			SET @szak=0;
			SET @szak_szem=0;
			SET @ok=1;
			SET @kredit=0;

			IF @ki=1 AND @hall=0
				BEGIN
					SET @hallgato=@tol;
				END
			ELSE
				BEGIN
					SET @hallgato=@hall;
				END
				


					SET @ok=1;

					IF @hallgato NOT IN(SELECT hkód FROM hallgató WHERE hkód=@hallgato)
					BEGIN
						RAISERROR('Nincs ilyen hallgató!',16,1)
						SET @ok=0;
					END
			--Hallgató és a szak szemeszter kiszedése
					SET @hallgato_szem=0;
					SELECT @hallgato_szem=akt_szem, @szak=szak FROM hallgató WHERE hkód=@hallgato
					SELECT @szak_szem=szemeszter FROM szak WHERE szkód=@szak
			-----------------------------
			-- Ha aktuális kissebb egyenlõ mint a szakhoz tartozó, kredit számít
					IF @ok = 1
					BEGIN
						IF @hallgato_szem<=@szak_szem
						BEGIN
							declare @hallgato_ketto INT
				--Kredit kiszámítása
							SET @kredit=
										(SELECT SUM(t.kreditérték) FROM jelentkezés AS j, vizsga AS v,
										tematika AS t WHERE j.jegy>1 AND j.szem=@hallgato_szem AND 
										j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)
				---------------------------
							SET @hallgato_ketto=@hallgato_szem+1;
							INSERT INTO félévi_eredmények VALUES(@hallgato,@hallgato_szem,@kredit)
							raiserror('A félév zárás megtörtént!',16,1)
							SET @ok=1;
							UPDATE hallgató SET akt_szem=akt_szem+1 WHERE hkód=@hallgato
						END
					END
			-------------------------------------
					SET @tol=@tol+1;
		END
GO

--DECLARE @rc INT;EXEC @rc=felev_zaras 0,1;SELECT @rc