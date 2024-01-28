-- Tworzenie typu obiektowego dla tabeli Pokój
CREATE TYPE Pokoj AS OBJECT (
    numer_pokoju NUMBER,
    liczba_miejsc NUMBER
);

-- Tworzenie tabeli Pokój z kolumn¹ typu obiektowego
CREATE TABLE TabelaPokoje OF Pokoj (
    numer_pokoju PRIMARY KEY
);

-- Tworzenie typu obiektowego dla tabeli Piêtro
CREATE TYPE Pietro AS OBJECT (
    numer_pietra NUMBER
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

-- Tworzenie tabeli Akademik z kolumn¹ typu obiektowego
CREATE TABLE TabelaAkademiki OF Akademik (
    nazwa_akademika PRIMARY KEY
);

-- Tworzenie typu obiektowego dla tabeli Student
CREATE TYPE Student AS OBJECT (
    numer_indeksu NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    data_urodzenia DATE,
    numer_pokoju_ref REF Pokoj,
    numer_pietra_ref REF Pietro,
    nazwa_akademika_ref REF Akademik
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
    numer_indeksu_ref REF Student,
    identyfikator_pracownika_ref REF Personel
);

-- Tworzenie tabeli Wp³aty z kolumn¹ typu obiektowego
CREATE TABLE TabelaWplaty OF Wplaty (
    numer_transakcji PRIMARY KEY,
    FOREIGN KEY (numer_indeksu_ref) REFERENCES TabelaStudenci,
    FOREIGN KEY (identyfikator_pracownika_ref) REFERENCES TabelaPersonel
);
