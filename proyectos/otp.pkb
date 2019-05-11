CREATE OR REPLACE PACKAGE BODY otp AS
    --Ordenes de trabajo de proyectos para control de activos fijos de edificaciones e infraestructura.

    FUNCTION en_curso(estado ot_mantto.estado%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN estado = 3;
    END;

    PROCEDURE valida_activacion(af activo_fijo%ROWTYPE, ot ot_mantto%ROWTYPE) IS
        d CONSTANT VARCHAR2(10) := ' ';
    BEGIN
        IF af.cod_activo_fijo IS NULL THEN
            raise_application_error(otcomun.en_afijo_existe, otcomun.em_afijo_existe || d || af.cod_activo_fijo);
        END IF;

        IF NOT en_curso(ot.estado) THEN
            raise_application_error(otcomun.en_revisar_estado, otcomun.em_revisar_estado);
        END IF;

        IF NOT otcomun.es_proyecto(ot.id_tipo) THEN
            raise_application_error(otcomun.en_no_es_proyecto, otcomun.em_no_es_proyecto);
        END IF;
    END;

    PROCEDURE activa_obra(ot IN OUT ot_mantto%ROWTYPE, af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
    BEGIN
        af.fecha_activacion := fch;
        af.valor_adquisicion_s := ot.total_activo_soles;
        af.valor_adquisicion_d := ot.total_activo_dolares;
        af.otm_tipo := ot.id_tipo;
        af.otm_serie := ot.id_serie;
        af.otm_numero := ot.id_numero;
        af.cod_estado := 1;
        api_activo_fijo.upd(af);
        otm_asiento.activacion(ot, af, trunc(fch));
        cierra_orden(ot, fch);
    END;

    PROCEDURE activa_mantenimiento(ot IN OUT ot_mantto%ROWTYPE, padre activo_fijo%ROWTYPE, fch DATE) IS
    BEGIN
        NULL;
    END;

    PROCEDURE activar(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE, opcion VARCHAR2, fch DATE) IS
        ot ot_mantto%ROWTYPE;
        af activo_fijo%ROWTYPE;
    BEGIN
        ot := api_ot_mantto.onerow(tpo, ser, num);
        af := api_activo_fijo.onerow(ot.id_activo_fijo);

        valida_activacion(af, ot);
        CASE opcion
            WHEN otcomun.k_activo THEN
                IF otcomun.es_obra(ot.id_modo) THEN
                    activa_obra(ot, af, fch);
                END IF;

                IF otcomun.es_mantenimiento(ot.id_modo) THEN
                    activa_mantenimiento(ot, af, fch);
                END IF;
            WHEN otcomun.k_gasto THEN
                otcomun.envia_al_gasto(ot, fch);
            END CASE;

        COMMIT;
    END;
END otp;
/