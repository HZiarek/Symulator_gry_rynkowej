CREATE INDEX badania_rynku_nry_rund_fk_idx ON
    badania_rynku (
        numer_rundy
    ASC );

CREATE INDEX badania_rynku_marki_fk_idx ON
    badania_rynku (
        id_marki
    ASC );

CREATE INDEX badania_rynku_gr_kons_fk_idx ON
    badania_rynku (
        id_grupy_konsumentow
    ASC );

CREATE INDEX dost_prod_his_b_rynku_fk_idx ON
    dostepy_producentow_his_zakup (
        id_badania_rynku
    ASC );

CREATE INDEX historie_cen_nr_rund_fk_idx ON
    historie_cen (
        numer_rundy
    ASC );

CREATE INDEX magazynowania_marki_fk_idx ON
    magazynowania (
        id_marki
    ASC );

CREATE INDEX marketingi_nr_rund_fk_idx ON
    marketingi (
        numer_rundy
    ASC );

CREATE INDEX marketingi_rodz_mar_fk_idx ON
    marketingi (
        id_rodzaju_marketingu
    ASC );

CREATE INDEX marketingi_marki_fk_idx ON
    marketingi (
        id_marki
    ASC );

CREATE INDEX marki_producenci_fk_idx ON
    marki (
        id_producenta
    ASC );

CREATE INDEX marki_jakosci_marek_fk_idx ON
    marki (
        jakosc_marki
    ASC );

CREATE INDEX oceny_marek_b_ryn_fk_idx ON
    oceny_marek (
        id_badania_rynku
    ASC );

CREATE INDEX produkcje_nry_rund_fk_idx ON
    produkcje (
        numer_rundy
    ASC );

CREATE INDEX produkcje_marki_fk_idx ON
    produkcje (
        id_marki
    ASC );

CREATE INDEX przyn_do_gr_gr_kons_fk_idx ON
    przynaleznosci_do_grup (
        id_grupy_konsumentow
    ASC );

CREATE INDEX przyw_do_marek_marki_fk_idx ON
    przywiazania_do_marek (
        id_marki
    ASC );

CREATE INDEX zakupy_kons_marki_fk_idx ON
    zakupy_konsumentow (
        id_marki
    ASC );

CREATE INDEX zakupy_kons_nr_rund_fk_idx ON
    zakupy_konsumentow (
        numer_rundy
    ASC );

