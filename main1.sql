
USE KASETY_506_05
GO


-- view 1 --
IF EXISTS(SELECT 1 FROM sys.views WHERE NAME = 'WYPOZYCZENIA_NA_OSOBE')
    DROP VIEW WYPOZYCZENIA_NA_OSOBE;
GO

CREATE VIEW WYPOZYCZENIA_NA_OSOBE
AS
    select x.IDKLIENTA, x.NAZWISKO, x.IMIE, count(*) AS 'WYPOZYCZENIA'
    from Z506_05.KLIENCI as x
    join Z506_05.WYPO as y
    on x.IDKLIENTA = y.IDKLIENTA
    group by x.IDKLIENTA, x.NAZWISKO, x.IMIE
GO

-- view 2 --
IF EXISTS(SELECT 1 FROM sys.views WHERE NAME = 'REZYSERZY_NA_FILM')
    DROP VIEW REZYSERZY_NA_FILM;
GO

CREATE VIEW REZYSERZY_NA_FILM
AS
    select x.IDREZYSER, x.NAZWISKO, x.IMIE, count(*) AS 'FILMY_LACZNIE'
    from Z506_05.REZYSER as x
    join Z506_05.FILMY as y
    on x.IDREZYSER = y.IDREZYSER
    group by x.IDREZYSER, x.NAZWISKO, x.IMIE
GO


-- procedure 1 --
IF EXISTS(SELECT 1 FROM sys.procedures WHERE NAME = 'DODAJ_WYPOZYCZENIE')
    DROP PROC DODAJ_WYPOZYCZENIE
GO

CREATE PROC DODAJ_WYPOZYCZENIE 
(
    @IDKLIENTA int,
    @IDKASETY int,
    @DATAW smalldatetime,
    @DATAZ smalldatetime,
    @KWOTA decimal
) AS
BEGIN
    BEGIN TRY
        INSERT INTO
            WYPO
        VALUES
            (@IDKLIENTA, @IDKASETY, @DATAW, @DATAZ, @KWOTA);
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_LINE () AS ErrorLine,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO

-- dla testow
DELETE FROM WYPO WHERE IDKLIENTA = 2 AND IDKASETY = 107
EXEC DODAJ_WYPOZYCZENIE 2, 107, '2021-10-26', NULL, NULL

-- procedure 2 --
IF EXISTS(SELECT 1 FROM sys.procedures WHERE NAME = 'DODAJ_REZYSERA_Z_FILMEM')
    DROP PROC DODAJ_REZYSERA_Z_FILMEM
GO

CREATE PROC DODAJ_REZYSERA_Z_FILMEM
(
    @IDREZYSERA INT,
    @IDFILMU INT,
    @TYTUL CHAR(25),
    @CENA DECIMAL(6, 2),
    @KOLOR CHAR(1),
    @OPIS CHAR(40),
    @NAZWISKO CHAR(30),
    @IMIE CHAR(15)
) AS
BEGIN
    BEGIN TRY
        INSERT INTO 
            REZYSER (IDREZYSER, NAZWISKO, IMIE)
        VALUES
            (@IDREZYSERA, @NAZWISKO, @IMIE);
        INSERT INTO
            FILMY (IDFILMU, TYTUL, CENA, KOLOR, OPIS, IDREZYSER)
        VALUES
            (@IDFILMU, @TYTUL, @CENA, @KOLOR, @OPIS, @IDREZYSERA);
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_LINE () AS ErrorLine,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO

-- dla testow
DELETE FROM FILMY WHERE IDFILMU = 101
DELETE FROM REZYSER WHERE IDREZYSER = 25
EXEC DODAJ_REZYSERA_Z_FILMEM 25, 101, 'matrix', 14.00, 'c', 'lorem ipsum', 'mike', 'mock'

-- cursor 1 --
DECLARE @NAZWISKO CHAR(30)
DECLARE @IMIE CHAR(15)
DECLARE @WYPOZYCZENIA INT

DECLARE @LICZBA_KLIENTOW INT = (SELECT COUNT(*) FROM WYPOZYCZENIA_NA_OSOBE)
DECLARE @SUMA_KLIENTOW INT = (SELECT SUM(WYPOZYCZENIA) FROM WYPOZYCZENIA_NA_OSOBE)
DECLARE @MIN INT = (SELECT MIN(WYPOZYCZENIA) FROM WYPOZYCZENIA_NA_OSOBE)
DECLARE @MAX INT = (SELECT MAX(WYPOZYCZENIA) FROM WYPOZYCZENIA_NA_OSOBE)

DECLARE WYPOZYCZENIA_NA_OSOBE_CURSOR CURSOR FOR
SELECT NAZWISKO, IMIE, WYPOZYCZENIA FROM WYPOZYCZENIA_NA_OSOBE

OPEN WYPOZYCZENIA_NA_OSOBE_CURSOR

FETCH NEXT FROM 
    WYPOZYCZENIA_NA_OSOBE_CURSOR
INTO
    @NAZWISKO, @IMIE, @WYPOZYCZENIA

PRINT('')
PRINT('Lącznie w bazie jest: ' + CAST(@LICZBA_KLIENTOW AS NVARCHAR) + 'klientów')
PRINT('-----------------------------------------')

