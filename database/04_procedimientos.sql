-- Concesionario / concesionario_db
-- 04_procedimientos.sql
-- sp_registrar_venta: vende dentro de una transaccion. El trigger actualiza el inventario.
-- sp_reporte_ventas: el reporte de la aplicacion llama este procedimiento.
-- sp_anular_venta: borra la venta con COMMIT, o ROLLBACK si no existe.

USE concesionario_db;

DROP PROCEDURE IF EXISTS sp_registrar_venta;
DROP PROCEDURE IF EXISTS sp_reporte_ventas;
DROP PROCEDURE IF EXISTS sp_anular_venta;

DELIMITER $$

CREATE PROCEDURE sp_registrar_venta(
  IN p_client_id INT,
  IN p_vendedor_id INT,
  IN p_carro_id INT,
  IN p_forma_pago VARCHAR(50)
)
SQL SECURITY INVOKER
BEGIN
  DECLARE v_precio DECIMAL(12,2);
  DECLARE v_estado VARCHAR(20);

  -- Dentro de un procedimiento BEGIN abre el bloque, no la transaccion.
  -- START TRANSACTION es el BEGIN de la transaccion. Si el trigger o un
  -- SIGNAL fallan, el handler hace ROLLBACK y no queda una venta a medias.
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  IF p_forma_pago NOT IN ('Contado', 'Financiado', 'Tarjeta') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Forma de pago no valida. Use Contado, Financiado o Tarjeta';
  END IF;

  -- Sin FOR UPDATE: con SQL SECURITY INVOKER ese bloqueo exigiria
  -- privilegio UPDATE sobre CARROS, y el vendedor no lo tiene.
  -- La unicidad de VENTA.CarroID y el trigger BEFORE cierran la doble venta.
  SELECT Precio_Venta, Estado_Inventario
    INTO v_precio, v_estado
  FROM CARROS
  WHERE CarroID = p_carro_id;

  IF v_precio IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El vehiculo no existe';
  END IF;

  IF v_estado <> 'Disponible' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El vehiculo no esta disponible para la venta';
  END IF;

  INSERT INTO VENTA (ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago)
  VALUES (p_client_id, p_vendedor_id, p_carro_id, CURDATE(), v_precio, p_forma_pago);
  COMMIT;
END$$

CREATE PROCEDURE sp_anular_venta(IN p_venta_id INT)
SQL SECURITY INVOKER
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM VENTA WHERE VentaID = p_venta_id;

  IF ROW_COUNT() = 0 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La venta no existe';
  END IF;

  COMMIT;
END$$

CREATE PROCEDURE sp_reporte_ventas(
  IN p_desde DATE,
  IN p_hasta DATE
)
SQL SECURITY INVOKER
BEGIN
  SELECT
    v.VentaID,
    CONCAT(cl.Nombre, ' ', cl.Apellido) AS Cliente,
    CONCAT(ve.Nombre, ' ', ve.Apellido) AS Vendedor,
    ca.Marca,
    ca.Modelo,
    ca.Anio,
    v.Monto_Total,
    v.Forma_Pago,
    v.Fecha_Venta,
    se.Nombre_Sede AS Sede
  FROM VENTA v
  JOIN CLIENTE cl ON cl.ClientID = v.ClientID
  JOIN VENDEDOR ve ON ve.VendedorID = v.VendedorID
  JOIN CARROS ca ON ca.CarroID = v.CarroID
  JOIN SEDE se ON se.SedeID = ca.SedeID
  WHERE v.Fecha_Venta BETWEEN p_desde AND p_hasta
  ORDER BY v.Fecha_Venta, v.VentaID;
END$$

DELIMITER ;
