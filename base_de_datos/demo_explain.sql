-- Comparacion EXPLAIN para la sustentacion (2 minutos).
-- Con 2 ventas MySQL suele elegir recorrido completo: leer una pagina sale
-- mas barato que usar el indice. Por eso la comparacion visible se hace sobre
-- una tabla de laboratorio con la misma forma de consulta (fecha = constante),
-- 5000 filas, y se borra al final.
--
-- Uso, desde la raiz del repo:
--   ./base_de_datos/demo_explain.sh

USE concesionario_db;
SET NAMES utf8mb4;
SET SESSION cte_max_recursion_depth = 10000;

SELECT '1. Consulta real del reporte, con el indice idx_venta_fecha ya creado' AS paso;
EXPLAIN SELECT VentaID, Monto_Total
FROM VENTA
WHERE Fecha_Venta BETWEEN '2026-01-01' AND '2026-12-31';

DROP TABLE IF EXISTS DEMO_BUSQUEDA;
CREATE TABLE DEMO_BUSQUEDA (
  id INT NOT NULL AUTO_INCREMENT,
  fecha DATE NOT NULL,
  sede_id INT NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO DEMO_BUSQUEDA (fecha, sede_id, monto)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT
  DATE_ADD('2023-01-01', INTERVAL (n MOD 900) DAY),
  (n MOD 2) + 1,
  20000000 + (n * 1500)
FROM seq;

ANALYZE TABLE DEMO_BUSQUEDA;

SELECT '2. ANTES del indice: type debe ser ALL y key NULL' AS paso;
EXPLAIN SELECT id, monto
FROM DEMO_BUSQUEDA
WHERE fecha = '2023-06-01';

CREATE INDEX idx_demo_fecha ON DEMO_BUSQUEDA (fecha);
ANALYZE TABLE DEMO_BUSQUEDA;

SELECT '3. DESPUES del indice: type debe ser ref y key idx_demo_fecha' AS paso;
EXPLAIN SELECT id, monto
FROM DEMO_BUSQUEDA
WHERE fecha = '2023-06-01';

DROP TABLE DEMO_BUSQUEDA;
SELECT 'Tabla de laboratorio eliminada. El esquema de negocio no cambio.' AS paso;
