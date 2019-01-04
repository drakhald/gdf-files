USE vizsga
GO
/*
ALTER TABLE hallgató ADD 
állapot VARCHAR(20)
*/
-- új vizsga eljárás, ha van olyan, akkor eldobja és megint megcsinálja

IF object_id('vegzett_nem','p') IS NOT NULL
	DROP PROCEDURE vegzett_nem
GO

CREATE PROCEDURE vegzett_nem(@hallgato INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	DECLARE @hallgato_szem INT
	DECLARE @szak_szem INT	

	SELECT @hallgato_szem=akt_szem FROM hallgató WHERE hkód=@hallgato
	SELECT @szak_szem=sz.szemeszter FROM hallgató AS h, szak AS sz WHERE h.hkód=@hallgato AND sz.szkód=h.szak
	
	IF @hallgato IN (SELECT hkód FROM hallgató WHERE állapot='végzett')
		BEGIN
			SET @ok=0;
			RAISERROR('Ez a hallgató már végzett!',16,1)
		END
	IF @ok=1
		BEGIN
			IF (@hallgato_szem>=@szak_szem)
				BEGIN
			--Teljesített minden tárgyat
					DECLARE @targy_osszesen INT
					DECLARE @hallgato_osszesen INT

					SET @hallgato_osszesen= (SELECT	COUNT(*) FROM jelentkezés AS j, vizsga AS v,
												tematika AS t WHERE j.jegy>1 AND 
												j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

					SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkezés AS j, vizsga AS v,
												tematika AS t WHERE j.hkód=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.tárgy=t.tárgy)

					IF @hallgato_osszesen=@targy_osszesen
						BEGIN
							UPDATE hallgató SET állapot='végzett' WHERE hkód=@hallgato
							RAISERROR('A hallgató végzetté nyílvánítása sikerült!',16,1)
						END
					ELSE
						BEGIN
							RAISERROR('A hallgató elérte a szemeszter értéket, de nem teljesített minden tárgyat!',16,1)
						END
				END
			ELSE
				BEGIN
					UPDATE hallgató SET akt_szem=akt_szem+1 WHERE hkód=@hallgato
					UPDATE hallgató SET állapot='aktív' WHERE hkód=@hallgato
					RAISERROR('A hallgató szemesztere eggyel nõtt!',16,1)
				END
		END
	-----------------------------------
GO
--DECLARE @rc INT;EXEC @rc=vegzett_nem 2;SELECT @rc