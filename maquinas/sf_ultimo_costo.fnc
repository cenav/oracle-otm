CREATE OR REPLACE FUNCTION sf_ultimo_costo_kardex(i_articulo articul.cod_art%TYPE, i_fecha DATE, i_moneda VARCHAR2) RETURN NUMBER IS
    k_costo_almacen CONSTANT VARCHAR2(2) := '02';
    costo_sol NUMBER := 0;
    costo_dol NUMBER := 0;
BEGIN
    -- Ultimo costo del kardex
    BEGIN
          WITH costo_kardex AS (
              SELECT *
                FROM tmp_moviart_dos
               WHERE cod_art = i_articulo
                 AND fecha <= i_fecha
               ORDER BY fecha DESC
          )
        SELECT costo, costo_d INTO costo_sol, costo_dol
          FROM costo_kardex
         WHERE rownum = 1;

    EXCEPTION
        WHEN no_data_found THEN costo_sol := 0; costo_dol := 0;
    END;

    IF costo_sol = 0 OR costo_dol = 0 THEN
        DECLARE
            importe_cambio NUMBER := 0;
        BEGIN
            -- Costo historico almacen
              WITH costo_historico AS (
                  SELECT *
                    FROM pcart_precios_hist
                   WHERE cod_art = i_articulo
                     AND cod_costo = k_costo_almacen
                     AND to_date(ano || mes, 'YYYYMM') <= i_fecha
                   ORDER BY to_date(ano || mes, 'YYYYMM') DESC
              )
            SELECT costo INTO costo_dol
              FROM costo_historico
             WHERE rownum = 1;

            importe_cambio := api_cambdol.ONEROW(i_fecha, 'V').import_cam;
            costo_sol := costo_dol * importe_cambio;
        EXCEPTION
            WHEN no_data_found THEN costo_sol := 0; costo_dol := 0;
        END;
    END IF;

    IF costo_sol = 0 OR costo_dol = 0 THEN
        DECLARE
            importe_cambio NUMBER := 0;
        BEGIN
            -- Ultimo costo almacen
            SELECT costo INTO costo_dol
              FROM pcart_precios
             WHERE cod_art = i_articulo
               AND cod_costo = k_costo_almacen;

            importe_cambio := api_cambdol.ONEROW(i_fecha, 'V').import_cam;
            costo_sol := costo_dol * importe_cambio;
        EXCEPTION
            WHEN no_data_found THEN costo_sol := 0; costo_dol := 0;
        END;
    END IF;

    RETURN CASE i_moneda WHEN 'S' THEN costo_sol ELSE costo_dol END;
END;