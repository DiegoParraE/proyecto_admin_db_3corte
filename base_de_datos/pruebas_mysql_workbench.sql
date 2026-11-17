-- Actividad adicional: pruebas de concesionario_db desde MySQL Workbench.
-- No entra en docker-entrypoint-initdb.d. Se corre a mano, con la base ya cargada.
--
-- Conexion:
--   Host 127.0.0.1  Puerto 3307  Esquema concesionario_db
--   Usuario admin_concesionario  Clave Admin#2026
--
-- Workbench: File, Open SQL Script, y luego el rayo "Execute the selected portion
-- of the script or everything, if there is no selection".
--
-- El procedimiento de apoyo vende un carro disponible, comprueba trigger y
-- auditoria, anula esa venta y borra las filas de auditoria de la prueba.
-- Al terminar, el script borra el procedimiento y la tabla de resultados.
-- La evidencia queda en las grillas de Workbench.
--
-- La prueba de permisos de consulta_concesionario no va aqui: con este usuario
-- el INSERT si funcionaria. Esa prueba esta en el documento y se corre en otra
-- pestaña, conectado como consulta_concesionario.

USE concesionario_db;
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS sp_ejecutar_pruebas_case;
DROP TABLE IF EXISTS resultado_pruebas_case;

CREATE TABLE resultado_pruebas_case (
  orden INT NOT NULL,
  prueba VARCHAR(160) NOT NULL,
  esperado VARCHAR(160) NOT NULL,
  resultado VARCHAR(10) NOT NULL,
  detalle VARCHAR(255) NOT NULL,
  PRIMARY KEY (orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELIMITER $$

CREATE PROCEDURE sp_ejecutar_pruebas_case()
SQL SECURITY INVOKER
BEGIN
  DECLARE v_carro INT DEFAULT NULL;
  DECLARE v_venta INT DEFAULT NULL;
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_n INT DEFAULT 0;
  DECLARE v_inventario INT DEFAULT 0;
  DECLARE v_disponibles INT DEFAULT 0;
  DECLARE v_detalle_ventas INT DEFAULT 0;
  DECLARE v_sedes INT DEFAULT 0;

  -- 1. CHECK Precio_Venta > 0
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (1, 'CHECK Precio_Venta > 0', 'rechazar precio 0', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario)
    VALUES ('CHS-CASE-PRECIO', 'Prueba', 'CASE', 2024, 1, 0, 'Disponible');

    DELETE FROM CARROS WHERE VIN = 'CHS-CASE-PRECIO';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (1, 'CHECK Precio_Venta > 0', 'rechazar precio 0', 'FALLO', 'La fila quedo guardada');
  END;

  -- 2. CHECK Estado_Inventario
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (2, 'CHECK Estado_Inventario', 'rechazar estado Reservado', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario)
    VALUES ('CHS-CASE-ESTADO', 'Prueba', 'CASE', 2024, 1, 1000, 'Reservado');

    DELETE FROM CARROS WHERE VIN = 'CHS-CASE-ESTADO';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (2, 'CHECK Estado_Inventario', 'rechazar estado Reservado', 'FALLO', 'La fila quedo guardada');
  END;

  -- 3. CHECK anio
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (3, 'CHECK Anio entre 1980 y 2100', 'rechazar anio 1970', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario)
    VALUES ('CHS-CASE-ANIO', 'Prueba', 'CASE', 1970, 1, 1000, 'Disponible');

    DELETE FROM CARROS WHERE VIN = 'CHS-CASE-ANIO';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (3, 'CHECK Anio entre 1980 y 2100', 'rechazar anio 1970', 'FALLO', 'La fila quedo guardada');
  END;

  -- 4. UNIQUE del chasis
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (4, 'UNIQUE VIN', 'rechazar el chasis CHS10001ABC repetido', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario)
    VALUES ('CHS10001ABC', 'Prueba', 'CASE', 2024, 1, 1000, 'Disponible');

    DELETE FROM CARROS WHERE Marca = 'Prueba' AND VIN = 'CHS10001ABC' AND CarroID <> 1;
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (4, 'UNIQUE VIN', 'rechazar el chasis CHS10001ABC repetido', 'FALLO', 'MySQL acepto el chasis duplicado');
  END;

  -- 5. Llave foranea de sede
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (5, 'FK CARROS.SedeID', 'rechazar una sede que no existe', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario)
    VALUES ('CHS-CASE-FK', 'Prueba', 'CASE', 2024, 999, 1000, 'Disponible');

    DELETE FROM CARROS WHERE VIN = 'CHS-CASE-FK';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (5, 'FK CARROS.SedeID', 'rechazar una sede que no existe', 'FALLO', 'La fila quedo guardada');
  END;

  -- 6. Trigger BEFORE INSERT: carro ya vendido (el Corolla, CarroID 5)
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (6, 'Trigger de carro vendido', 'rechazar otra venta del Corolla', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO VENTA (ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago)
    VALUES (1, 1, 5, CURDATE(), 105000000, 'Contado');

    -- Solo se llega aqui si el trigger no rechazo la fila. Se borra la venta
    -- extra y se deja el Corolla vendido, como en los datos de prueba.
    DELETE FROM VENTA WHERE CarroID = 5 AND VentaID <> 1;
    UPDATE CARROS SET Estado_Inventario = 'Vendido' WHERE CarroID = 5;
    DELETE FROM AUDITORIA
    WHERE Tabla = 'VENTA'
      AND Registro_ID IS NOT NULL
      AND Registro_ID <> 1
      AND Detalle LIKE '%carro 5%';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (6, 'Trigger de carro vendido', 'rechazar otra venta del Corolla', 'FALLO', 'La segunda venta quedo guardada');
  END;

  -- 7. Trigger BEFORE INSERT: carro que no existe
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (7, 'Trigger de carro inexistente', 'rechazar CarroID 99999', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO VENTA (ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago)
    VALUES (1, 1, 99999, CURDATE(), 1000, 'Contado');

    DELETE FROM VENTA WHERE CarroID = 99999;
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (7, 'Trigger de carro inexistente', 'rechazar CarroID 99999', 'FALLO', 'La venta quedo guardada');
  END;

  -- 8. CHECK Forma_Pago
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (8, 'CHECK Forma_Pago', 'rechazar Efectivo', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO VENTA (ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago)
    VALUES (1, 1, 1, CURDATE(), 65000000, 'Efectivo');

    DELETE FROM VENTA WHERE CarroID = 1 AND Forma_Pago = 'Efectivo';
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (8, 'CHECK Forma_Pago', 'rechazar Efectivo', 'FALLO', 'La venta quedo guardada');
  END;

  -- 9. N:M. CARRO_PROVEEDOR no acepta un proveedor que no existe.
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (9, 'FK de la relacion N:M', 'rechazar ProveedorID 999', 'PASO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARRO_PROVEEDOR (CarroID, ProveedorID, Fecha_Compra_Prov, Costo_Compra_Prov)
    VALUES (1, 999, CURDATE(), 1000);

    DELETE FROM CARRO_PROVEEDOR WHERE ProveedorID = 999;
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (9, 'FK de la relacion N:M', 'rechazar ProveedorID 999', 'FALLO', 'La compra quedo guardada');
  END;

  -- 10. sp_registrar_venta rechaza una forma de pago fuera de la lista
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (10, 'sp_registrar_venta valida el pago', 'rechazar Efectivo y no dejar venta', 'PASO', LEFT(v_msg, 255));
    END;

    CALL sp_registrar_venta(1, 1, 1, 'Efectivo');
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (10, 'sp_registrar_venta valida el pago', 'rechazar Efectivo y no dejar venta', 'FALLO', 'El procedimiento no rechazo el pago');
  END;

  -- 11. sp_anular_venta hace ROLLBACK si la venta no existe
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (11, 'sp_anular_venta inexistente', 'senalar que la venta no existe', 'PASO', LEFT(v_msg, 255));
    END;

    CALL sp_anular_venta(999999);
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (11, 'sp_anular_venta inexistente', 'senalar que la venta no existe', 'FALLO', 'El procedimiento no fallo');
  END;

  -- 12. DEFAULT de Estado_Inventario
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      DELETE FROM CARROS WHERE VIN = 'CHS-CASE-DEFAULT';
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (12, 'DEFAULT Estado_Inventario', 'quedar en Disponible', 'FALLO', LEFT(v_msg, 255));
    END;

    INSERT INTO CARROS (VIN, Marca, Modelo, Anio, SedeID, Precio_Venta)
    VALUES ('CHS-CASE-DEFAULT', 'Prueba', 'CASE', 2024, 1, 1000);

    SELECT Estado_Inventario INTO v_estado
    FROM CARROS
    WHERE VIN = 'CHS-CASE-DEFAULT';

    DELETE FROM CARROS WHERE VIN = 'CHS-CASE-DEFAULT';

    IF v_estado <> 'Disponible' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estado por defecto no fue Disponible';
    END IF;

    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (12, 'DEFAULT Estado_Inventario', 'quedar en Disponible', 'PASO', 'La columna tomo el valor Disponible');
  END;

  -- 13. Venta real de prueba: procedimiento, trigger, auditoria y anulacion.
  --     Deja el carro como estaba y borra la auditoria de esta sola venta.
  BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE v_falta INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_falta = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
      IF v_venta IS NOT NULL THEN
        BEGIN
          DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
          CALL sp_anular_venta(v_venta);
        END;
      END IF;
      INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
      VALUES (
        13,
        'Venta, trigger, auditoria y anulacion',
        'vender, marcar Vendido, auditar, anular y devolver el carro',
        'FALLO',
        LEFT(v_msg, 255)
      );
    END;

    SET v_carro = NULL;
    SET v_venta = NULL;
    SET v_falta = 0;

    SELECT c.CarroID INTO v_carro
    FROM CARROS c
    LEFT JOIN VENTA v ON v.CarroID = c.CarroID
    WHERE c.Estado_Inventario = 'Disponible'
      AND v.VentaID IS NULL
    ORDER BY c.CarroID
    LIMIT 1;

    IF v_falta = 1 OR v_carro IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay un carro disponible para la prueba';
    END IF;

    CALL sp_registrar_venta(1, 1, v_carro, 'Contado');

    SELECT VentaID INTO v_venta
    FROM VENTA
    WHERE CarroID = v_carro;

    SELECT Estado_Inventario INTO v_estado
    FROM CARROS
    WHERE CarroID = v_carro;

    IF v_estado <> 'Vendido' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El trigger no marco el carro como Vendido';
    END IF;

    SELECT COUNT(*) INTO v_n
    FROM AUDITORIA
    WHERE Tabla = 'VENTA'
      AND Operacion = 'INSERT'
      AND Registro_ID = v_venta;

    IF v_n < 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta no quedo en AUDITORIA';
    END IF;

    CALL sp_anular_venta(v_venta);

    SELECT Estado_Inventario INTO v_estado
    FROM CARROS
    WHERE CarroID = v_carro;

    IF v_estado <> 'Disponible' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Al anular, el carro no volvio a Disponible';
    END IF;

    SELECT COUNT(*) INTO v_n
    FROM VENTA
    WHERE VentaID = v_venta;

    IF v_n <> 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta de prueba siguio en VENTA';
    END IF;

    SELECT COUNT(*) INTO v_n
    FROM AUDITORIA
    WHERE Tabla = 'VENTA'
      AND Operacion = 'DELETE'
      AND Registro_ID = v_venta;

    IF v_n < 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La anulacion no quedo en AUDITORIA';
    END IF;

    DELETE FROM AUDITORIA
    WHERE Tabla = 'VENTA'
      AND Registro_ID = v_venta;

    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (
      13,
      'Venta, trigger, auditoria y anulacion',
      'vender, marcar Vendido, auditar, anular y devolver el carro',
      'PASO',
      LEFT(CONCAT('Carro ', v_carro, ', venta de prueba ', v_venta, '. Inventario y auditoria quedaron como antes.'), 255)
    );
  END;

  -- 14. Las tres vistas siguen coherentes con los datos de prueba.
  SELECT COUNT(*) INTO v_inventario FROM vw_inventario_disponible;
  SELECT COUNT(*) INTO v_disponibles FROM CARROS WHERE Estado_Inventario = 'Disponible';
  SELECT COUNT(*) INTO v_detalle_ventas FROM vw_detalle_ventas;
  SELECT COUNT(*) INTO v_sedes FROM vw_ventas_por_sede;

  IF v_inventario = v_disponibles AND v_detalle_ventas = 2 AND v_sedes = 3 THEN
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (
      14,
      'Vistas del concesionario',
      'inventario igual a los disponibles, 2 ventas y 3 sedes',
      'PASO',
      LEFT(CONCAT('Disponibles ', v_disponibles, ', detalle ', v_detalle_ventas, ', sedes ', v_sedes), 255)
    );
  ELSE
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (
      14,
      'Vistas del concesionario',
      'inventario igual a los disponibles, 2 ventas y 3 sedes',
      'FALLO',
      LEFT(CONCAT('Disponibles ', v_disponibles, ' vs vista ', v_inventario, '; detalle ', v_detalle_ventas, '; sedes ', v_sedes), 255)
    );
  END IF;

  -- 15. Los cuatro indices de 07_indices.sql siguen creados.
  SELECT COUNT(DISTINCT INDEX_NAME) INTO v_n
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = 'concesionario_db'
    AND INDEX_NAME IN (
      'idx_venta_fecha',
      'idx_carro_estado_marca',
      'idx_cliente_apellido',
      'idx_manto_fecha'
    );

  IF v_n = 4 THEN
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (15, 'Indices de 07_indices.sql', 'los cuatro indices presentes', 'PASO', 'idx_venta_fecha, idx_carro_estado_marca, idx_cliente_apellido, idx_manto_fecha');
  ELSE
    INSERT INTO resultado_pruebas_case (orden, prueba, esperado, resultado, detalle)
    VALUES (15, 'Indices de 07_indices.sql', 'los cuatro indices presentes', 'FALLO', CONCAT('Encontrados ', v_n, ' de 4'));
  END IF;
END$$

DELIMITER ;

CALL sp_ejecutar_pruebas_case();

SELECT orden, prueba, esperado, resultado, detalle
FROM resultado_pruebas_case
ORDER BY orden;

SELECT
  SUM(resultado = 'PASO') AS pasaron,
  SUM(resultado = 'FALLO') AS fallaron,
  COUNT(*) AS total
FROM resultado_pruebas_case;

-- El reporte que la pagina llama. Con los datos de prueba salen dos filas:
-- Corolla en Medellin (10 de mayo de 2026) y March en Cali (12 de mayo de 2026).
CALL sp_reporte_ventas('2026-01-01', '2026-12-31');

DROP PROCEDURE IF EXISTS sp_ejecutar_pruebas_case;
DROP TABLE IF EXISTS resultado_pruebas_case;
