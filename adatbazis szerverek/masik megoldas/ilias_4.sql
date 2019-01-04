USE vizsga

-- tematika-előzmény tábla létrehozása

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tematika-előzmény' AND xtype='U')
BEGIN
	CREATE TABLE [tematika-előzmény]
	(
		szak char(3) NOT NULL,
		tárgy char(4) NOT NULL,
		előzmény char(4) NOT NULL,
		CONSTRAINT [PK_tematika-előzmény] PRIMARY KEY (szak,tárgy,előzmény)
	)

	CREATE INDEX IX_tematika ON dbo.[tematika-előzmény] (szak, tárgy)
	CREATE INDEX [IX_tematika-előzmény] ON dbo.[tematika-előzmény] (szak,előzmény)

	ALTER TABLE [tematika-előzmény] ADD CONSTRAINT [FK_tematika-előzmény_tematika] FOREIGN KEY (szak,előzmény) REFERENCES dbo.tematika (szak,tárgy)
	ALTER TABLE [tematika-előzmény] ADD CONSTRAINT [FK_tematika_előzmény-tematika] FOREIGN KEY (szak,tárgy) REFERENCES dbo.tematika (szak,tárgy)
	
	EXEC ('INSERT INTO [tematika-előzmény] SELECT szak, tárgy, előzmény FROM tematika WHERE előzmény IS NOT NULL');
	
	ALTER TABLE [tematika] DROP CONSTRAINT [FK_tematika_tematika]
	ALTER TABLE [tematika] DROP COLUMN előzmény 
END
GO

-- vizsga_jelentkezes eljárás

IF object_id('vizsga_jelentkezes','p') IS NOT NULL
	DROP PROCEDURE vizsga_jelentkezes
GO

CREATE PROCEDURE vizsga_jelentkezes(@hkód INT,@vizsga INT) 
AS
BEGIN
	DECLARE @ok INT
	SET @ok=1;
	
	DECLARE @szak char(4);
	DECLARE @tárgy char(4);
	DECLARE @max_fő INT;
	DECLARE @szemeszter INT;

	SELECT @szak=tematika.szak,@tárgy=tematika.tárgy,@max_fő=vizsga.max_fő FROM vizsga LEFT JOIN tematika ON tematika.szak = vizsga.szak AND tematika.tárgy=vizsga.tárgy WHERE vizsga.vizsga=@vizsga
	IF @@ROWCOUNT = 0
	BEGIN
		raiserror('Ismeretlen vizsga!',16,1)
		SET @ok = 0;
	END
	
	SELECT @szemeszter=akt_szem FROM hallgató WHERE hkód=@hkód
	IF @@ROWCOUNT = 0
	BEGIN
		raiserror('Ismeretlen hallgató!',16,1)
		SET @ok = 0;
	END

	IF EXISTS(
		SELECT előzmény FROM [tematika-előzmény] WHERE szak=@szak AND tárgy=@tárgy AND előzmény NOT IN (
			SELECT vizsga.tárgy FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hkód AND jelentkezés.jegy>1 AND vizsga.szak=[tematika-előzmény].szak
		)
	)
	BEGIN
		raiserror('Nincs minden követelmény teljesítve!',16,1)
		SET @ok = 0;
	END

	IF EXISTS(SELECT jelentkezés.vizsga FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE jelentkezés.hkód=@hkód AND (jelentkezés.jegy IS NULL OR jelentkezés.jegy=0) AND vizsga.szak=@szak AND vizsga.tárgy=@tárgy)
	BEGIN
		raiserror('Már jelentkezett a tárgy egy másik vizsgájára!',16,1)
		SET @ok = 0;
	END

	DECLARE @jelentkezett INT;
	SELECT @jelentkezett = COUNT(jelentkezés.vizsga) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE vizsga.szak=@szak AND vizsga.tárgy=@tárgy AND jelentkezés.szem=@szemeszter
	IF @jelentkezett >= 3
	BEGIN
		raiserror('Az aktuális szemeszterben már legalább 3 alkalommal jelentkezett ennek a tárgynak a vizsgájára!',16,1)
		SET @ok = 0;
	END

	SELECT @jelentkezett = COUNT(jelentkezés.vizsga) FROM jelentkezés LEFT JOIN vizsga ON vizsga.vizsga = jelentkezés.vizsga WHERE vizsga.szak=@szak AND vizsga.tárgy=@tárgy
	IF @jelentkezett >= 6
	BEGIN
		raiserror('Már legalább 6 alkalommal jelentkezett ennek a tárgynak a vizsgájára!',16,1)
		SET @ok = 0;
	END

	SELECT @jelentkezett = COUNT(jelentkezés.hkód) FROM jelentkezés WHERE vizsga=@vizsga
	IF @jelentkezett >= @max_fő
	BEGIN
		raiserror('Az adott vizsgára már nincs hely!',16,1)
		SET @ok = 0;
	END

	IF @hkód NOT IN (SELECT hkód FROM hallgató WHERE szak=@szak)
	BEGIN
		raiserror('Az adott szakon nincs ilyen hallgató!',16,1)
		SET @ok = 0;
	END

	IF NOT EXISTS(SELECT vizsga FROM vizsga WHERE vizsga=@vizsga AND idő>getdate())
	BEGIN
		raiserror('Csak jövőbeni vizsgára lehet jelentkezni!',16,1)
		SET @ok = 0;
	END

	IF @ok = 1
	BEGIN
		INSERT INTO jelentkezés VALUES (@hkód,@vizsga,@szemeszter,NULL)
		raiserror('A jelentkezés rögzítve',16,1)
		SET @ok=1;
	END

END;
GO

INSERT INTO vizsga VALUES ('MIT','ABK','2019-02-01 10:00:00',403,10);
INSERT INTO vizsga VALUES ('MIT','PROB','2019-01-18 10:00:00',403,10);
INSERT INTO jelentkezés VALUES (397,8,7,2);
UPDATE vizsga SET max_fő = 5 WHERE vizsga = 5;
-- tesztek
-- hibás: a hallgató nem az adott szkra jár, a vizsga már elmúlt, nincs minden követelmény teljesítve, már legalább 6 vizsgajelentkezése volt, nincs hely
EXEC vizsga_jelentkezes @hkód=399,@vizsga=5;
-- hibás: nincs minden előzmény teljesítve
EXEC vizsga_jelentkezes @hkód=399,@vizsga=6;

-- jó vizsga
EXEC vizsga_jelentkezes @hkód=397,@vizsga=7;