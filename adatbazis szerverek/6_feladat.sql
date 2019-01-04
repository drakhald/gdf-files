USE vizsga
GO
/*
ALTER TABLE hallgat� ADD 
�llapot VARCHAR(20)
*/
-- �j vizsga elj�r�s, ha van olyan, akkor eldobja �s megint megcsin�lja

IF object_id('vegzett_nem','p') IS NOT NULL
	DROP PROCEDURE vegzett_nem
GO

CREATE PROCEDURE vegzett_nem(@hallgato INT) 
AS
	DECLARE @ok INT
	SET @ok=1;
	DECLARE @hallgato_szem INT
	DECLARE @szak_szem INT	

	SELECT @hallgato_szem=akt_szem FROM hallgat� WHERE hk�d=@hallgato
	SELECT @szak_szem=sz.szemeszter FROM hallgat� AS h, szak AS sz WHERE h.hk�d=@hallgato AND sz.szk�d=h.szak
	
	IF @hallgato IN (SELECT hk�d FROM hallgat� WHERE �llapot='v�gzett')
		BEGIN
			SET @ok=0;
			RAISERROR('Ez a hallgat� m�r v�gzett!',16,1)
		END
	IF @ok=1
		BEGIN
			IF (@hallgato_szem>=@szak_szem)
				BEGIN
			--Teljes�tett minden t�rgyat
					DECLARE @targy_osszesen INT
					DECLARE @hallgato_osszesen INT

					SET @hallgato_osszesen= (SELECT	COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
												tematika AS t WHERE j.jegy>1 AND 
												j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

					SET @targy_osszesen= (SELECT COUNT(*) FROM jelentkez�s AS j, vizsga AS v,
												tematika AS t WHERE j.hk�d=@hallgato AND v.vizsga=j.vizsga AND v.szak=t.szak AND v.t�rgy=t.t�rgy)

					IF @hallgato_osszesen=@targy_osszesen
						BEGIN
							UPDATE hallgat� SET �llapot='v�gzett' WHERE hk�d=@hallgato
							RAISERROR('A hallgat� v�gzett� ny�lv�n�t�sa siker�lt!',16,1)
						END
					ELSE
						BEGIN
							RAISERROR('A hallgat� el�rte a szemeszter �rt�ket, de nem teljes�tett minden t�rgyat!',16,1)
						END
				END
			ELSE
				BEGIN
					UPDATE hallgat� SET akt_szem=akt_szem+1 WHERE hk�d=@hallgato
					UPDATE hallgat� SET �llapot='akt�v' WHERE hk�d=@hallgato
					RAISERROR('A hallgat� szemesztere eggyel n�tt!',16,1)
				END
		END
	-----------------------------------
GO
--DECLARE @rc INT;EXEC @rc=vegzett_nem 2;SELECT @rc