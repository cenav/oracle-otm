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
END otm_err;