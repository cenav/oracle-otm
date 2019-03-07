CREATE OR REPLACE PACKAGE otm_qry AS
    FUNCTION en_curso(estado ot_mantto.estado%TYPE) RETURN BOOLEAN;
END;
