CREATE OR REPLACE PACKAGE otm_err AS
    SUBTYPE msg IS VARCHAR2(100);

    ex_afijo_existe    EXCEPTION;
    en_afijo_existe    CONSTANT INTEGER := -20001;
    em_afijo_existe    CONSTANT msg := 'Activo Fijo NO existe';
    PRAGMA EXCEPTION_INIT (ex_afijo_existe, -20001);

    ex_revisar_estado    EXCEPTION;
    en_revisar_estado    CONSTANT INTEGER := -20002;
    em_revisar_estado    CONSTANT msg := 'Revise el estado de la OTM para poder cerrarla';
    PRAGMA EXCEPTION_INIT (ex_revisar_estado, -20002);
        
    ex_instalacion_sin_valor    EXCEPTION;
    en_instalacion_sin_valor    CONSTANT INTEGER := -20003;
    em_instalacion_sin_valor    CONSTANT msg := 'El valor de la instalación no puede ser 0';
    PRAGMA EXCEPTION_INIT (ex_instalacion_sin_valor, -20003);
END otm_err;