USE vizsga

-- tárgyfelvétel tábla létrehozása

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tárgyfelvétel' AND xtype='U')
BEGIN
	CREATE TABLE tárgyfelvétel
	(
		hkód INT NOT NULL,
		tárgy char(4) NOT NULL,
		szem TINYINT NOT NULL,
		CONSTRAINT [PK_tárgyfelvétel] PRIMARY KEY (hkód,tárgy,szem)
	)

END
GO

-- targyfelvetel eljárás

IF object_id('targyfelvetel','p') IS NOT NULL
	DROP PROCEDURE targyfelvetel
GO

CREATE PROCEDURE targyfelvetel
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;	
	
	INSERT INTO tárgyfelvétel SELECT hallgató.hkód,tematika.tárgy,hallgató.akt_szem FROM hallgató LEFT JOIN tematika ON tematika.szemeszter=hallgató.akt_szem AND tematika.szak = hallgató.szak WHERE tárgy IS NOT NULL EXCEPT SELECT hkód,tárgy,szem FROM tárgyfelvétel
	PRINT CONCAT(@@ROWCOUNT, ' tárgy felvéve')

	RETURN @ok
END;
GO

IF object_id('targyfelvetel_elmaradt','p') IS NOT NULL
	DROP PROCEDURE targyfelvetel_elmaradt
GO

CREATE PROCEDURE targyfelvetel_elmaradt(@hkód INT,@tárgy CHAR(3)) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;
	DECLARE @szemeszter INT
	DECLARE @szak char(3)
	
	SELECT @szemeszter=akt_szem,@szak=szak FROM hallgató WHERE hkód=@hkód
	IF @@ROWCOUNT = 0
	BEGIN
		raiserror('Érvénytelen hallgató!',16,1)
		SET @ok = 0;
	END

	-- korábbi tárgy amiből a legjobb vizsgajegy <=1
	IF EXISTS(SELECT * FROM (SELECT tematika.tárgy,(SELECT MAX(jelentkezés.jegy) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hkód AND jelentkezés.szem<@szemeszter AND vizsga.tárgy=tematika.tárgy) AS legjobbjegy FROM tematika WHERE szemeszter<@szemeszter AND szak=@szak AND tárgy=@tárgy) tárgyak WHERE tárgyak.legjobbjegy<=1 OR tárgyak.legjobbjegy IS NULL)
	BEGIN
		INSERT INTO tárgyfelvétel SELECT @hkód,@tárgy,@szemeszter
		IF @@ERROR = 0
		BEGIN
			PRINT CONCAT(@tárgy, ' korábbi szemeszteres tárgy felvéve')
		END
		ELSE
		BEGIN
			raiserror('A tárgy már korábban fel lett véve!',16,1)
			SET @ok = 0;
		END
	END
	ELSE
	BEGIN
		raiserror('Érvénytelen tárgy!',16,1)
		SET @ok = 0;
	END

	RETURN @ok
END;
GO

-- teszt
-- hibás, érvénytelen hallgató
EXEC targyfelvetel_elmaradt @hkód=999, @tárgy='ABSZ'
-- hibás, érvénytelen tárgy
EXEC targyfelvetel_elmaradt @hkód=999, @tárgy='1234'
-- érvényes
EXEC targyfelvetel_elmaradt @hkód=3, @tárgy='PRI'
EXEC targyfelvetel