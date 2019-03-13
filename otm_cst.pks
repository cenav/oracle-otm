CREATE OR REPLACE PACKAGE otm_cst AS
    activo CONSTANT VARCHAR2(30) := 'ACTIVO';
    gasto CONSTANT VARCHAR2(30) := 'GASTO';
    mantenimiento CONSTANT VARCHAR2(30) := 'MAN';
    instalacion CONSTANT VARCHAR2(30) := 'INS';
    salida_transac  CONSTANT VARCHAR2(2) := '22';
    salida_serie    CONSTANT NUMBER := 1;
END;
