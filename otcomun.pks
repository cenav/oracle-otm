CREATE OR REPLACE PACKAGE otcomun AS
    SUBTYPE MSG IS VARCHAR2(100);

    k_activo CONSTANT VARCHAR2(30) := 'ACTIVO';
    k_gasto CONSTANT VARCHAR2(30) := 'GASTO';
    k_mantenimiento CONSTANT VARCHAR2(30) := 'MAN';
    k_instalacion CONSTANT VARCHAR2(30) := 'INS';
    k_obra CONSTANT VARCHAR2(30) := 'OBR';
    k_salida_transac CONSTANT VARCHAR2(2) := '22';
    k_salida_serie CONSTANT NUMBER := 1;
    k_otmaquina CONSTANT VARCHAR2(2) := 'MQ';
    k_otproyecto CONSTANT VARCHAR2(2) := 'PY';
    k_otvehiculo CONSTANT VARCHAR2(2) := 'VH';

    ex_afijo_existe EXCEPTION;
    en_afijo_existe CONSTANT INTEGER := -20001;
    em_afijo_existe CONSTANT MSG := 'Activo Fijo NO existe';
    PRAGMA EXCEPTION_INIT (ex_afijo_existe, -20001);

    ex_revisar_estado EXCEPTION;
    en_revisar_estado CONSTANT INTEGER := -20002;
    em_revisar_estado CONSTANT otcomun.MSG := 'Revise el estado de la OTM para poder cerrarla';
    PRAGMA EXCEPTION_INIT (ex_revisar_estado, -20002);

    ex_no_es_proyecto EXCEPTION;
    en_no_es_proyecto CONSTANT INTEGER := -20003;
    em_no_es_proyecto CONSTANT otcomun.MSG := 'La orden de trabajo no es de proyetos';
    PRAGMA EXCEPTION_INIT (ex_no_es_proyecto, -20003);

    PROCEDURE envia_al_gasto(ot IN OUT ot_mantto%ROWTYPE, fch DATE);

    FUNCTION es_maquina(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN;
    FUNCTION es_proyecto(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN;
    FUNCTION es_vehiculo(tipo ot_mantto.id_tipo%TYPE) RETURN BOOLEAN;
    FUNCTION es_mantenimiento(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN;
    FUNCTION es_instalacion(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN;
    FUNCTION es_obra(modo ot_mantto.id_modo%TYPE) RETURN BOOLEAN;
END otcomun;
/
