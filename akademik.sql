-- Tworzenie typu obiektowego dla tabeli Pokój
CREATE TYPE Pokoj AS OBJECT (
    numer_pokoju NUMBER,
    liczba_miejsc NUMBER,
    cena_pokoju NUMBER,
    czy_czysty BOOLEAN,
    numer_pietra_ref REF Pietro
);
-- do stworzenia

-- Tworzenie tabeli Pokój z kolumn¹ typu obiektowego
CREATE TABLE TabelaPokoje OF Pokoj (
    numer_pokoju PRIMARY KEY
);

-- Tworzenie typu obiektowego dla tabeli Piêtro
CREATE TYPE Pietro AS OBJECT (
    numer_pietra NUMBER,
    liczba_pokoi NUMBER
);

-- Tworzenie tabeli Piêtro z kolumn¹ typu obiektowego
CREATE TABLE TabelaPietra OF Pietro (
    numer_pietra PRIMARY KEY
);

-- Tworzenie typu obiektowego dla tabeli Akademik
CREATE TYPE Akademik AS OBJECT (
    nazwa_akademika VARCHAR2(50),
    lokalizacja VARCHAR2(100)
);

-- Tworzenie typu obiektowego dla tabeli Student
CREATE TYPE Student AS OBJECT (
    numer_indeksu NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    data_urodzenia DATE,
    plec BOOLEAN,
    status_studenta BOOLEAN,
    numer_pokoju_ref REF Pokoj
);

-- Tworzenie tabeli Student z kolumn¹ typu obiektowego
CREATE TABLE TabelaStudenci OF Student (
    numer_indeksu PRIMARY KEY,
    FOREIGN KEY (numer_pokoju_ref) REFERENCES TabelaPokoje,
    FOREIGN KEY (numer_pietra_ref) REFERENCES TabelaPietra,
    FOREIGN KEY (nazwa_akademika_ref) REFERENCES TabelaAkademiki
);

-- Tworzenie typu obiektowego dla tabeli Personel
CREATE TYPE Personel AS OBJECT (
    identyfikator_pracownika NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    stanowisko VARCHAR2(50)
);

-- Tworzenie tabeli Personel z kolumn¹ typu obiektowego
CREATE TABLE TabelaPersonel OF Personel (
    identyfikator_pracownika PRIMARY KEY
);

-- Tworzenie typu obiektowego dla tabeli Wp³aty
CREATE TYPE Wplaty AS OBJECT (
    numer_transakcji NUMBER,
    kwota NUMBER,
    data_transakcji DATE,
    numer_indeksu_ref REF Student
);

-- Tworzenie tabeli Wp³aty z kolumn¹ typu obiektowego
CREATE TABLE TabelaWplaty OF Wplaty (
    numer_transakcji PRIMARY KEY,
    FOREIGN KEY (numer_indeksu_ref) REFERENCES TabelaStudenci
);




-- Dodajemy kolumnê p³ci do typu Pokoj
ALTER TYPE Pokoj ADD MEMBER FUNCTION sprawdz_plec RETURN VARCHAR2;

-- Implementacja funkcji sprawdzaj¹cej p³eæ w pokoju
CREATE OR REPLACE TYPE BODY Pokoj AS
    MEMBER FUNCTION sprawdz_plec RETURN VARCHAR2 IS
    BEGIN
        RETURN 'MÊ¯CZYZNA'; -- Za³ó¿my, ¿e wszyscy mieszkañcy w pokoju musz¹ byæ tej samej p³ci
    END sprawdz_plec;
END;

-- Dodajemy kolumnê aktywny do tabeli Student
ALTER TABLE TabelaStudenci ADD (aktywny NUMBER(1) DEFAULT 1);

-- Tworzymy procedurê do sprawdzania op³at i ewentualnego wydalenia studenta
CREATE OR REPLACE PROCEDURE sprawdz_oplaty IS
BEGIN
    FOR wp in (SELECT * FROM TabelaWplaty WHERE data_transakcji < ADD_MONTHS(SYSDATE, -1)) LOOP
        UPDATE TabelaStudenci SET aktywny = 0 WHERE numer_indeksu = wp.numer_indeksu_ref.numer_indeksu;
    END LOOP;
END;

