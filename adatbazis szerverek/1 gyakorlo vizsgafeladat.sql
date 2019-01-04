--Galambos Máté
--1. Feladat
--Bővítse az adatbázist a vizsgáztatás helyeinek (terem) nyilvántartásával.
--A terem jellemzői: befogadó képesség (fő), gépek száma (db).
--A vizsga új tulajdonságai: terem, gépes-e, időtartam.
--Megvalósítandó funkció a vizsga meghirdetése (új vizsga) teljes ellenőrzéssel.

USE vizsga_feladat_1
GO

--termek tábla létrehozása
CREATE TABLE termek
(
	teremID char(10), --terem azonosítókódja
	fő tinyint NOT NULL, --hány fő fér be
	gépek tinyint NOT NULL  --hány gép van a teremben
		CONSTRAINT DF_gépek DEFAULT 0, --alapértelmezett érték legyen 0

	CONSTRAINT PK_termek PRIMARY KEY (teremID), --elsődleges kulcs
	CONSTRAINT CK_gépek_fő CHECK (gépek<=fő) --ne legyen több gép a teremben, mint ahány ember befér (mert akkor az raktár nem tanterem)
)
GO
--teszt
/*
SELECT *
FROM termek
GO

INSERT INTO termek -- jó értékek
VALUES	('GD', 50,0),
		('1', 25, 20),
		('2',25,25)
GO
INSERT INTO termek (teremID, fő, gépek) --jó határérték teszt
VALUES	('0', 255, 255)
GO
INSERT INTO termek (teremID, fő, gépek) --rossz határérték teszt (túl nagy fő és gép)
VALUES	('0', 256, 256)
GO
INSERT INTO termek (teremID, fő) --default teszt
VALUES	('3', 25)
GO
INSERT INTO termek (teremID, fő, gépek) --rossz érték teszt (több gép, mint fő)
VALUES	('3', 25, 50)
GO
*/

GO

--vizsga bővítése
ALTER TABLE vizsga
ADD	teremID char(10) NOT NULL --hol lesz a vizsga
		 CONSTRAINT DF_teremID DEFAULT '0', --alapértelmezett: 0-ás terem (255 fő, 255 gép)
	gépes_e char NOT NULL --kell-e gép a vizsgához
		 CONSTRAINT DF_gépes_e DEFAULT 'N', --alapértelmezett: nem kell gép
	hány_perc int NOT NULL --vizsga hossza percekben
		 CONSTRAINT DF_hány_perc DEFAULT 3*60, --alapértelmezett: 3 óra

	CONSTRAINT FK_vizsga_termek FOREIGN KEY (teremID) REFERENCES termek(teremID) --külső kulcs
GO
--teszt
/*
SELECT *
FROM vizsga
SELECT *
FROM termek
SELECT *
FROM tematika
*/
--külső kulcs tesztelése:
/*
--jó külső kulcs
INSERT INTO vizsga(szak,tárgy,idő,tanár,max_fő,teremID,gépes_e,hány_perc)
VALUES	('MIN','PRI','2018-12-12 12:00', 405, 500, 'GD', 'I', 4*60)
GO
--rossz küső kulcs
INSERT INTO vizsga(szak,tárgy,idő,tanár,max_fő,teremID,gépes_e,hány_perc)
VALUES	('MIN','PRI','2018-12-12 12:00', 405, 500, 'KKK', 'I', 4*60)
GO
*/

GO

DROP FUNCTION fnÜtközik
GO
--egy új vizsga melyik régi vizsgákkal ütközik <here be dragons>
CREATE FUNCTION fnÜtközik(@teremID char(10), @idő smalldatetime, @hány_perc int)
RETURNS @ütköző_vizsgák table
	(vizsga int NOT NULL)
