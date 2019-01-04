USE vizsga

-- Ha nem l�tezik a terem t�bla, akkor l�trehozza �s felt�lti azt

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='t�rgy_felv�tel')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='t�rgy_felv�tel' AND xtype='U')
BEGIN
	CREATE TABLE t�rgy_felv�tel(hallgat� INT NOT NULL, t�rgy CHAR(4) NOT NULL,
								akt_szem INT NOT NULL, PRIMARY KEY (hallgat�,t�rgy,akt_szem))
END
GO

-----------------------------------------------

-- �j felvetel elj�r�s, ha van olyan, akkor eldobja �s megint megcsin�lja

IF object_id('felvetel','p') IS NOT NULL
	DROP PROCEDURE felvetel
GO

CREATE PROCEDURE felvetel(@hallgato INT, @mit INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	IF @hallgato NOT IN(SELECT hk�d FROM hallgat� WHERE hk�d=@hallgato)
		BEGIN
			RAISERROR('Nincs ilyen hallgat�!',16,1)
			SET @ok=0;
		END
--Felv�telek megt�rt�ntek
	IF @ok=1
		BEGIN
			DECLARE @hallgato_osszesen_elozo INT
		-- Van-e a hallgat�nak elmaradt t�rgya
			SET @hallgato_osszesen_elozo= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
									tematika AS t, hallgat� AS h WHERE j.jegy<=1 AND 
									j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.t�rgy=t.t�rgy AND h.hk�d=j.hk�d AND t.szemeszter<h.akt_szem)

			DECLARE @hallgato_osszesen_mostani INT
		--Van-e mostani t�rgya
			SET @hallgato_osszesen_mostani= (SELECT COUNT(*) FROM tematika AS t, hallgat� AS h WHERE 
											h.hk�d=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter)
			

			IF @hallgato IN(SELECT hallgat� FROM t�rgy_felv�tel WHERE hallgat�=@hallgato)
				BEGIN
					IF @mit=1
						BEGIN
							
							IF 		(SELECT t.t�rgy FROM jelentkez�s AS j, vizsga AS v,
									tematika AS t, hallgat� AS h WHERE j.jegy<=1 AND 
									j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.t�rgy=t.t�rgy AND h.hk�d=j.hk�d AND t.szemeszter<h.akt_szem)
												IN
									(SELECT t.t�rgy FROM t�rgy_felv�tel AS t, hallgat� AS h WHERE
									h.hk�d=@hallgato AND h.hk�d=t.hallgat� AND h.akt_szem=t.akt_szem)
								BEGIN
									RAISERROR('A hallgat� m�r felvette az elmaradtakat!',16,1)
									SET @ok=0;								
								END
						END
					IF @mit=0
						BEGIN
							
							IF 		(SELECT t.t�rgy FROM tematika AS t, hallgat� AS h WHERE 
									h.hk�d=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter)
												IN
									(SELECT t.t�rgy FROM t�rgy_felv�tel AS t, hallgat� AS h WHERE
									h.hk�d=@hallgato AND h.hk�d=t.hallgat� AND h.akt_szem=t.akt_szem)
								BEGIN
									RAISERROR('A hallgat� m�r felvette a t�rgyait!',16,1)
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
		--Van-e m�g valamilyen vizsg�ja
			SET @hallgato_osszesen= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
									tematika AS t WHERE j.jegy>1 AND 
									j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

			SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
								tematika AS t WHERE j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

			IF @hallgato_osszesen=@targy_osszesen
				BEGIN
					RAISERROR('A hallgat�nak nincs sem elmaradt, sem �j t�rgya!',16,1)
					SET @ok=0;
				END

			IF @mit=1
				BEGIN
					IF @hallgato_osszesen_elozo<1
						BEGIN
							RAISERROR('A hallgat�nak nincs elmaradt vizsg�ja!',16,1)
							SET @ok=0;			
						END
					ELSE
						BEGIN
							INSERT INTO t�rgy_felv�tel (hallgat�,t�rgy,akt_szem)
									SELECT h.hk�d,t.t�rgy,h.akt_szem FROM jelentkez�s AS j, vizsga AS v,
									tematika AS t, hallgat� AS h WHERE j.jegy<=1 AND 
									j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak
									AND v.t�rgy=t.t�rgy AND h.hk�d=j.hk�d AND t.szemeszter<h.akt_szem
							RAISERROR('A hallgat� fevette az elmaradt t�rgyait!',16,1)
						END
				END
			IF @mit=0
				BEGIN
					IF @hallgato_osszesen_mostani<1
						BEGIN
							RAISERROR('A hallgat�nak nincs �j t�rgya!',16,1)
							SET @ok=0;
						END	
					ELSE
						BEGIN
							INSERT INTO t�rgy_felv�tel (hallgat�,t�rgy,akt_szem)
									SELECT h.hk�d,t.t�rgy,h.akt_szem FROM tematika AS t, hallgat� AS h WHERE
									h.hk�d=@hallgato AND h.szak=t.szak AND h.akt_szem=t.szemeszter
							RAISERROR('A hallgat� fevette az �j t�rgyait!',16,1)
						END
				END
		END
GO

--DECLARE @rc INT;EXEC @rc=felvetel 6,1;SELECT @rc