CREATE OR REPLACE PACKAGE otm_asiento AS
    PROCEDURE activacion(ot IN OUT ot_mantto%ROWTYPE, af activo_fijo%ROWTYPE, fch DATE);
    PROCEDURE gasto(ot IN OUT ot_mantto%ROWTYPE, fch DATE);
END otm_asiento;