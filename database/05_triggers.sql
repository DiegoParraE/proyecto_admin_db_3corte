-- Concesionario / concesionario_db
-- 05_triggers.sql
-- El trigger protege cualquier INSERT a VENTA (aplicacion, procedimiento o consola).
-- Se crea como root en la carga inicial, asi que corre con privilegios de root:
-- puede marcar el carro como Vendido aunque el vendedor no tenga UPDATE sobre CARROS.

USE concesionario_db;

DROP TRIGGER IF EXISTS trg_venta_before_insert;
DROP TRIGGER IF EXISTS trg_venta_after_insert;
DROP TRIGGER IF EXISTS trg_venta_after_delete;

DELIMITER $$

CREATE TRIGGER trg_venta_before_insert
BEFORE INSERT ON VENTA
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);

  SELECT Estado_Inventario
    INTO v_estado
  FROM CARROS
  WHERE CarroID = NEW.CarroID;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede vender un vehiculo que no existe';
  END IF;

  IF v_estado <> 'Disponible' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Trigger: el vehiculo no esta disponible para la venta';
  END IF;

  IF NEW.Monto_Total IS NULL OR NEW.Monto_Total <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El monto de la venta debe ser mayor que cero';
  END IF;
END$$

CREATE TRIGGER trg_venta_after_insert
AFTER INSERT ON VENTA
FOR EACH ROW
BEGIN
  UPDATE CARROS
     SET Estado_Inventario = 'Vendido'
   WHERE CarroID = NEW.CarroID;

  INSERT INTO AUDITORIA (Tabla, Operacion, Registro_ID, Usuario_DB, Detalle)
  VALUES (
    'VENTA',
    'INSERT',
    NEW.VentaID,
    USER(),
    CONCAT('Venta del carro ', NEW.CarroID, ' por ', NEW.Monto_Total, ' (', NEW.Forma_Pago, ')')
  );
END$$

CREATE TRIGGER trg_venta_after_delete
AFTER DELETE ON VENTA
FOR EACH ROW
BEGIN
  -- Un carro solo puede tener una venta (uk_venta_carro). No se consulta
  -- VENTA desde este trigger: MySQL no deja leer la misma tabla que disparo el evento.
  UPDATE CARROS
     SET Estado_Inventario = 'Disponible'
   WHERE CarroID = OLD.CarroID;

  INSERT INTO AUDITORIA (Tabla, Operacion, Registro_ID, Usuario_DB, Detalle)
  VALUES (
    'VENTA',
    'DELETE',
    OLD.VentaID,
    USER(),
    CONCAT('Se anulo la venta del carro ', OLD.CarroID, ' y volvio a inventario')
  );
END$$

DELIMITER ;
