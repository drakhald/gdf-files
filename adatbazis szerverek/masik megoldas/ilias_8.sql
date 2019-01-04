USE vizsga

-- Ha nem létezik a hallgató_archív tábla, akkor lemásoljuk a hallgató táblát, és a jelentkezés táblát is az arhívnak

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='hallgató_archív' AND xtype='U')
BEGIN
	SELECT * INTO hallgató_archív FROM hallgató WHERE 0=1
	SELECT * INTO jelentkezés_archív FROM jelentkezés WHERE 0=1
END
GO

-- felevzaras

IF object_id('arhivalas','p') IS NOT NULL
	DROP PROCEDURE arhivalas
GO

CREATE PROCEDURE arhivalas 
AS
BEGIN
	DECLARE @db INT
	DECLARE @hallgató INT
	DECLARE @szak char(3)
	SET @db = 0

	DECLARE hallgatók CURSOR FOR SELECT hallgató.hkód,hallgató.szak FROM hallgató LEFT JOIN szak ON szak.szkód=hallgató.szak WHERE hallgató.akt_szem=szak.szemeszter
	
	OPEN hallgatók
	FETCH FROM hallgatók INTO @hallgató,@szak
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 
		tematika.tárgy,(SELECT MAX(jelentkezés.jegy) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hallgató AND vizsga.tárgy=tematika.tárgy) AS legjobbjegy
		INTO #tárgyak
		FROM tematika WHERE szak=@szak

		IF NOT EXISTS(SELECT tárgy FROM #tárgyak WHERE legjobbjegy IS NULL OR legjobbjegy<=1)
		BEGIN

			BEGIN TRY
				BEGIN TRANSACTION
					SELECT * INTO hallgató_archív FROM hallgató WHERE hkód=@hallgató
					SELECT * INTO jelentkezés_archív FROM jelentkezés WHERE hkód=@hallgató
					DELETE FROM jelentkezés WHERE hkód=@hallgató
					DELETE FROM hallgató WHERE hkód=@hallgató
				COMMIT TRANSACTION;
				SET @db = @db + 1
			END TRY
			BEGIN CATCH
    			IF @@TRANCOUNT > 0
        			ROLLBACK TRAN

			    RAISERROR('A hallgatót nem lehet arhiválni', 16, 1)
			END CATCH
		END

		IF OBJECT_ID('tempdb..#tárgyak') IS NOT NULL
			DROP TABLE #tárgyak

		FETCH FROM hallgatók INTO @hallgató,@szak
	END
	CLOSE hallgatók
	DEALLOCATE hallgatók

	PRINT CONCAT(@db ,' hallgató arhiválva')

	RETURN @db
END;
GO

EXEC arhivalas;