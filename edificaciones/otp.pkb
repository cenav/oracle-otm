CREATE OR REPLACE PACKAGE BODY otp AS
    PROCEDURE activar(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE, opcion VARCHAR2, fch DATE) IS
        ot               ot_mantto%ROWTYPE;
        af               activo_fijo%ROWTYPE;
        es_mantenimiento BOOLEAN;
        es_instalacion   BOOLEAN;
    BEGIN
        ot := api_ot_mantto.onerow(tpo, ser, num);
        af := api_activo_fijo.onerow(ot.id_activo_fijo);

        CASE opcion
            WHEN otm_cst.activo THEN
                valida_activacion(af, ot);
                es_mantenimiento := ot.id_modo = otm_cst.mantenimiento;
                es_instalacion := ot.id_modo = otm_cst.instalacion;

                IF es_mantenimiento THEN
                    activa_mantenimiento(ot, af, fch);
                END IF;

                IF es_instalacion THEN
                    activa_instalacion(ot, af, fch);
                END IF;
            WHEN otm_cst.gasto THEN
                envia_al_gasto(ot, fch);
            END CASE;

        COMMIT;
    END;
END otp;
/