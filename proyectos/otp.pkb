CREATE OR REPLACE PACKAGE BODY otp AS
    --Ordenes de trabajo de proyectos para control de activos fijos de edificaciones e infraestructura.
    param paramaf%ROWTYPE;

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

    PROCEDURE activa_activo_fijo(ot ot_mantto%ROWTYPE, af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
        total otm.T_VALOR;
    BEGIN
        total := otm.valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
        af.fecha_activacion := fch;
        af.valor_adquisicion_s := total.soles;
        af.valor_adquisicion_d := total.dolares;
        af.otm_tipo := ot.id_tipo;
        af.otm_serie := ot.id_serie;
        af.otm_numero := ot.id_numero;
        af.cod_estado := 1;
    END;

    PROCEDURE activa_obra(ot IN OUT ot_mantto%ROWTYPE, af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
    BEGIN
        activa_activo_fijo(ot, af, fch);
        api_activo_fijo.upd(af);
        otm_asiento.activacion(ot, af, trunc(fch));
        otcomun.cierra_orden(ot, fch);
        api_ot_mantto.upd(ot);
    END;

    PROCEDURE activa_mantenimiento(ot IN OUT ot_mantto%ROWTYPE, padre activo_fijo%ROWTYPE, fch DATE) IS
        d CONSTANT        VARCHAR2(30) := '-';
        subclase CONSTANT VARCHAR2(3)  := 'MAN';
        af                activo_fijo%ROWTYPE;
        val               otm.T_VALOR;
    BEGIN
        af.cod_activo_fijo := pkg_activo_fijo.NUEVO_CODIGO(padre.cod_activo_fijo, subclase);
        af.descripcion := 'MANTENIMIENTO DE MAQUINA ' || padre.cod_activo_fijo || ' OTM ' || ot.id_serie || d || ot.id_numero;
        af.cod_estado := '1';
        af.cod_clase := 'MAQ';
        af.cod_subclase := subclase;
        af.centro_costo := ot.centro_costo;
        af.cuenta_contable := padre.cuenta_contable;
        af.tangible_intangible := 'I';
        af.cod_tipo_adquisicion := 'PROPIO';
        val := otm.valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
        af.valor_adquisicion_s := val.soles;
        af.valor_adquisicion_d := val.dolares;
        af.moneda_adquisicion := 'S';
        af.otm_tipo := ot.id_tipo;
        af.otm_serie := ot.id_serie;
        af.otm_numero := ot.id_numero;
        af.valor_residual_s := 0;
        af.valor_residual_d := 0;
        af.cod_metodo_deprec := 'LIN';
        af.porcentaje_nif := param.porc_niif;
        af.porcentaje_tributario := param.porc_tributario;
        af.porcentaje_precios := param.porc_tributario;
        af.cod_adicion := padre.cod_activo_fijo;
        af.fecha_adquisicion := fch;
        af.fecha_activacion := fch;
        af.depreciable := 'S';
        af.origen := padre.origen;

        api_activo_fijo.ins(af);
        otm_asiento.activacion(ot, af, trunc(fch));
        otcomun.cierra_orden(ot, fch);
        api_ot_mantto.upd(ot);
        otcomun.envia_correo_activacion(af);
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
    BEGIN
    param := api_paramaf.onerow();
END otp;
/