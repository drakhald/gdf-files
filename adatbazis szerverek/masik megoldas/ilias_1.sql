USE vizsga

-- terem tábla létrehozása

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='terem' AND xtype='U')
BEGIN
	CREATE TABLE terem
	(
		tkód int NOT NULL,
		kapacitás int NOT NULL,
		gépek_száma int NOT NULL,
		CONSTRAINT PK_terem PRIMARY KEY (tkód)
	)
	-- vizsga tábla kibővítése
	ALTER TABLE vizsga
	ADD terem int NULL,
		gépes tinyint NOT NULL DEFAULT '0',
		időtartam time NOT NULL DEFAULT '00:00'

	ALTER TABLE vizsga WITH NOCHECK
	ADD CONSTRAINT FK_vizsga_terem FOREIGN KEY (terem) REFERENCES terem(tkód)

END
GO

-- új vizsga eljárás

IF object_id('uj_vizsga','p') IS NOT NULL
	DROP PROCEDURE uj_vizsga
GO

CREATE PROCEDURE uj_vizsga(@szak CHAR(3),@tárgy CHAR(4),@idő SMALLDATETIME,@tanár INT,
						   @max_fő SMALLINT,@terem INT,@időtartam TIME,@gépes TINYINT) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;

	IF @idő<convert(SMALLDATETIME,getdate())
	BEGIN
		RAISERROR('Már elmúlt dátum nem megadható!',16,1)
		SET @ok=0;
	END

	IF @terem NOT IN (SELECT tkód FROM terem)
	BEGIN
		RAISERROR('A terem nem található!',16,1)
		SET @ok=0;
	END

	IF @időtartam<'00:15'
	BEGIN
		RAISERROR('Az vizsga hossza legalább 15 percnek kell lennie!',16,1)
		SET @ok=0;
	END

	IF @tárgy NOT IN (SELECT tkód FROM tantárgy)
	BEGIN
		RAISERROR('Tárgy nem található!',16,1)
		SET @ok=0;
	END

	IF @szak NOT IN (SELECT szkód FROM szak)
	BEGIN
		RAISERROR('Szak nem található!',16,1)
		SET @ok=0;
	END

	IF @tanár NOT IN (SELECT szkód FROM személy WHERE szkód NOT IN(SELECT hkód FROM hallgató))
	BEGIN
		RAISERROR('A tanár nem található!',16,1)
		SET @ok=0;
	END

	IF (@gépes=1)
		IF @terem NOT IN (SELECT tkód FROM terem WHERE gépek_száma>0)
		BEGIN
			RAISERROR('A terem nem gépes!',16,1)
			SET @ok=0;
		END

	IF @terem IN (SELECT terem FROM vizsga WHERE
		(
			(@idő BETWEEN idő AND időtartam+idő) OR (@idő+@időtartam BETWEEN idő AND időtartam+idő) OR
			(idő BETWEEN @idő AND @időtartam+@idő) OR (idő+időtartam BETWEEN @idő AND @időtartam+@idő)
		) AND terem=@terem)
	BEGIN
		RAISERROR('Már van vizsga a teremben!',16,1)
		SET @ok=0;
	END
	
			
	IF @tanár IN (SELECT tanár FROM vizsga WHERE
		(
			(@idő BETWEEN idő AND időtartam+idő) OR (@idő+@időtartam BETWEEN idő AND időtartam+idő) OR
			(idő BETWEEN @idő AND @időtartam+@idő) OR (idő+időtartam BETWEEN @idő AND @időtartam+@idő)
		) AND tanár=@tanár)
	BEGIN
		RAISERROR('A tanár vizsgáztat ebben az időben!',16,1)
		SET @ok=0;
	END

			
	IF @szak NOT IN(SELECT szak FROM tematika WHERE szak=@szak AND tárgy=@tárgy)
	BEGIN
		RAISERROR('Ezen a szakon nincs ilyen tárgy!',16,1)
		SET @ok=0;
	END

	declare @kapacitás INT 
		SELECT @kapacitás=kapacitás FROM terem WHERE tkód=@terem

	IF @max_fő>@kapacitás
	BEGIN
		RAISERROR('Ekkora létszám nem fér a terembe!',16,1) 
		SET @ok=0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO vizsga VALUES(@szak,@tárgy,@idő,@tanár,@max_fő,@terem,@gépes,@időtartam)
		SET @ok=1;
	END
	
	RETURN @ok
END;
GO
----------------------------------------------

-- termek
INSERT INTO terem VALUES (1,50,0)
INSERT INTO terem VALUES (2,20,20)
INSERT INTO terem VALUES (3,20,20)

UPDATE vizsga SET terem = 1, időtartam = '01:00';

-- teszt
-- hibás dátum, a tanár foglalt, a terem nem gépes, a terem foglalt, a szakon nincs tárgy
EXEC uj_vizsga @szak='IKT',@tárgy='ABSZ',@idő='2008-12-13 11:00:00',@tanár=403,@max_fő=60,@terem=1,@időtartam='01:00',@gépes=1;
-- helyes vizsga
EXEC uj_vizsga @szak='MIT',@tárgy='ABSZ',@idő='2019-01-13 11:00:00',@tanár=403,@max_fő=20,@terem=2,@időtartam='01:00',@gépes=1;