-- Concesionario / concesionario_db
-- 03_vistas.sql
-- SQL SECURITY INVOKER: la vista se ejecuta con los permisos de quien consulta,
-- no con los de root. Si el usuario no puede leer la tabla base, tampoco ve la vista.

USE concesionario_db;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_detalle_ventas AS
SELECT
  v.VentaID AS VentaID,
  CONCAT(c.Nombre, ' ', c.Apellido) AS Cliente,
  CONCAT(ven.Nombre, ' ', ven.Apellido) AS Vendedor,
  car.Marca AS Marca,
  car.Modelo AS Modelo,
  car.Anio AS Anio,
  v.Monto_Total AS Monto_Total,
  v.Forma_Pago AS Forma_Pago,
  v.Fecha_Venta AS Fecha_Venta,
  s.Nombre_Sede AS Sede
FROM VENTA v
JOIN CLIENTE c ON v.ClientID = c.ClientID
JOIN VENDEDOR ven ON v.VendedorID = ven.VendedorID
JOIN CARROS car ON v.CarroID = car.CarroID
JOIN SEDE s ON car.SedeID = s.SedeID;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_inventario_disponible AS
SELECT
  c.CarroID,
  c.VIN,
  c.Marca,
  c.Modelo,
  c.Anio,
  c.Precio_Venta,
  s.Nombre_Sede,
  s.Ciudad
FROM CARROS c
JOIN SEDE s ON s.SedeID = c.SedeID
WHERE c.Estado_Inventario = 'Disponible';

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_ventas_por_sede AS
SELECT
  s.SedeID,
  s.Nombre_Sede,
  s.Ciudad,
  COUNT(v.VentaID) AS Cantidad_Ventas,
  COALESCE(SUM(v.Monto_Total), 0) AS Total_Vendido
FROM SEDE s
LEFT JOIN CARROS c ON c.SedeID = s.SedeID
LEFT JOIN VENTA v ON v.CarroID = c.CarroID
GROUP BY s.SedeID, s.Nombre_Sede, s.Ciudad;
