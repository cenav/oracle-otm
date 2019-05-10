CREATE OR REPLACE PACKAGE otp AS
    PROCEDURE activar(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE, opcion VARCHAR2, fch DATE);
END otp;
/