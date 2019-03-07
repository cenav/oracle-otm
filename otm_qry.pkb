CREATE OR REPLACE PACKAGE BODY otm_qry AS
    FUNCTION en_curso(estado ot_mantto.estado%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN estado = 1;
    END;
END;
/
