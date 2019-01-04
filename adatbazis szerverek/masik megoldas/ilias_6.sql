USE vizsga

-- hozzáadjuk a hallgató-hoz az állapot oszlopot ha még nincs
IF COL_LENGTH('hallgató', 'állapot') IS NULL
BEGIN
    ALTER TABLE hallgató
    ADD állapot CHAR(10) NOT NULL DEFAULT('aktív')
END
GO

-- kovetkezo_szemeszter eljárás

IF object_id('kovetkezo_szemeszter','p') IS NOT NULL
	DROP PROCEDURE kovetkezo_szemeszter
GO

CREATE PROCEDURE kovetkezo_szemeszter(@hkód INT) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;
	DECLARE @szemeszter INT
	DECLARE @maxszemeszter INT
	DECLARE @szak char(3)
	
	SELECT @szemeszter=hallgató.akt_szem,@maxszemeszter=szak.szemeszter,@szak=hallgató.szak FROM hallgató LEFT JOIN szak ON szak.szkód=hallgató.szak WHERE hallgató.hkód=@hkód
	IF @@ROWCOUNT = 0
	BEGIN
		raiserror('Érvénytelen hallgató!',16,1)
		SET @ok = 0;
	END

	IF @ok = 1
	BEGIN
	
		IF @szemeszter<@maxszemeszter
		BEGIN
			UPDATE hallgató SET akt_szem=akt_szem+1 WHERE hkód=@hkód
			PRINT ('A szemesztert a következőre állítottuk')
		END
		ELSE
		BEGIN
			SELECT 
			tematika.tárgy,(SELECT MAX(jelentkezés.jegy) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hkód AND vizsga.tárgy=tematika.tárgy) AS legjobbjegy
			INTO #tárgyak
			FROM tematika WHERE szak=@szak

			IF NOT EXISTS(SELECT tárgy FROM #tárgyak WHERE legjobbjegy IS NULL OR legjobbjegy <= 1)
			BEGIN
				UPDATE hallgató SET állapot = 'végzett' WHERE hkód=@hkód
				PRINT ('A hallgató állapota végzett lett')
			END
			ELSE
			BEGIN
				PRINT ('A hallgató nem minden tárgyal végzett')
			END
		END

	END

	RETURN @ok
END;
GO

-- tesztek
-- hiba, érvénytelen hallgató
EXEC kovetkezo_szemeszter @hkód=999

-- érvényes
EXEC kovetkezo_szemeszter @hkód=3

