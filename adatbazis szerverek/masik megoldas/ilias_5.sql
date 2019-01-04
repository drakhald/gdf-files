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

CREATE PROCEDURE targyfelvetel(@hkód INT) 
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

	IF @ok = 1
	BEGIN
		INSERT INTO tárgyfelvétel SELECT @hkód,tárgy,szemeszter FROM tematika WHERE szemeszter=@szemeszter AND szak=@szak
		PRINT CONCAT(@@ROWCOUNT, ' tárgy felvéve')
	END

	RETURN @ok
END;
GO

IF object_id('targyfelvetel_elmaradtak','p') IS NOT NULL
	DROP PROCEDURE targyfelvetel_elmaradtak
GO

CREATE PROCEDURE targyfelvetel_elmaradtak(@hkód INT) 
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

	-- korábbi tárgyak amiből a legjobb vizsgajegy <=1
	SELECT 
	tematika.tárgy,(SELECT MAX(jelentkezés.jegy) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hkód AND jelentkezés.szem<@szemeszter AND vizsga.tárgy=tematika.tárgy) AS legjobbjegy
	INTO #tárgyak
	FROM tematika WHERE szemeszter<@szemeszter AND szak=@szak
	
	IF @ok = 1
	BEGIN
		INSERT INTO tárgyfelvétel SELECT @hkód,tárgy,@szemeszter FROM #tárgyak WHERE legjobbjegy IS NULL OR legjobbjegy <= 1
		PRINT CONCAT(@@ROWCOUNT, ' korábbi szemeszteres tárgy felvéve')
	END

	RETURN @ok
END;
GO

-- teszt
UPDATE hallgató SET akt_szem=3 WHERE hkód=3
-- hibás, érvénytelen hallgató
EXEC targyfelvetel @hkód=999
EXEC targyfelvetel_elmaradtak @hkód=999
-- érvényes
EXEC targyfelvetel @hkód=3
EXEC targyfelvetel_elmaradtak @hkód=3
