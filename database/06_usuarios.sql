-- Concesionario / concesionario_db
-- 06_usuarios.sql
-- Cuentas del SGBD. No son los mismos usuarios del formulario web.
-- Host '%': entran por TCP (la app y `mysql -h 127.0.0.1`).
-- En MySQL, localhost por socket NO coincide con '%'.
-- Las claves de abajo son de la practica academica.

USE concesionario_db;

DROP USER IF EXISTS 'auth_concesionario'@'%';
DROP USER IF EXISTS 'admin_concesionario'@'%';
DROP USER IF EXISTS 'vendedor_concesionario'@'%';
DROP USER IF EXISTS 'consulta_concesionario'@'%';

CREATE USER 'auth_concesionario'@'%' IDENTIFIED BY 'Auth#2026';
CREATE USER 'admin_concesionario'@'%' IDENTIFIED BY 'Admin#2026';
CREATE USER 'vendedor_concesionario'@'%' IDENTIFIED BY 'Vendedor#2026';
CREATE USER 'consulta_concesionario'@'%' IDENTIFIED BY 'Consulta#2026';

-- Solo puede leer la tabla de login. No ve ventas ni inventario.
GRANT SELECT ON concesionario_db.USUARIO TO 'auth_concesionario'@'%';

-- Administracion de esta base. No es superusuario del servidor.
GRANT ALL PRIVILEGES ON concesionario_db.* TO 'admin_concesionario'@'%';

-- Vendedor: lee el negocio, crea clientes, ventas y mantenimientos.
-- No borra, no cambia el precio de una venta y no lee hashes ni auditoria.
GRANT SELECT ON concesionario_db.SEDE TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.CLIENTE TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.VENDEDOR TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.PROVEEDOR TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.CARROS TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.CARRO_PROVEEDOR TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.VENTA TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.MANTENIMIENTO TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_detalle_ventas TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_inventario_disponible TO 'vendedor_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_ventas_por_sede TO 'vendedor_concesionario'@'%';
GRANT INSERT, UPDATE ON concesionario_db.CLIENTE TO 'vendedor_concesionario'@'%';
GRANT INSERT ON concesionario_db.VENTA TO 'vendedor_concesionario'@'%';
GRANT INSERT ON concesionario_db.MANTENIMIENTO TO 'vendedor_concesionario'@'%';
GRANT EXECUTE ON PROCEDURE concesionario_db.sp_registrar_venta TO 'vendedor_concesionario'@'%';
GRANT EXECUTE ON PROCEDURE concesionario_db.sp_reporte_ventas TO 'vendedor_concesionario'@'%';

-- Evidencia de REVOKE: se concede DELETE y anular ventas, y se quita.
-- Despues de estas dos lineas el vendedor queda como arriba: no borra.
GRANT DELETE ON concesionario_db.VENTA TO 'vendedor_concesionario'@'%';
GRANT EXECUTE ON PROCEDURE concesionario_db.sp_anular_venta TO 'vendedor_concesionario'@'%';
REVOKE DELETE ON concesionario_db.VENTA FROM 'vendedor_concesionario'@'%';
REVOKE EXECUTE ON PROCEDURE concesionario_db.sp_anular_venta FROM 'vendedor_concesionario'@'%';

-- Consulta: solo lectura y el reporte. El INSERT debe fallar en la sustentacion.
GRANT SELECT ON concesionario_db.SEDE TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.CLIENTE TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.VENDEDOR TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.PROVEEDOR TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.CARROS TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.CARRO_PROVEEDOR TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.VENTA TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.MANTENIMIENTO TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_detalle_ventas TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_inventario_disponible TO 'consulta_concesionario'@'%';
GRANT SELECT ON concesionario_db.vw_ventas_por_sede TO 'consulta_concesionario'@'%';
GRANT EXECUTE ON PROCEDURE concesionario_db.sp_reporte_ventas TO 'consulta_concesionario'@'%';

FLUSH PRIVILEGES;
