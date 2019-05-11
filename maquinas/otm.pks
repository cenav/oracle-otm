CREATE OR REPLACE PACKAGE PEVISA.otm AS
    TYPE T_VALOR IS RECORD (
        soles NUMBER(12, 2)
        , dolares NUMBER(12, 2)
        );

    FUNCTION otm_x_oc(p_oc_serie itemord.serie%TYPE, p_oc_numero itemord.num_ped%TYPE) RETURN VARCHAR2;
    FUNCTION valor_total(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                         num ot_mantto.id_numero%TYPE) RETURN T_VALOR;
    FUNCTION esta_en_curso(p_tipo ot_mantto.id_tipo%TYPE, p_art ot_mantto.id_activo_fijo%TYPE) RETURN BOOLEAN;
    FUNCTION opcion_activacion(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                               num ot_mantto.id_numero%TYPE) RETURN VARCHAR2;
    PROCEDURE mail_mantto_preventivo;
    PROCEDURE activar(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE,
                      opcion VARCHAR2, fch DATE);
    FUNCTION valor_servicio(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE) RETURN T_VALOR;
    FUNCTION valor_repuesto(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE) RETURN T_VALOR;        
END otm;
/
