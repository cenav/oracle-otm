CREATE OR REPLACE PACKAGE BODY otm AS
    param paramaf%ROWTYPE;

    PROCEDURE mail_mantto_preventivo IS
        CURSOR cr_preventivo_hoy IS
            SELECT cod_maquina, maquina, cod_operacion, operacion, frecuencia, intervalo_frecuencia
              FROM vw_mantto_preventivo_hoy
             WHERE prox_fecha_mantto = TRUNC(SYSDATE);

        mail pkg_types.MAXVARCHAR2;
        existe_registro BOOLEAN := FALSE ;
        s VARCHAR2(1) := ' ';
        m PLS_INTEGER := 20;
        n PLS_INTEGER := 40;
        o PLS_INTEGER := 80;
        f PLS_INTEGER := 10;
        i PLS_INTEGER := 9;
    BEGIN
        mail := 'Estos son los mantenimientos preventivos para el dia de hoy ' ||
                to_char(sysdate, 'dd/mm/yyyy') ||
                chr(10) || chr(10);
        mail := rtrim(mail) || rpad('MAQUINA', m) || s || rpad('NOMBRE', n) || s || rpad('OPERACION', o) ||
                s ||
                rpad('FRECUENCIA', f) || s || rpad('INTERVALO', i) || chr(10);
        mail := rtrim(mail) || rpad('=', m + n + o + f + i + 5, '=') || chr(10);

        FOR r IN cr_preventivo_hoy LOOP
            existe_registro := TRUE;
            mail := rtrim(mail) || rpad(r.cod_maquina, m) || s || rpad(r.maquina, n) || s ||
                    rpad(r.operacion, o) ||
                    s ||
                    rpad(r.frecuencia, f) || s || rpad(r.intervalo_frecuencia, i) || chr(10);
        END LOOP;

        IF existe_registro THEN
            enviar_correo('sistemas@pevisa.com.pe', 'mcastilla@pevisa.com.pe',
                          'Mantenimiento Preventivo de Hoy ' || to_char(sysdate, 'dd/mm/yyyy'), mail);
            enviar_correo('sistemas@pevisa.com.pe', 'cnavarro@pevisa.com.pe',
                          'Mantenimiento Preventivo de Hoy ' || to_char(sysdate, 'dd/mm/yyyy'), mail);
        END IF;
    END;

    FUNCTION otm_x_oc(p_oc_serie itemord.serie%TYPE, p_oc_numero itemord.num_ped%TYPE) RETURN VARCHAR2 IS
        lista pkg_types.MAXVARCHAR2;

        CURSOR cr_otm IS
            SELECT DISTINCT otm_serie, otm_numero
              FROM itemord
             WHERE serie = p_oc_serie
               AND num_ped = p_oc_numero
               AND otm_numero IS NOT NULL;
    BEGIN
        FOR r IN cr_otm LOOP
            lista := lista || ', ' || r.otm_serie || '-' || r.otm_numero;
        END LOOP;

        RETURN substr(lista, 3);
    END;

    FUNCTION valor_total(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                         num ot_mantto.id_numero%TYPE) RETURN T_VALOR IS
        val T_VALOR;
    BEGIN
          WITH valor_otm AS (
              SELECT soles, dolares
                FROM vw_compra_otm
               WHERE otm_serie = valor_total.ser
                 AND otm_numero = valor_total.num
                 AND otm_tipo = valor_total.tpo
               UNION ALL
              SELECT valor_sol, valor_dol
                FROM vw_repuesto_otm
               WHERE otm_serie = valor_total.ser
                 AND otm_numero = valor_total.num
                 AND otm_tipo = valor_total.tpo
          )
        SELECT nvl(sum(soles), 0), nvl(sum(dolares), 0) INTO val
          FROM valor_otm;

        RETURN val;
    END;

    FUNCTION valor_servicio(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                            num ot_mantto.id_numero%TYPE) RETURN T_VALOR IS
        val T_VALOR;
    BEGIN
        SELECT nvl(sum(soles), 0), nvl(sum(dolares), 0) INTO val
          FROM vw_compra_otm
         WHERE otm_serie = valor_servicio.ser
           AND otm_numero = valor_servicio.num
           AND otm_tipo = valor_servicio.tpo;

        RETURN val;
    END;

    FUNCTION valor_repuesto(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                            num ot_mantto.id_numero%TYPE) RETURN T_VALOR IS
        val T_VALOR;
    BEGIN
        SELECT nvl(sum(valor_sol), 0), nvl(sum(valor_dol), 0) INTO val
          FROM vw_repuesto_otm
         WHERE otm_serie = valor_repuesto.ser
           AND otm_numero = valor_repuesto.num
           AND otm_tipo = valor_repuesto.tpo;

        RETURN val;
    END;

    FUNCTION esta_en_curso(p_tipo ot_mantto.id_tipo%TYPE, p_art ot_mantto.id_activo_fijo%TYPE) RETURN BOOLEAN IS
        c PLS_INTEGER := 0;
    BEGIN
        SELECT count(*) INTO c
          FROM ot_mantto
         WHERE estado IN (0, 1)
           AND id_tipo = p_tipo
           AND id_activo_fijo = p_art;

        RETURN c > 0;
    END;

    PROCEDURE envia_correo_activacion(af activo_fijo%ROWTYPE) IS
        CURSOR cr_correos IS
            SELECT correo
              FROM notificacion
             WHERE sistema = 'ACTIVO_FIJO'
               AND proceso = 'ACTIVACION';

        mail pkg_types.CORREO;
        s VARCHAR2(10) := '-';
        asiento activo_fijo_asiento%ROWTYPE;
    BEGIN
        asiento := api_activo_fijo_asiento.ONEROW(af.cod_activo_fijo, 'ACTIVO');
        mail.asunto := 'Activación de OTM ' || af.cod_activo_fijo;
        mail.de := 'sistemas@pevisa.com.pe';
        mail.texto := 'Se ha activado la siguiente OTM:' || chr(10) || chr(10);
        mail.texto := rtrim(mail.texto) || 'Código: ' || af.cod_activo_fijo || chr(10);
        mail.texto := rtrim(mail.texto) || 'Descripción: ' || af.descripcion || chr(10);
        mail.texto := rtrim(mail.texto) || 'OTM: ' || af.otm_tipo || s || af.otm_serie || s || af.otm_numero || chr(10);
        mail.texto := rtrim(mail.texto) || 'Fecha activación: ' || to_char(af.fecha_activacion, 'DD/MM/YYYY') || chr(10);
        mail.texto := rtrim(mail.texto) || 'Asiento Contable: ' || asiento.ano || s || asiento.mes || s ||
                      asiento.libro || s || asiento.voucher || chr(10);

        FOR r IN cr_correos LOOP
            enviar_correo(mail.de, r.correo, mail.asunto, mail.texto);
        END LOOP;
    END;

    PROCEDURE envia_correo_gasto(ot ot_mantto%ROWTYPE) IS
        CURSOR cr_correos IS
            SELECT correo
              FROM notificacion
             WHERE sistema = 'ACTIVO_FIJO'
               AND proceso = 'ACTIVACION';

        mail pkg_types.CORREO;
        s VARCHAR2(10) := '-';
        asiento activo_fijo_asiento%ROWTYPE;
        mq pr_tabmaq%ROWTYPE;
    BEGIN
        mail.asunto := 'Cierre de OTM envio al gasto ' || ot.id_activo_fijo;
        mail.de := 'sistemas@pevisa.com.pe';
        mail.texto := 'Se ha enviado al gasto la siguiente OTM:' || chr(10) || chr(10);
        mail.texto := rtrim(mail.texto) || 'OTM: ' || ot.id_tipo || s || ot.id_serie || s || ot.id_numero || chr(10);
        mail.texto := rtrim(mail.texto) || 'Máquina: ' || ot.id_activo_fijo || chr(10);
        mq := api_pr_tabmaq.ONEROW(ot.id_activo_fijo);
        mail.texto := rtrim(mail.texto) || 'Descripción: ' || NVL(mq.abreviatura, mq.descripcion) || chr(10);
        mail.texto := rtrim(mail.texto) || 'Asiento Contable: ' || ot.cierre_ano || s || ot.cierre_mes || s ||
                      ot.cierre_libro || s || ot.cierre_voucher || chr(10);

        FOR r IN cr_correos LOOP
            enviar_correo(mail.de, r.correo, mail.asunto, mail.texto);
        END LOOP;
    END;

    PROCEDURE envia_correo_instalacion(af activo_fijo%ROWTYPE) IS
        CURSOR cr_correos IS
            SELECT correo
              FROM notificacion
             WHERE sistema = 'ACTIVO_FIJO'
               AND proceso = 'ACTIVACION';

        mail pkg_types.CORREO;
        s VARCHAR2(10) := '-';
        asiento activo_fijo_asiento%ROWTYPE;
    BEGIN
        asiento := api_activo_fijo_asiento.ONEROW(af.cod_activo_fijo, 'ACTIVO');
        mail.asunto := 'Instalación de activo fijo ' || af.cod_activo_fijo;
        mail.de := 'sistemas@pevisa.com.pe';
        mail.texto := 'Se ha instalado el siguiente activo fijo:' || chr(10) || chr(10);
        mail.texto := rtrim(mail.texto) || 'Código: ' || af.cod_activo_fijo || chr(10);
        mail.texto := rtrim(mail.texto) || 'Descripción: ' || af.descripcion || chr(10);
        mail.texto := rtrim(mail.texto) || 'OTM: ' || af.otm_tipo || s || af.otm_serie || s || af.otm_numero || chr(10);
        mail.texto := rtrim(mail.texto) || 'Fecha activación: ' || to_char(af.fecha_activacion, 'DD/MM/YYYY') || chr(10);
        mail.texto := rtrim(mail.texto) || 'Asiento Contable: ' || asiento.ano || s || asiento.mes || s ||
                      asiento.libro || s || asiento.voucher || chr(10);

        FOR r IN cr_correos LOOP
            enviar_correo(mail.de, r.correo, mail.asunto, mail.texto);
        END LOOP;
    END;

    PROCEDURE valida_activacion(af activo_fijo%ROWTYPE, ot ot_mantto%ROWTYPE) IS
        d CONSTANT VARCHAR2(10) := ' ';
    BEGIN
        IF af.cod_activo_fijo IS NULL
        THEN
            raise_application_error(otm_err.en_afijo_existe, otm_err.em_afijo_existe || d || af.cod_activo_fijo);
        END IF;

        IF NOT otm_qry.en_curso(ot.estado)
        THEN
            raise_application_error(otm_err.en_revisar_estado, otm_err.em_revisar_estado);
        END IF;
    END;

    FUNCTION opcion_activacion(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE,
                               num ot_mantto.id_numero%TYPE) RETURN VARCHAR2 IS
        val T_VALOR;
        opcion VARCHAR2(30);
    BEGIN
        val := valor_total(tpo, ser, num);

        CASE
            WHEN val.soles >= param.rango_min_activo THEN
                opcion := otm_cst.activo;
            WHEN val.soles <= param.rango_max_gasto THEN
                opcion := otm_cst.gasto;
            ELSE
                opcion := otm_cst.gasto;
            END CASE;

        RETURN opcion;
    END;

    PROCEDURE activa_mantenimiento(ot IN OUT ot_mantto%ROWTYPE, a activo_fijo%ROWTYPE, fch DATE) IS
        d CONSTANT VARCHAR2(30) := '-';
        subclase CONSTANT VARCHAR2(3) := 'MAN';
        correlativo PLS_INTEGER := 0;
        af activo_fijo%ROWTYPE;
        cod_activo activo_fijo.cod_activo_fijo%TYPE;
        val T_VALOR;
        es_submaquina_referencial BOOLEAN;
    BEGIN
        es_submaquina_referencial := a.depreciable = 'N' AND a.cod_adicion IS NOT NULL;
        IF es_submaquina_referencial THEN
            cod_activo := a.cod_adicion; -- asigna al padre
        ELSE
            cod_activo := a.cod_activo_fijo;
        END IF;
        correlativo := pkg_activo_fijo.correlativo_subclase(cod_activo, subclase);
        af.cod_activo_fijo := cod_activo || ' ' || subclase || correlativo;
        af.descripcion :=
                    'MANTENIMIENTO DE MAQUINA ' || cod_activo || ' OTM ' || ot.id_serie || d || ot.id_numero;
        af.cod_estado := '1';
        af.cod_clase := 'MAQ';
        af.cod_subclase := subclase;
        af.centro_costo := ot.centro_costo;
        af.tangible_intangible := 'I';
        af.cod_tipo_adquisicion := 'PROPIO';
        val := valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
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
        af.cod_adicion := cod_activo;
        af.fecha_adquisicion := fch;
        af.fecha_activacion := fch;
        af.depreciable := 'S';
        af.origen := 'NAC';

        api_activo_fijo.ins(af);
        otm_asiento.activacion(ot, af, trunc(fch));

        ot.estado := 8;
        ot.fecha_cierre := fch;
        ot.usuario_cierre := user;
        ot.registro_contable := otm_cst.activo;
        ot.total_soles := val.soles;
        ot.total_dolares := val.dolares;
        api_ot_mantto.upd(ot);

        envia_correo_activacion(af);
    END;

    PROCEDURE saca_del_almacen(af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
        kg kardex_g%ROWTYPE;
        kd kardex_d%ROWTYPE;
    BEGIN
        kg.cod_alm := param.almacen_activo_fijo;
        kg.tp_transac := otm_cst.salida_transac;
        kg.serie := otm_cst.salida_serie;
        kg.numero := api_kardex_g.next_numero(otm_cst.salida_transac, otm_cst.salida_serie);
        kg.fch_transac := fch;
        kg.tip_doc_ref := af.otm_tipo;
        kg.ser_doc_ref := af.otm_serie;
        kg.nro_doc_ref := af.otm_numero;
        kg.glosa := 'Salida por activacion de activo fijo ' || af.cod_activo_fijo;
        kg.tp_relacion := 'C';
        kg.nro_lista := 1;
        kg.por_desc1 := 0;
        kg.por_desc2 := 0;
        kg.motivo := 1;
        kg.estado := 0;
        kg.origen := 'P';
        kg.ing_sal := 'S';
        kg.flg_impr := 0;
        kg.num_importa := 'SM :1 ' || kg.nro_doc_ref;
        api_kardex_g.ins(kg);

        kd.cod_alm := kg.cod_alm;
        kd.tp_transac := kg.tp_transac;
        kd.serie := kg.serie;
        kd.numero := kg.numero;
        kd.cod_art := af.cod_activo_fijo;
        kd.cantidad := 1;
        kd.costo_s := 0;
        kd.costo_d := 0;
        kd.fch_transac := SYSDATE;
        kd.por_desc1 := 0;
        kd.por_desc2 := 0;
        kd.imp_vvb := 0;
        kd.estado := 0;
        kd.origen := 'P';
        kd.ing_sal := 'S';
        kd.pr_referencia := 'ACTIVACION ACTIVO FIJO';
        api_kardex_d.ins(kd);

        af.activacion_almacen := kg.cod_alm;
        af.activacion_tp_transac := kg.tp_transac;
        af.activacion_serie := kg.serie;
        af.activacion_numero := kg.numero;
    END;

    PROCEDURE activa_activo_fijo(ot IN OUT ot_mantto%ROWTYPE, af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
    BEGIN
        af.fecha_activacion := fch;
        af.valor_adquisicion_s := ot.total_activo_soles;
        af.valor_adquisicion_d := ot.total_activo_dolares;
        af.otm_tipo := ot.id_tipo;
        af.otm_serie := ot.id_serie;
        af.otm_numero := ot.id_numero;
        af.cod_estado := 1;
        saca_del_almacen(af, fch);
        api_activo_fijo.upd(af);
        otm_asiento.activacion(ot, af, trunc(fch));
    END;

    PROCEDURE activa_servicio_instalacion(ot IN OUT ot_mantto%ROWTYPE, fch DATE) IS
        subclase CONSTANT VARCHAR2(3) := 'INS';
        correlativo PLS_INTEGER := 0;
        af activo_fijo%ROWTYPE;
        servicio T_VALOR;
        repuesto T_VALOR;
    BEGIN
        servicio := valor_servicio(ot.id_tipo, ot.id_serie, ot.id_numero);
        repuesto := valor_repuesto(ot.id_tipo, ot.id_serie, ot.id_numero);

        IF servicio.soles + repuesto.soles > 0 THEN
            correlativo := pkg_activo_fijo.correlativo_subclase(ot.id_activo_fijo, subclase);
            af.cod_activo_fijo := ot.id_activo_fijo || ' ' || subclase || correlativo;
            af.descripcion :=
                        'INSTALACION DE MAQUINA ' || ot.id_activo_fijo || ' OTM ' || ot.id_serie || '-' || ot.id_numero;
            af.cod_estado := '1';
            af.cod_clase := 'MAQ';
            af.cod_subclase := subclase;
            af.centro_costo := ot.centro_costo;
            af.tangible_intangible := 'I';
            af.cod_tipo_adquisicion := 'PROPIO';
            af.valor_adquisicion_s := servicio.soles + repuesto.soles;
            af.valor_adquisicion_d := servicio.dolares + repuesto.dolares;
            af.moneda_adquisicion := 'S';
            af.otm_tipo := ot.id_tipo;
            af.otm_serie := ot.id_serie;
            af.otm_numero := ot.id_numero;
            af.cod_metodo_deprec := 'LIN';
            af.porcentaje_nif := param.porc_niif;
            af.porcentaje_tributario := param.porc_tributario;
            af.porcentaje_precios := param.porc_precios;
            af.cod_adicion := ot.id_activo_fijo;
            af.fecha_adquisicion := fch;
            af.fecha_activacion := fch;
            af.depreciable := 'S';
            af.origen := 'NAC';

            api_activo_fijo.ins(af);
            otm_asiento.activacion(ot, af, trunc(fch));
        ELSE
            raise_application_error(otm_err.en_instalacion_sin_valor, otm_err.em_instalacion_sin_valor);
        END IF;

    END;

    PROCEDURE cierra_orden(ot IN OUT ot_mantto%ROWTYPE, fch DATE) IS
        servicio T_VALOR;
        repuesto T_VALOR;
    BEGIN
        servicio := valor_servicio(ot.id_tipo, ot.id_serie, ot.id_numero);
        repuesto := valor_repuesto(ot.id_tipo, ot.id_serie, ot.id_numero);
        ot.estado := 8;
        ot.fecha_cierre := fch;
        ot.usuario_cierre := user;
        ot.registro_contable := otm_cst.activo;
        ot.total_servicio_soles := servicio.soles;
        ot.total_servicio_dolares := servicio.dolares;
        ot.total_repuesto_soles := repuesto.soles;
        ot.total_repuesto_dolares := repuesto.dolares;
        ot.total_soles := ot.total_activo_soles + servicio.soles + repuesto.soles;
        ot.total_dolares := ot.total_activo_dolares + servicio.dolares + repuesto.dolares;
        api_ot_mantto.upd(ot);
    END;

    PROCEDURE activa_instalacion(ot IN OUT ot_mantto%ROWTYPE, af IN OUT activo_fijo%ROWTYPE, fch DATE) IS
    BEGIN
        activa_activo_fijo(ot, af, fch);
        activa_servicio_instalacion(ot, fch);
        cierra_orden(ot, fch);
        envia_correo_instalacion(af);
    END;

    PROCEDURE envia_al_gasto(ot IN OUT ot_mantto%ROWTYPE, fch DATE) IS
        val T_VALOR;
    BEGIN
        val := valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
        IF val.soles > 0 THEN
            otm_asiento.gasto(ot, trunc(fch));
        END IF;
        envia_correo_gasto(ot);
        ot.estado := '8';
        ot.fecha_cierre := fch;
        ot.usuario_cierre := user;
        ot.registro_contable := otm_cst.gasto;
        ot.total_soles := val.soles;
        ot.total_dolares := val.dolares;
        api_ot_mantto.upd(ot);
    END;

    PROCEDURE activar(tpo ot_mantto.id_tipo%TYPE, ser ot_mantto.id_serie%TYPE, num ot_mantto.id_numero%TYPE,
                      opcion VARCHAR2, fch DATE) IS
        ot ot_mantto%ROWTYPE;
        af activo_fijo%ROWTYPE;
        es_mantenimiento BOOLEAN;
        es_instalacion BOOLEAN;
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
    BEGIN
    param := api_paramaf.onerow();
END otm;