AS
BEGIN
	INSERT INTO @ütköző_vizsgák
	SELECT vizsga
	FROM vizsga
	WHERE teremID=@teremID --ha a két terem megegyezik
				AND -- ÉS
			--a felitt *ÚJ* vizsga átfedésben van egy másik *RÉGI*vel:
			(--az *ÚJ* vége belelóg egy *RÉGI* elejébe, vagyis:
				(idő<DATEADD(mi,@hány_perc,@idő) --az *ÚJ* vége nagyobb, mint egy *RÉGI* eleje
				AND --és a *RÉGI* nem egy jóval korábbi vizsga, vagyis:
				@idő<DATEADD(mi,hány_perc,idő) --az *ÚJ* eleje kisebb, mint egy *RÉGI* vége
				)
			OR --vagy
			--az *ÚJ* eleje belelóg egy *RÉGI* végébe, vagyis:
				(@idő<DATEADD(mi,hány_perc,idő) --az *ÚJ* eleje kisebb, mint egy *RÉGI* vége
				AND --és a *RÉGI* nem jóval későbbi vizsga, vagyis:
				idő<DATEADD(mi,@hány_perc,@idő) --a *RÉGI* eleje kisebb mint az *ÚJ* vége
				)
			)
	RETURN
END
GO --<\dragons>
GO
--teszt
/*
SELECT *
FROM vizsga

--fnÜtközik(@teremID char(10), @idő smalldatetime, @hány_perc int)
SELECT *
FROM dbo.fnÜtközik('GD', '2018-12-12 8:00', 1*60) --nincs ütközés
SELECT *
FROM dbo.fnÜtközik('GD', '2018-12-12 10:00', 3*60) --egy ütközés
SELECT *
FROM dbo.fnÜtközik('GD', '2018-12-12 14:00', 60) --egy ütközés
SELECT *
FROM dbo.fnÜtközik('0', '2009-09-01 14:00', 3*60) --két ütközés
GO
*/
/*
--négy ütköző vizsga kódjának összefűzött felsorolása:
DECLARE @összes_ütközés nvarchar(100)='Ütközés a következő vizsgákkal: '
SELECT @összes_ütközés=CONCAT(@összes_ütközés, vizsga, ', ')
FROM dbo.fnÜtközik('0', '2009-09-01 14:00', 60*24*60)
PRINT @összes_ütközés
GO
*/
GO

--új vizsga felvitele
CREATE PROC spÚjVizsga
@szak char(3),
@tárgy char(4),
@idő smalldatetime,
@tanár int,
@max_fő smallint,
@teremID char(10),
@gépes_e char,
@hány_perc int
AS
BEGIN
	DECLARE @jó_e char='I' --ha ez I marad, felviszem az adatokat
	--tesztek:
	--szak+tárgy kombináció létezik-e a tematikában
	IF(NOT EXISTS	(SELECT *
					FROM tematika
					WHERE szak=@szak AND tárgy=@tárgy)) --ha NINCS ilyen szak+tárgy
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A szak+tárgy kombináció nem létezik a tematikában',11,1)
		END
	--múltbeli időre ne lehessen vizsgát kiírni
	IF(@idő<=SYSDATETIME()) --ha a vizsga ideje kisebb vagy egyenlő a mosani idővel
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('Csak jövőbeli időpontra lehet vizsgát kiírni',11,1)
		END
	--két vizsga ne ütközzön
	IF				(EXISTS
						(
						SELECT *
						FROM dbo.fnÜtközik(@teremID, @idő, @hány_perc)
						)
					)--ha van ütközés (lásd dbo.fnÜtközik függvényt, ami kilistázza az ütközéseket)
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		--az ütköző vizsgák szöveggé alakítása: 
			DECLARE @összes_ütközés nvarchar(100)='Ütközés a következő vizsgákkal: '
			SELECT @összes_ütközés=CONCAT(@összes_ütközés, vizsga, ', ')
			FROM dbo.fnÜtközik(@teremID, @idő, @hány_perc)
		--hibaüzenet a szövegesen kigyűjtött ütközések alapján
		RAISERROR(@összes_ütközés,11,1)
		END
	
	--a tanárnak léteznie kell
	IF			(@tanár IS NOT NULL --a tanár ki van töltve
				AND --és
				NOT EXISTS --nincs benne a személyek táblában
				(SELECT *
				FROM személy
				WHERE szkód=@tanár)
				) --ha nem létező tanár
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A tanár kódja nem szerepel a személyek között',11,1)
		END
	--létező teremben vizsgázzunk
	IF			(NOT EXISTS --a terem nem létezik
				(SELECT *
				FROM termek
				WHERE teremID=@teremID)
				) --ha a terem nem létezik
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A megadott terem azonosítója nem található a termek között',11,1)
		END
	--a vizsgázók férjenek be a terembe
	IF			(@max_fő>	(SELECT fő
							FROM termek
							WHERE teremID=@teremID)
				) --ha a vizsgára többen jelentkezhetnek, mint a terem befogadóképessége
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A maximális létszám nagyobb, mint a terem befogadóképessége',11,1)
		END
	--a gépes_e értéke csak I vagy N lehessen
	IF(@gépes_e!='I' AND @gépes_e!='N') --ha nam I vagy N
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A gépes_e változó lehetséges értékei: I vagy N',11,1)
		END
	--ha a vizsga gépes, legyen elég gép a vizsgához
	IF			(@gépes_e='I' --a vizsga gépes
				AND --és
				@max_fő>	(SELECT gépek
							FROM termek
							WHERE teremID=@teremID)
				) --ha a vizsga gépes és nincs elég gép
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A megadott teremben lévő gépek száma kisebb, mint a megadott maximális létszám',11,1)
		END
	--a vizsga hossza legyen nagyobb, mint 0 perc de kisebb, mint 12 óra
	IF(@hány_perc<0 OR 12*60<@hány_perc) --ha kisebb, mint 0 vagy nagyobb, mint fél nap
		BEGIN --hibaüzenetet adok
		SET @jó_e='N'
		RAISERROR('A vizsga hossza 0 perc és 720 perc közé kell, hogy essen',11,1)
		END

	IF(@jó_e='I')--ha minden jó
		--felviszem az új vizsgát
		INSERT INTO vizsga(szak,tárgy,idő,tanár,max_fő,teremID,gépes_e,hány_perc)
		VALUES (@szak,@tárgy,@idő,@tanár,@max_fő,@teremID,@gépes_e,@hány_perc)
	ELSE
		RAISERROR('-----------A vizsgaadatok felvitele sikertelen-----------',11,1)
