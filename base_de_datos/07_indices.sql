-- Concesionario / concesionario_db
-- 07_indices.sql
-- Indices que el analisis dejo. No se repiten los que ya crean PRIMARY KEY,
-- UNIQUE o las llaves foraneas (InnoDB indexa la columna de cada FK).
--
-- Descartados a proposito:
--   CLIENTE(DNI) y CARROS(VIN) y VENTA(CarroID): ya son UNIQUE.
--   AUDITORIA(Fecha_Hora): el autoincremental sigue el orden de insercion;
--   "los ultimos eventos" se resuelve con ORDER BY AuditoriaID.
--
-- Orden de idx_carro_estado_marca: Estado va primero porque la pantalla de
-- inventario filtra por estado aunque no indiquen marca. El prefijo izquierdo
-- de un indice compuesto tiene que ser la columna que la consulta iguala sola.

USE concesionario_db;

-- Rango de fechas del procedimiento sp_reporte_ventas y del reporte web.
CREATE INDEX idx_venta_fecha ON VENTA (Fecha_Venta);

-- Inventario: WHERE Estado_Inventario = ? AND Marca = ?
CREATE INDEX idx_carro_estado_marca ON CARROS (Estado_Inventario, Marca);

-- Busqueda de clientes por prefijo de apellido (LIKE 'Gom%').
CREATE INDEX idx_cliente_apellido ON CLIENTE (Apellido);

-- Historial de servicio por fecha.
CREATE INDEX idx_manto_fecha ON MANTENIMIENTO (Fecha_Servicio);