-- Tworzymy procedurê do sprawdzania czystoœci pokoju
CREATE OR REPLACE PROCEDURE sprawdz_czystosc_pokoju(p_numer_pokoju NUMBER) IS
BEGIN
    -- Implementacja sprawdzania czystoœci (mo¿na dostosowaæ wed³ug potrzeb)
    DBMS_OUTPUT.PUT_LINE('Sprawdzanie czystoœci pokoju ' || p_numer_pokoju || '...');
END;

-- Dodajemy kolumnê rezerwacja do tabeli TabelaStudenci
ALTER TABLE TabelaStudenci ADD (rezerwacja NUMBER(1) DEFAULT 0);

-- Tworzymy procedurê do rezerwacji miejsca w akademiku
CREATE OR REPLACE PROCEDURE zarezerwuj_miejsce(p_numer_indeksu NUMBER, p_z_osoba NUMBER DEFAULT 0) IS
BEGIN
    IF p_z_osoba = 0 THEN
        UPDATE TabelaStudenci SET rezerwacja = 1 WHERE numer_indeksu = p_numer_indeksu;
    ELSE
        UPDATE TabelaStudenci SET rezerwacja = 1 WHERE numer_indeksu = p_z_osoba OR numer_indeksu = p_numer_indeksu;
    END IF;
END;

-- Tworzymy procedurê do obs³ugi wynajmu pokoju
CREATE OR REPLACE PROCEDURE wynajmij_pokoj(p_numer_indeksu NUMBER, p_numer_pokoju NUMBER, p_data_poczatkowa DATE, p_data_koncowa DATE) IS
    v_max_wiek NUMBER := 30;
    v_cena NUMBER;
BEGIN
    -- Sprawdzamy, czy student spe³nia warunki wynajmu
    FOR s IN (SELECT * FROM TabelaStudenci WHERE numer_indeksu = p_numer_indeksu AND aktywny = 1 AND rezerwacja = 1 AND data_urodzenia > ADD_MONTHS(SYSDATE, -v_max_wiek * 12)) LOOP
        -- Sprawdzamy, czy pokój jest dostêpny
        FOR p IN (SELECT * FROM TabelaPokoje WHERE numer_pokoju = p_numer_pokoju) LOOP
            IF p.sprawdz_plec() <> s.plec THEN
                DBMS_OUTPUT.PUT_LINE('P³eæ mieszkañców w pokoju musi byæ taka sama.');
            ELSIF p.liczba_miejsc < 3 AND (p.liczba_miejsc + 1) < (SELECT COUNT(*) FROM TabelaStudenci WHERE numer_pokoju_ref.numer_pokoju = p_numer_pokoju) THEN
                DBMS_OUTPUT.PUT_LINE('W pokoju nie mo¿e mieszkaæ wiêcej ni¿ 3 osoby.');
            ELSE
                -- Okresowo sprawdzamy czystoœæ pokoju
                IF TO_CHAR(SYSDATE, 'DD') = '01' THEN
                    sprawdz_czystosc_pokoju(p_numer_pokoju);
                END IF;
                
                -- Ustalamy cenê wynajmu w zale¿noœci od liczby osób w pokoju
                v_cena := CASE
                            WHEN p.liczba_miejsc = 1 THEN 1000
                            WHEN p.liczba_miejsc = 2 THEN 800
                            WHEN p.liczba_miejsc = 3 THEN 600
                          END;

                -- Dodajemy wp³atê za wynajem
                INSERT INTO TabelaWplaty VALUES (numer_transakcji_seq.NEXTVAL, v_cena, SYSDATE, p_numer_indeksu, NULL);

                -- Aktualizujemy status rezerwacji i informacje o wynajêtym pokoju
                UPDATE TabelaStudenci SET rezerwacja = 0, numer_pokoju_ref = p_numer_pokoju WHERE numer_indeksu = p_numer_indeksu;

                DBMS_OUTPUT.PUT_LINE('Wynajêto pokój ' || p_numer_pokoju || ' przez studenta ' || p_numer_indeksu || ' na okres od ' || p_data_poczatkowa || ' do ' || p_data_koncowa);
            END IF;
        END LOOP;
    END LOOP;
END;

-- Tworzymy procedurê do obs³ugi wydalenia studenta
CREATE OR REPLACE PROCEDURE wydaj_studenta(p_numer_indeksu NUMBER) IS
BEGIN
    UPDATE TabelaStudenci SET aktywny = 0 WHERE numer_indeksu = p_numer_indeksu;
END;