END
GO
--teszt
/*
SELECT *
FROM vizsga
GO
EXEC spÚjVizsga --jó adatokkal
	'MIN',
	'PRI',
	'2019-01-01 12:00',
	405,
	30,
	'0',
	'N',
	120
GO
EXEC spÚjVizsga --rossz tárgy
	'AAA',
	'PRI',
	'2019-01-02 12:00',
	405,
	30,
	'0',
	'N',
	120
GO
EXEC spÚjVizsga --múltbeli vizsga
	'MIN',
	'PRI',
	'2018-01-03 12:00',
	405,
	30,
	'0',
	'N',
	120
GO
EXEC spÚjVizsga --jó adatokkal
	'MIN',
	'PRI',
	'2019-01-01 14:00',
	405,
	30,
	'0',
	'N',
	120
GO
EXEC spÚjVizsga --ütközés
	'MIN',
	'PRI',
	'2019-01-01 12:00',
	405,
	30,
	'0',
	'N',
	180
GO
EXEC spÚjVizsga --rossz tanár
	'MIN',
	'PRI',
	'2019-01-03 12:00',
	666,
	30,
	'0',
	'N',
	120
GO
SELECT *
FROM termek
GO
EXEC spÚjVizsga --kevés hely
	'MIN',
	'PRI',
	'2019-01-01 12:00',
	405,
	30,
	'1',
	'N',
	180
GO
EXEC spÚjVizsga --kevés gép
	'MIN',
	'PRI',
	'2019-01-03 12:00',
	405,
	22,
	'1',
	'I',
	120
GO
EXEC spÚjVizsga --rossz gépes_e érték 
	'MIN',
	'PRI',
	'2019-01-03 12:00',
	405,
	30,
	'0',
	'j',
	120
GO
EXEC spÚjVizsga --negatív viszgahossz
	'MIN',
	'PRI',
	'2019-01-03 12:00',
	405,
	30,
	'0',
	'N',
	-120
GO
EXEC spÚjVizsga --túl hosszú vizsga
	'MIN',
	'PRI',
	'2019-01-03 12:00',
	405,
	30,
	'0',
	'N',
	12000
GO
*/