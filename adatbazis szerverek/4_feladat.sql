
/*****************************************************************************************************
VIZSGAFELADATOK
*****************************************************************************************************/
/*
4. Bővítse az adatbázist úgy, hogy 
	- lehetőség legyen egy tematikához több előzményt definiálni.
	Megvalósítandó funkciók: 
		vizsgára jelentkezés teljes ellenőrzéssel.
*/

/*
	Jelenleg a TEMATIKA tábla szak, tárgy attribútuma PK és az előzmény attrímútumhoz tartozik egy FK, ami a tárgyhoz van hozzárendelve.
	Ahhoz, hogy több előzményt lehessen megadni, meg kell szűntetni a jelenlegi PK-t, FK-t és a három (szak, tárgy, előzményt) attribútumot
	kell egy PK-ba tenni.
*/


USE vizsga

GO

IF OBJECT_ID('FK_tematika_tematika', 'F') IS NOT NULL 
	ALTER TABLE tematika DROP CONSTRAINT FK_tematika_tematika
GO

IF OBJECT_ID('FK_vizsga_tematika', 'F') IS NOT NULL 
	ALTER TABLE vizsga DROP CONSTRAINT FK_vizsga_tematika
GO


IF OBJECT_ID('PK_tematika', 'PK') IS NOT NULL 
	ALTER TABLE tematika DROP CONSTRAINT PK_tematika
GO

/*
Ahhoz, hogy a három attribútumból lehessen PK biztosítani kell, hogy egyis se vehesse fel a NULL értéket.
Azaz létre kell hozni egy tárgyat, ami mindennek az előzménye, ez lesz AAA és a tanár valaki:
SELECT szkód FROM szemely s LEFT JOIN hallgato h ON s.szkód = h.hkód WHERE h.hkód IS NULL //402
*/

INSERT INTO tantárgy VALUES ('AAA','Mindennek az alapja', 402)

GO

UPDATE tematika SET előzmény='AAA' WHERE előzmény IS NULL

GO

ALTER TABLE tematika ALTER COLUMN előzmény CHAR(4) NOT NULL

GO

ALTER TABLE tematika ADD CONSTRAINT PK_tematika PRIMARY KEY CLUSTERED 
(
	szak ASC,
	tárgy ASC,
	előzmény ASC
)
GO

IF OBJECT_ID('új_vizsga', 'P') IS NOT NULL 
	DROP PROC új_vizsga

GO

CREATE PROCEDURE új_vizsga
	(
		@szak char(3),
		@tárgy char(4),
		@idő date,
		@tanár int,
		@max_fő smallint
		)
AS
	DECLARE @ok INT
	SET @ok=1
	
	IF @szak NOT IN (SELECT szkód FROM szak GROUP BY szkód)
		BEGIN
			SET @ok=0;
			RAISERROR('Nem létezik a megadott szak.',11,1)
		END	

			IF @tárgy NOT IN (SELECT tkód FROM tantárgy GROUP BY tkód)
		BEGIN
			SET @ok=0;
			RAISERROR('Nem létezik a megadott tantárgy.',11,1)
		END	
		
		IF @tárgy NOT IN (SELECT tárgy FROM tematika WHERE szak = @szak GROUP BY tárgy)
		BEGIN
			SET @ok=0;
			RAISERROR('Nem létezik a megadott tematika.',11,1)
		END	

		IF @idő<convert(SMALLDATETIME,getdate())
		BEGIN
			RAISERROR('Mai nap előtti időpontot nem lehet adni!',11,1)
			SET @ok=0;
		END

		
		IF (@tanár) IS NOT NULL
			BEGIN
				IF @tanár NOT IN (SELECT szkód FROM személy s LEFT JOIN hallgató h ON s.szkód = h.hkód WHERE h.hkód IS NULL )
				BEGIN
					RAISERROR('Nem létező tanár!',11,1)
					SET @ok=0;
				END
			END
		

		IF @ok=1
			BEGIN
				INSERT INTO vizsga VALUES (@szak, @tárgy, @idő, @tanár, @max_fő)
				RAISERROR('Sikeres vizsgajelentkezés!',1,1)
				
			END
GO

RAISERROR('Sikertelen próbálkozás:',1,1)
-- 
-- hibás dátum, a tanár foglalt, a terem nem gépes, a terem foglalt, a szakon nincs tárgy
EXEC új_vizsga @szak='TIM',@tárgy='ABSZ', @idő='2019-01-13 11:00:00',@tanár=6,@max_fő=1000;

RAISERROR('Sikeres próbálkozás:',1,1)
-- 
-- helyes vizsga
EXEC új_vizsga @szak='MIT',@tárgy='ABSZ', @idő='2019-01-13 11:00:00',@tanár=402,@max_fő=1000;
