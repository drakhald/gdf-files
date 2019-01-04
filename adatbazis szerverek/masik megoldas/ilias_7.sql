USE vizsga

-- Ha nem létezik a félévi_eredmények tábla, akkor létrehozza és feltölti azt, tematikához tesz egy oszlopot

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='félévi_eredmények' AND xtype='U')
BEGIN
	CREATE TABLE félévi_eredmények(hallgató INT NOT NULL,szemeszter INT NOT NULL, összkredit INT, PRIMARY KEY(hallgató,szemeszter))

	ALTER TABLE tematika ADD kredit_érték INT,
	CONSTRAINT CK_kreditérték CHECK (kredit_érték>= 1 AND kredit_érték<=10)

END
GO

-- felevzaras

IF object_id('felevzaras','p') IS NOT NULL
	DROP PROCEDURE felevzaras
GO

CREATE PROCEDURE felevzaras(@hkód INT) 
AS
BEGIN
	DECLARE @db INT
	DECLARE @hallgató INT
	DECLARE @szemeszter INT
	DECLARE @maxszemeszter INT
	DECLARE @szak char(3)
	SET @db = 0

	DECLARE hallgatók CURSOR FOR SELECT hallgató.hkód,hallgató.akt_szem,szak.szemeszter AS maxszemeszter,hallgató.szak FROM hallgató LEFT JOIN szak ON szak.szkód=hallgató.szak WHERE (hallgató.hkód=@hkód OR @hkód=0)
	
	OPEN hallgatók
	FETCH FROM hallgatók INTO @hallgató,@szemeszter,@maxszemeszter,@szak
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 
		tematika.tárgy,tematika.kredit_érték,(SELECT MAX(jelentkezés.jegy) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hallgató AND jelentkezés.szem=@szemeszter AND vizsga.tárgy=tematika.tárgy) AS legjobbjegy
		INTO #tárgyak
		FROM tematika WHERE szemeszter=@szemeszter AND szak=@szak

		IF @szemeszter<@maxszemeszter
		BEGIN

			INSERT INTO félévi_eredmények SELECT @hallgató,@szemeszter,SUM(kredit_érték) FROM #tárgyak WHERE legjobbjegy>1
			IF @@ERROR = 0
			BEGIN
				UPDATE hallgató SET akt_szem=akt_szem+1 WHERE hkód=@hallgató
				PRINT CONCAT('A félév lezárva: ', @hallgató)
				SET @db=@db+1
			END
			ELSE
			BEGIN
				raiserror('A félévi eredmény ehhez a hallgatóhoz már létezik!',16,1)
			END

		END

		IF OBJECT_ID('tempdb..#tárgyak') IS NOT NULL
			DROP TABLE #tárgyak

		FETCH FROM hallgatók INTO @hallgató,@szemeszter,@maxszemeszter,@szak
	END
	CLOSE hallgatók
	DEALLOCATE hallgatók

	PRINT CONCAT('A félév lezárva ', @db ,' hallgatónál')

	RETURN @db
END;
GO

EXEC felevzaras @hkód=0;