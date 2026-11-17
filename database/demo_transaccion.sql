-- Transaccion explicita para la sustentacion.
-- Fuera de un procedimiento, BEGIN es alias de START TRANSACTION.
-- Uso: ./database/demo_transaccion.sh

USE concesionario_db;

SELECT COUNT(*) AS clientes_antes FROM CLIENTE;

BEGIN;
INSERT INTO CLIENTE (Nombre, Apellido, DNI)
VALUES ('Rollback', 'Prueba', '000ROLLBACK');
ROLLBACK;

SELECT COUNT(*) AS clientes_despues_del_rollback
FROM CLIENTE
WHERE DNI = '000ROLLBACK';
