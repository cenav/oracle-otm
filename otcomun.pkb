CREATE OR REPLACE PACKAGE BODY otcomun AS
    -- Orde de trabajo de activos fijos, t@odo el codigo en comun que tengan las OTM, OTP, OTV va aqui.

    FUNCTION es_maquina(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN tipo = otcomun.k_otmaquina;
    END;

    FUNCTION es_proyecto(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN tipo = otcomun.k_otproyecto;
    END;

    FUNCTION es_vehiculo(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN tipo = otcomun.k_otvehiculo;
    END;

    FUNCTION es_mantenimiento(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN modo = otcomun.k_mantenimiento;
    END;

    FUNCTION es_instalacion(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN modo = otcomun.k_instalacion;
    END;

    FUNCTION es_obra(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN modo = otcomun.k_obra;
    END;

    PROCEDURE envia_correo_gasto(ot ot_mantto%ROWTYPE) IS
        CURSOR cr_correos IS
            SELECT correo
              FROM notificacion
             WHERE sistema = 'ACTIVO_FIJO'
               AND proceso = 'ACTIVACION';

        mail    pkg_types.CORREO;
        s       VARCHAR2(10) := '-';
        asiento activo_fijo_asiento%ROWTYPE;
        mq      pr_tabmaq%ROWTYPE;
        af      activo_fijo%ROWTYPE;
        tipo    ot_mantto_tipo%ROWTYPE;
    BEGIN
        tipo := api_ot_mantto_tipo.ONEROW(ot.id_tipo);
        mail.asunto := 'Cierre de ' || tipo.abreviada || ' envio al gasto ' || ot.id_activo_fijo;
        mail.de := 'sistemas@pevisa.com.pe';
        mail.texto := 'Se ha enviado al gasto la siguiente orden de trabajo de ' || tipo.descripcion || '(' || tipo.abreviada || '):' ||
                      chr(10) || chr(10);
        mail.texto := rtrim(mail.texto) || tipo.abreviada || ': ' || ot.id_tipo || s || ot.id_serie || s || ot.id_numero || chr(10);
        mail.texto := rtrim(mail.texto) || 'Código: ' || ot.id_activo_fijo || chr(10);
        IF es_maquina(ot.id_tipo) THEN
            mq := api_pr_tabmaq.ONEROW(ot.id_activo_fijo);
            mail.texto := rtrim(mail.texto) || 'Descripción: ' || NVL(mq.abreviatura, mq.descripcion) || chr(10);
        ELSE
            mail.texto := rtrim(mail.texto) || 'Descripción: ' || af.descripcion || chr(10);
        END IF;
        mail.texto := rtrim(mail.texto) || 'Asiento Contable: ' || ot.cierre_ano || s || ot.cierre_mes || s ||
                      ot.cierre_libro || s || ot.cierre_voucher || chr(10);

        FOR r IN cr_correos LOOP
            enviar_correo(mail.de, r.correo, mail.asunto, mail.texto);
        END LOOP;
    END;

    PROCEDURE envia_al_gasto(ot IN OUT ot_mantto%ROWTYPE, fch DATE) IS
        val otm.T_VALOR;
    BEGIN
        val := otm.valor_total(ot.id_tipo, ot.id_serie, ot.id_numero);
        IF val.soles > 0 THEN
            otm_asiento.gasto(ot, trunc(fch));
        END IF;
        envia_correo_gasto(ot);
        ot.estado := '8';
        ot.fecha_cierre := fch;
        ot.usuario_cierre := user;
        ot.registro_contable := otcomun.k_gasto;
        ot.total_soles := val.soles;
        ot.total_dolares := val.dolares;
        api_ot_mantto.upd(ot);
    END;
END otcomun;
/