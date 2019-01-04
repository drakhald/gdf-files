USE vizsga

-- Ha nem létezik a terem tábla, akkor létrehozza és feltölti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='tárgy_felvétel')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tárgy_felvétel' AND xtype='U')
BEGIN
	CREATE TABLE tárgy_felvétel(hallgató INT NOT NULL, tárgy CHAR(4) NOT NULL,
								akt_szem INT NOT NULL, PRIMARY KEY (hallgató,tárgy,akt_szem))
END
GO

-----------------------------------------------

-- új felvetel eljárás, ha van olyan, akkor eldobja és megint megcsinálja

IF object_id('felvetel','p') IS NOT NULL
	DROP PROCEDURE felvetel
GO

CREATE PROCEDURE felvetel(@hallgato INT, @mit INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	IF @hallgato NOT IN(SELECT hkód FROM hallgató WHERE hkód=@hallgato)
		BEGIN
			RAISERROR('Nincs ilyen hallgató!',16,1)
			SET @ok=0;
		END
--Felvételek megtörténtek
	IF @ok=1
		BEGIN
			DECLARE @hallgato_osszesen_elozo INT
		-- Van-e a hallgatónak elmaradt tárgya
			SET @hallgato_osszesen_elozo= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
									tematika AS t, hallgató AS h WHERE j.jegy<=1 AND 
									j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.tárgy=t.tárgy AND h.hkód=j.hkód AND t.szemeszter<h.akt_szem)

			DECLARE @hallgato_osszesen_mostani INT
		--Van-e mostani tárgya
			SET @hallgato_osszesen_mostani= (SELECT COUNT(*) FROM tematika AS t, hallgató AS h WHERE 
											h.hkód=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter)
			

			IF @hallgato IN(SELECT hallgató FROM tárgy_felvétel WHERE hallgató=@hallgato)
				BEGIN
					IF @mit=1
						BEGIN
							
							IF 		(SELECT t.tárgy FROM jelentkezés AS j, vizsga AS v,
									tematika AS t, hallgató AS h WHERE j.jegy<=1 AND 
									j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.tárgy=t.tárgy AND h.hkód=j.hkód AND t.szemeszter<h.akt_szem)
												IN
									(SELECT t.tárgy FROM tárgy_felvétel AS t, hallgató AS h WHERE
									h.hkód=@hallgato AND h.hkód=t.hallgató AND h.akt_szem=t.akt_szem)
								BEGIN
									RAISERROR('A hallgató már felvette az elmaradtakat!',16,1)
									SET @ok=0;								
								END
						END
					IF @mit=0
						BEGIN
							
							IF 		(SELECT t.tárgy FROM tematika AS t, hallgató AS h WHERE 
									h.hkód=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter)
												IN
									(SELECT t.tárgy FROM tárgy_felvétel AS t, hallgató AS h WHERE
									h.hkód=@hallgato AND h.hkód=t.hallgató AND h.akt_szem=t.akt_szem)
								BEGIN
									RAISERROR('A hallgató már felvette a tárgyait!',16,1)
									SET @ok=0;
								END
						END
				END
		END
-----------------
	IF @ok=1
		BEGIN
			DECLARE @targy_osszesen INT
			DECLARE @hallgato_osszesen INT
		--Van-e még valamilyen vizsgája
			SET @hallgato_osszesen= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
									tematika AS t WHERE j.jegy>1 AND 
									j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

			SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
								tematika AS t WHERE j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

			IF @hallgato_osszesen=@targy_osszesen
				BEGIN
					RAISERROR('A hallgatónak nincs sem elmaradt, sem új tárgya!',16,1)
					SET @ok=0;
				END

			IF @mit=1
				BEGIN
					IF @hallgato_osszesen_elozo<1
						BEGIN
							RAISERROR('A hallgatónak nincs elmaradt vizsgája!',16,1)
							SET @ok=0;			
						END
					ELSE
						BEGIN
							INSERT INTO tárgy_felvétel (hallgató,tárgy,akt_szem)
									SELECT h.hkód,t.tárgy,h.akt_szem FROM jelentkezés AS j, vizsga AS v,
									tematika AS t, hallgató AS h WHERE j.jegy<=1 AND 
									j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.tárgy=t.tárgy AND h.hkód=j.hkód AND t.szemeszter<h.akt_szem
							RAISERROR('A hallgató fevette az elmaradt tárgyait!',16,1)
						END
				END
			IF @mit=0
				BEGIN
					IF @hallgato_osszesen_mostani<1
						BEGIN
							RAISERROR('A hallgatónak nincs új tárgya!',16,1)
							SET @ok=0;
						END	
					ELSE
						BEGIN
							INSERT INTO tárgy_felvétel (hallgató,tárgy,akt_szem)
									SELECT h.hkód,t.tárgy,h.akt_szem FROM tematika AS t, hallgató AS h WHERE
									h.hkód=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter
							RAISERROR('A hallgató fevette az új tárgyait!',16,1)
						END
				END
		END
GO

--DECLARE @rc INT;EXEC @rc=felvetel 6,1;SELECT @rc