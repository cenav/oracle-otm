CREATE OR REPLACE PACKAGE BODY otm_asiento AS
    PROCEDURE activacion(ot IN OUT ot_mantto%ROWTYPE, af activo_fijo%ROWTYPE, fch DATE) AS
        -- Constantes
        c_moneda CONSTANT         VARCHAR2(1) := 'S';
        c_pase_ctacte CONSTANT    VARCHAR2(1) := 'N';
        c_fecha_registro CONSTANT DATE        := SYSDATE;

        -- Variables Globales
        g_ano                     movglos.ano%TYPE;
        g_mes                     movglos.mes%TYPE;
        g_libro                   movglos.libro%TYPE;
        g_voucher                 movglos.voucher%TYPE;
        g_cambio                  cambdol.import_cam%TYPE;
        g_param                   paramaf%ROWTYPE;

        PROCEDURE inicializa IS
        BEGIN
            g_param := api_paramaf.onerow();
            g_ano := TO_NUMBER(TO_CHAR(fch, 'YYYY'));
            g_mes := TO_NUMBER(TO_CHAR(fch, 'MM'));
            g_libro := g_param.libro_activo;
            g_voucher := api_movglos.nuevo_numero(g_ano, g_mes, g_libro);
            g_cambio := api_cambdol.onerow(fch, pkg_asiento.c_tipo_cambio).import_cam;
        END;

        PROCEDURE calc_cabecera IS
            mg movglos%ROWTYPE;
        BEGIN
            mg.ano := g_ano;
            mg.mes := g_mes;
            mg.libro := g_libro;
            mg.voucher := g_voucher;
            mg.glosa := pkg_asiento.glosa('ACTIVACION DE ' || af.cod_activo_fijo, g_ano, g_mes);
            mg.fecha := fch;
            mg.tipo_cambio := pkg_asiento.c_tipo_cambio;
            mg.estado := pkg_asiento.c_estado;
            mg.sistema := 'CONT';
            mg.pase_ctacte := c_pase_ctacte;
            mg.pase_cta_cte_pro := c_pase_ctacte;
            mg.moneda := c_moneda;
            mg.usuario := USER;
            mg.fec_reg := c_fecha_registro;
            mg.nro_planilla := TO_CHAR(fch, 'DD/MM/YYYY');

            api_movglos.ins(mg);
        END;

        PROCEDURE calc_cuenta_costo IS
            md movdeta%ROWTYPE;
        BEGIN
            md.ano := g_ano;
            md.mes := g_mes;
            md.libro := g_libro;
            md.voucher := g_voucher;
            md.cuenta := af.cuenta_contable;
            md.tipo_cambio := pkg_asiento.c_tipo_cambio;
            md.tipo_relacion := 'U';
            md.relacion := af.centro_costo;
            md.tipo_referencia := '00';
            md.serie := '0000';
            md.nro_referencia := substr(af.cod_activo_fijo, 0, 20);
            md.fecha := fch;
            md.detalle := ot.id_serie || '-' || ot.id_numero;
            md.cargo_s := af.valor_adquisicion_s;
            md.cargo_d := af.valor_adquisicion_d;
            md.abono_s := 0;
            md.abono_d := 0;
            md.estado := pkg_asiento.c_estado;
            md.columna := api_plancta.onerow(md.cuenta).col_compras;
            md.generado := api_plancta.genera_automaticos(md.cuenta);
            md.usuario := USER;
            md.fec_reg := c_fecha_registro;
            md.f_vencto := fch;
            md.cambio := ROUND(md.cargo_s / md.cargo_d, 3);
            md.file_cta_cte := 'N';

            api_movdeta.ins(md);
        END;

        PROCEDURE calc_cuenta_otm IS
            md movdeta%ROWTYPE;
        BEGIN
            md.ano := g_ano;
            md.mes := g_mes;
            md.libro := g_libro;
            md.voucher := g_voucher;
            md.cuenta := api_activo_fijo_clase.ONEROW(af.cod_clase).cuenta_puente;
            md.tipo_cambio := pkg_asiento.c_tipo_cambio;
            md.tipo_relacion := 'U';
            md.relacion := af.centro_costo;
            md.tipo_referencia := '00';
            md.serie := '0000';
            md.nro_referencia := substr(af.cod_activo_fijo, 0, 20);
            md.fecha := fch;
            md.detalle := ot.id_serie || '-' || ot.id_numero;
            md.cargo_s := 0;
            md.cargo_d := 0;
            md.abono_s := af.valor_adquisicion_s;
            md.abono_d := af.valor_adquisicion_d;
            md.estado := pkg_asiento.c_estado;
            md.columna := api_plancta.onerow(md.cuenta).col_compras;
            md.generado := api_plancta.genera_automaticos(md.cuenta);
            md.usuario := USER;
            md.fec_reg := c_fecha_registro;
            md.f_vencto := fch;
            md.cambio := ROUND(md.abono_s / md.abono_d, 3);
            md.file_cta_cte := 'N';

            api_movdeta.ins(md);
        END;

        PROCEDURE guarda_numero_voucher IS
            vou activo_fijo_asiento%ROWTYPE;
        BEGIN
            vou.cod_activo_fijo := af.cod_activo_fijo;
            vou.cod_tipo := 'ACTIVO';
            vou.ano := g_ano;
            vou.mes := g_mes;
            vou.libro := g_libro;
            vou.voucher := g_voucher;
            api_activo_fijo_asiento.ins(vou);

            ot.cierre_ano := g_ano;
            ot.cierre_mes := g_mes;
            ot.cierre_libro := g_libro;
            ot.cierre_voucher := g_voucher;
        END;
    BEGIN
        inicializa();
        calc_cabecera();
        calc_cuenta_costo();
        calc_cuenta_otm();
        guarda_numero_voucher();
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
                pkg_error.record_log('Fecha: ' || fch || ' Moneda: ' || c_moneda);
            END IF;

            ROLLBACK;
            RAISE;
    END;

    PROCEDURE gasto(ot IN OUT ot_mantto%ROWTYPE, fch DATE) AS
        -- Constantes
        c_moneda CONSTANT         VARCHAR2(1) := 'S';
        c_pase_ctacte CONSTANT    VARCHAR2(1) := 'N';
        c_fecha_registro CONSTANT DATE        := SYSDATE;

        -- Variables Globales
        g_ano                     movglos.ano%TYPE;
        g_mes                     movglos.mes%TYPE;
        g_libro                   movglos.libro%TYPE;
        g_voucher                 movglos.voucher%TYPE;
        g_cambio                  cambdol.import_cam%TYPE;
        g_param                   paramaf%ROWTYPE;
        g_activo                  activo_fijo%ROWTYPE;
        val                       otm.T_VALOR;

        PROCEDURE inicializa IS
        BEGIN
            g_param := api_paramaf.onerow();
            g_ano := TO_NUMBER(TO_CHAR(fch, 'YYYY'));
            g_mes := TO_NUMBER(TO_CHAR(fch, 'MM'));
            g_libro := g_param.libro_activo;
            g_voucher := api_movglos.nuevo_numero(g_ano, g_mes, g_libro);
            g_cambio := api_cambdol.onerow(fch, pkg_asiento.c_tipo_cambio).import_cam;
            g_activo := api_activo_fijo.onerow(ot.id_activo_fijo);
            val := otm.valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
        END;

        PROCEDURE calc_cabecera IS
            mg movglos%ROWTYPE;
        BEGIN
            mg.ano := g_ano;
            mg.mes := g_mes;
            mg.libro := g_libro;
            mg.voucher := g_voucher;
            mg.glosa := pkg_asiento.glosa('GASTO DE ' || ot.id_activo_fijo, g_ano, g_mes);
            mg.fecha := fch;
            mg.tipo_cambio := pkg_asiento.c_tipo_cambio;
            mg.estado := pkg_asiento.c_estado;
            mg.sistema := 'CONT';
            mg.pase_ctacte := c_pase_ctacte;
            mg.pase_cta_cte_pro := c_pase_ctacte;
            mg.moneda := c_moneda;
            mg.usuario := USER;
            mg.fec_reg := c_fecha_registro;
            mg.nro_planilla := TO_CHAR(fch, 'DD/MM/YYYY');

            api_movglos.ins(mg);
        END;

        PROCEDURE calc_cuenta_gasto IS
            md movdeta%ROWTYPE;
        BEGIN
            md.ano := g_ano;
            md.mes := g_mes;
            md.libro := g_libro;
            md.voucher := g_voucher;
            CASE
                WHEN otcomun.es_maquina(ot.id_tipo) THEN md.cuenta := g_param.cuenta_maquina_gasto;
                WHEN otcomun.es_proyecto(ot.id_tipo) THEN md.cuenta := g_param.cuenta_proyecto_gasto;
                WHEN otcomun.es_vehiculo(ot.id_tipo) THEN md.cuenta := g_param.cuenta_vehiculo_gasto;
                ELSE md.cuenta := g_param.cuenta_maquina_gasto;
                END CASE;
            md.tipo_cambio := pkg_asiento.c_tipo_cambio;
            md.tipo_relacion := 'U';
            md.relacion := ot.centro_costo;
            md.tipo_referencia := '00';
            md.serie := '0000';
            md.nro_referencia := ot.id_activo_fijo;
            md.fecha := fch;
            md.detalle := ot.id_serie || '-' || ot.id_numero;
            md.cargo_s := val.soles;
            md.cargo_d := val.dolares;
            md.abono_s := 0;
            md.abono_d := 0;
            md.estado := pkg_asiento.c_estado;
            md.columna := api_plancta.onerow(md.cuenta).col_compras;
            md.generado := api_plancta.genera_automaticos(md.cuenta);
            md.usuario := USER;
            md.fec_reg := c_fecha_registro;
            md.f_vencto := fch;
            md.cambio := ROUND(md.cargo_s / md.cargo_d, 3);
            md.file_cta_cte := 'N';

            api_movdeta.ins(md);
        END;

        PROCEDURE calc_cuenta_otm IS
            md movdeta%ROWTYPE;
        BEGIN
            md.ano := g_ano;
            md.mes := g_mes;
            md.libro := g_libro;
            md.voucher := g_voucher;
            md.cuenta := api_activo_fijo_clase.ONEROW(g_activo.cod_clase).cuenta_puente;
            md.tipo_cambio := pkg_asiento.c_tipo_cambio;
            md.tipo_relacion := 'U';
            md.relacion := ot.centro_costo;
            md.tipo_referencia := '00';
            md.serie := '0000';
            md.nro_referencia := ot.id_activo_fijo;
            md.fecha := fch;
            md.detalle := ot.id_serie || '-' || ot.id_numero;
            md.cargo_s := 0;
            md.cargo_d := 0;
            md.abono_s := val.soles;
            md.abono_d := val.dolares;
            md.estado := pkg_asiento.c_estado;
            md.columna := api_plancta.onerow(md.cuenta).col_compras;
            md.generado := api_plancta.genera_automaticos(md.cuenta);
            md.usuario := USER;
            md.fec_reg := c_fecha_registro;
            md.f_vencto := fch;
            md.cambio := ROUND(md.abono_s / md.abono_d, 3);
            md.file_cta_cte := 'N';

            api_movdeta.ins(md);
        END;

        PROCEDURE guarda_numero_voucher IS
        BEGIN
            ot.cierre_ano := g_ano;
            ot.cierre_mes := g_mes;
            ot.cierre_libro := g_libro;
            ot.cierre_voucher := g_voucher;
        END;
    BEGIN
        inicializa();
        calc_cabecera();
        calc_cuenta_gasto();
        calc_cuenta_otm();
        guarda_numero_voucher();
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
                pkg_error.record_log('Fecha: ' || fch || ' Moneda: ' || c_moneda);
            END IF;

            ROLLBACK;
            RAISE;
    END;
END otm_asiento;