WHILE (@@FETCH_STATUS = 0)
BEGIN
    DECLARE @WTEXT VARCHAR(MAX) = @NAZWISKO + ', ' + @IMIE + ', ' + CAST(@WYPOZYCZENIA AS NVARCHAR)
    
    IF @WYPOZYCZENIA = @MIN
        SET @WTEXT = @WTEXT + ', najmniej'

    IF @WYPOZYCZENIA = @MAX
        SET @WTEXT = @WTEXT + ', najwiecej'

    PRINT(@WTEXT)

    FETCH NEXT FROM 
        WYPOZYCZENIA_NA_OSOBE_CURSOR 
    INTO
        @NAZWISKO, @IMIE, @WYPOZYCZENIA 
END

PRINT('')
PRINT('Łącznie jest: ' + CAST(@SUMA_KLIENTOW AS NVARCHAR) + 'wypożyczeń')
PRINT('')

CLOSE WYPOZYCZENIA_NA_OSOBE_CURSOR

DEALLOCATE WYPOZYCZENIA_NA_OSOBE_CURSOR

-- cursor 2 --
DECLARE @NAZWISKO_REZYSERA CHAR(30)
DECLARE @IMIE_REZYSERA CHAR(15)
DECLARE @FILMY_LACZNIE INT

DECLARE @LICZBA_REZYSEROW INT = (SELECT COUNT(*) FROM REZYSERZY_NA_FILM)
DECLARE @SUMA_REZYSEROW INT = (SELECT SUM(FILMY_LACZNIE) FROM REZYSERZY_NA_FILM)
DECLARE @MIN_FILMOW INT = (SELECT MIN(FILMY_LACZNIE) FROM REZYSERZY_NA_FILM)
DECLARE @MAX_FILMOW INT = (SELECT MAX(FILMY_LACZNIE) FROM REZYSERZY_NA_FILM)

DECLARE REZYSERZY_NA_FILM_CURSOR CURSOR FOR
SELECT NAZWISKO, IMIE, FILMY_LACZNIE FROM REZYSERZY_NA_FILM

OPEN REZYSERZY_NA_FILM_CURSOR

FETCH NEXT FROM 
    REZYSERZY_NA_FILM_CURSOR
INTO
    @NAZWISKO_REZYSERA, @IMIE_REZYSERA, @FILMY_LACZNIE

PRINT('Lącznie w bazie jest: ' + CAST(@LICZBA_REZYSEROW AS NVARCHAR) + 'reżyserów')
PRINT('-----------------------------------------')

WHILE (@@FETCH_STATUS = 0)
BEGIN
    DECLARE @RTEXT VARCHAR(MAX) = @NAZWISKO_REZYSERA + ', ' + ISNULL(NULLIF(@IMIE_REZYSERA, ''), 'brak imienia') + ', ' + CAST(@FILMY_LACZNIE AS NVARCHAR)
    
    IF @FILMY_LACZNIE = @MIN_FILMOW
        SET @RTEXT = @RTEXT + ', najmniej'

    IF @FILMY_LACZNIE = @MAX_FILMOW
        SET @RTEXT = @RTEXT + ', najwiecej'

    PRINT(@RTEXT)

    FETCH NEXT FROM 
        REZYSERZY_NA_FILM_CURSOR 
    INTO
        @NAZWISKO_REZYSERA, @IMIE_REZYSERA, @FILMY_LACZNIE 
END

PRINT('')
PRINT('Łącznie jest: ' + CAST(@SUMA_REZYSEROW AS NVARCHAR) + 'filmów')
PRINT('')

CLOSE REZYSERZY_NA_FILM_CURSOR

DEALLOCATE REZYSERZY_NA_FILM_CURSOR


-- temp table 1 --
CREATE TABLE #OSTATNIO_ZALOGOWANE_OSOBY
(
    ID INT PRIMARY KEY IDENTITY(1, 1),
    ID_OSOBY INT FOREIGN KEY REFERENCES OSOBY(ID),
    CZAS DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

IF OBJECT_ID('tempdb..#OSTATNIO_ZALOGOWANE_OSOBY') IS NOT NULL DROP TABLE #OSTATNIO_ZALOGOWANE_OSOBY
GO

CREATE TABLE #OSTATNIO_ZALOGOWANE_OSOBY
(
    ID INT PRIMARY KEY IDENTITY(1, 1),
    ID_OSOBY INT FOREIGN KEY REFERENCES OSOBY(ID),
    CZAS DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

-- test czy działa
INSERT INTO 
    #OSTATNIO_ZALOGOWANE_OSOBY (ID_OSOBY)
VALUES
    (1),
    (2);

SELECT * FROM #OSTATNIO_ZALOGOWANE_OSOBY

-- temp table 2 --
IF OBJECT_ID('tempdb..#OSTATNIO_ZALOGOWANI_KLIENCI') IS NOT NULL DROP TABLE #OSTATNIO_ZALOGOWANI_KLIENCI
GO

CREATE TABLE #OSTATNIO_ZALOGOWANI_KLIENCI
(
    ID INT PRIMARY KEY IDENTITY(1, 1),
    ID_KLIENTA INT FOREIGN KEY REFERENCES KLIENCI(IDKLIENTA),
    CZAS DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

-- test czy działa
INSERT INTO 
    #OSTATNIO_ZALOGOWANI_KLIENCI (ID_KLIENTA)
VALUES
    (1),
    (2),
    (3),
    (6),
    (8),
    (9);

SELECT * FROM #OSTATNIO_ZALOGOWANI_KLIENCI
