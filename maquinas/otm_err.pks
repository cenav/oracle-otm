CREATE OR REPLACE PACKAGE otm_err AS
    ex_instalacion_sin_valor EXCEPTION;
    en_instalacion_sin_valor CONSTANT INTEGER := -20003;
    em_instalacion_sin_valor CONSTANT otcomun.MSG := 'El valor de la instalación no puede ser 0';
    PRAGMA EXCEPTION_INIT (ex_instalacion_sin_valor, -20003);
END otm_err;