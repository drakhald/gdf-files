USE vizsga

-- Ha nem l�tezik a f�l�vi_eredm�nyek t�bla, akkor l�trehozza �s felt�lti azt, tematik�hoz tesz egy oszlopot

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='f�l�vi_eredm�nyek')
--IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='f�l�vi_eredm�nyek' AND xtype='U')
BEGIN
	CREATE TABLE f�l�vi_eredm�nyek(hallgat� INT NOT NULL,szemeszter INT NOT NULL, �sszkredit INT, PRIMARY KEY(hallgat�,szemeszter))
	ALTER TABLE tematika ADD kredit�rt�k INT,
	CONSTRAINT ck_kredit�rt�k CHECK (kredit�rt�k>= 1 AND kredit�rt�k<=10)

END
go

-----------------------------------------------

-- �j f�l�v z�r�sa, ha van olyan, akkor eldobja �s megint megcsin�lja

IF object_id('felev_zaras','p') IS NOT NULL
	DROP PROCEDURE felev_zaras
GO

-- Ha a ki v�ltoz�ban 1-est kap, akkor lez�r mindenkit, k�l�nben a hallgat�t �s hallgat� 0-a
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
				SET @db= (SELECT COUNT(*) FROM hallgat�)
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

					IF @hallgato NOT IN(SELECT hk�d FROM hallgat� WHERE hk�d=@hallgato)
					BEGIN
						RAISERROR('Nincs ilyen hallgat�!',16,1)
						SET @ok=0;
					END
			--Hallgat� �s a szak szemeszter kiszed�se
					SET @hallgato_szem=0;
					SELECT @hallgato_szem=akt_szem, @szak=szak FROM hallgat� WHERE hk�d=@hallgato
					SELECT @szak_szem=szemeszter FROM szak WHERE szk�d=@szak
			-----------------------------
			-- Ha aktu�lis kissebb egyenl� mint a szakhoz tartoz�, kredit sz�m�t
					IF @ok = 1
					BEGIN
						IF @hallgato_szem<=@szak_szem
						BEGIN
							declare @hallgato_ketto INT
				--Kredit kisz�m�t�sa
							SET @kredit=
										(SELECT SUM(t.kredit�rt�k) FROM jelentkez�s AS j, vizsga AS v,
										tematika AS t WHERE j.jegy>1 AND j.szem=@hallgato_szem AND 
										j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)
				---------------------------
							SET @hallgato_ketto=@hallgato_szem+1;
							INSERT INTO f�l�vi_eredm�nyek VALUES(@hallgato,@hallgato_szem,@kredit)
							raiserror('A f�l�v z�r�s megt�rt�nt!',16,1)
							SET @ok=1;
							UPDATE hallgat� SET akt_szem=akt_szem+1 WHERE hk�d=@hallgato
						END
					END
			-------------------------------------
					SET @tol=@tol+1;
		END
GO

--DECLARE @rc INT;EXEC @rc=felev_zaras 0,1;SELECT @rc