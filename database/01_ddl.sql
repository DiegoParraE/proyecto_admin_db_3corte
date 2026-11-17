-- Concesionario / concesionario_db
-- 01_ddl.sql: estructura. Se ejecuta primero.
-- Conserva el modelo del dump (9 nov 2026) y agrega USUARIO (login de la app)
-- y AUDITORIA (la llena el trigger de ventas).
-- Los indices secundarios van en 07_indices.sql, no aqui.

CREATE DATABASE IF NOT EXISTS concesionario_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE concesionario_db;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS AUDITORIA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS MANTENIMIENTO;
DROP TABLE IF EXISTS VENTA;
DROP TABLE IF EXISTS CARRO_PROVEEDOR;
DROP TABLE IF EXISTS CARROS;
DROP TABLE IF EXISTS VENDEDOR;
DROP TABLE IF EXISTS CLIENTE;
DROP TABLE IF EXISTS PROVEEDOR;
DROP TABLE IF EXISTS SEDE;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE SEDE (
  SedeID INT NOT NULL AUTO_INCREMENT,
  Nombre_Sede VARCHAR(100) NOT NULL,
  Direccion VARCHAR(150) NOT NULL,
  Ciudad VARCHAR(100) NOT NULL,
  Telefono VARCHAR(20) NOT NULL,
  PRIMARY KEY (SedeID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CLIENTE (
  ClientID INT NOT NULL AUTO_INCREMENT,
  Nombre VARCHAR(50) NOT NULL,
  Apellido VARCHAR(50) NOT NULL,
  DNI VARCHAR(20) NOT NULL,
  Direccion VARCHAR(150) NULL,
  Telefono VARCHAR(20) NULL,
  PRIMARY KEY (ClientID),
  UNIQUE KEY uk_cliente_dni (DNI)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE PROVEEDOR (
  ProveedorID INT NOT NULL AUTO_INCREMENT,
  Nombre_Proveedor VARCHAR(100) NOT NULL,
  Contacto VARCHAR(100) NULL,
  Telefono VARCHAR(20) NULL,
  Direccion VARCHAR(150) NULL,
  PRIMARY KEY (ProveedorID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE VENDEDOR (
  VendedorID INT NOT NULL AUTO_INCREMENT,
  Nombre VARCHAR(50) NOT NULL,
  Apellido VARCHAR(50) NOT NULL,
  DNI VARCHAR(20) NOT NULL,
  Telefono VARCHAR(20) NULL,
  SedeID INT NOT NULL,
  PRIMARY KEY (VendedorID),
  UNIQUE KEY uk_vendedor_dni (DNI),
  CONSTRAINT fk_vendedor_sede FOREIGN KEY (SedeID) REFERENCES SEDE (SedeID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CARROS (
  CarroID INT NOT NULL AUTO_INCREMENT,
  VIN VARCHAR(50) NOT NULL,
  Marca VARCHAR(50) NOT NULL,
  Modelo VARCHAR(50) NOT NULL,
  Anio INT NOT NULL,
  SedeID INT NOT NULL,
  Precio_Venta DECIMAL(12,2) NOT NULL,
  Estado_Inventario VARCHAR(20) NOT NULL DEFAULT 'Disponible',
  PRIMARY KEY (CarroID),
  UNIQUE KEY uk_carro_vin (VIN),
  CONSTRAINT fk_carro_sede FOREIGN KEY (SedeID) REFERENCES SEDE (SedeID),
  CONSTRAINT chk_carro_anio CHECK (Anio BETWEEN 1980 AND 2100),
  CONSTRAINT chk_carro_precio CHECK (Precio_Venta > 0),
  CONSTRAINT chk_carro_estado CHECK (Estado_Inventario IN ('Disponible', 'Vendido'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CARRO_PROVEEDOR (
  CarroProveedorID INT NOT NULL AUTO_INCREMENT,
  CarroID INT NOT NULL,
  ProveedorID INT NOT NULL,
  Fecha_Compra_Prov DATE NOT NULL,
  Costo_Compra_Prov DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (CarroProveedorID),
  CONSTRAINT fk_cp_carro FOREIGN KEY (CarroID) REFERENCES CARROS (CarroID),
  CONSTRAINT fk_cp_proveedor FOREIGN KEY (ProveedorID) REFERENCES PROVEEDOR (ProveedorID),
  CONSTRAINT chk_cp_costo CHECK (Costo_Compra_Prov > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE VENTA (
  VentaID INT NOT NULL AUTO_INCREMENT,
  ClientID INT NOT NULL,
  VendedorID INT NOT NULL,
  CarroID INT NOT NULL,
  Fecha_Venta DATE NOT NULL,
  Monto_Total DECIMAL(12,2) NOT NULL,
  Forma_Pago VARCHAR(50) NOT NULL,
  PRIMARY KEY (VentaID),
  UNIQUE KEY uk_venta_carro (CarroID),
  CONSTRAINT fk_venta_cliente FOREIGN KEY (ClientID) REFERENCES CLIENTE (ClientID),
  CONSTRAINT fk_venta_vendedor FOREIGN KEY (VendedorID) REFERENCES VENDEDOR (VendedorID),
  CONSTRAINT fk_venta_carro FOREIGN KEY (CarroID) REFERENCES CARROS (CarroID),
  CONSTRAINT chk_venta_monto CHECK (Monto_Total > 0),
  CONSTRAINT chk_venta_pago CHECK (Forma_Pago IN ('Contado', 'Financiado', 'Tarjeta'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE MANTENIMIENTO (
  MantenimientoID INT NOT NULL AUTO_INCREMENT,
  CarroID INT NOT NULL,
  ClientID INT NULL,
  VendedorID INT NULL,
  Fecha_Servicio DATE NOT NULL,
  Descripcion_Servicio TEXT NOT NULL,
  Costo_Servicio DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (MantenimientoID),
  CONSTRAINT fk_manto_carro FOREIGN KEY (CarroID) REFERENCES CARROS (CarroID),
  CONSTRAINT fk_manto_cliente FOREIGN KEY (ClientID) REFERENCES CLIENTE (ClientID),
  CONSTRAINT fk_manto_vendedor FOREIGN KEY (VendedorID) REFERENCES VENDEDOR (VendedorID),
  CONSTRAINT chk_manto_costo CHECK (Costo_Servicio > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Credenciales de la aplicacion. El hash no es reversible.
-- Los usuarios de MySQL (admin, vendedor, consulta) estan en 06_usuarios.sql
-- y son otra capa: controlan quien entra al SGBD, no al formulario web.
CREATE TABLE USUARIO (
  UsuarioID INT NOT NULL AUTO_INCREMENT,
  Username VARCHAR(40) NOT NULL,
  Password_Hash VARCHAR(200) NOT NULL,
  Rol VARCHAR(20) NOT NULL,
  Nombre_Completo VARCHAR(100) NOT NULL,
  Activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (UsuarioID),
  UNIQUE KEY uk_usuario_username (Username),
  CONSTRAINT chk_usuario_rol CHECK (Rol IN ('ADMIN', 'VENDEDOR', 'CONSULTA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE AUDITORIA (
  AuditoriaID INT NOT NULL AUTO_INCREMENT,
  Tabla VARCHAR(40) NOT NULL,
  Operacion VARCHAR(20) NOT NULL,
  Registro_ID INT NULL,
  Usuario_DB VARCHAR(128) NOT NULL,
  Detalle VARCHAR(255) NOT NULL,
  Fecha_Hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (AuditoriaID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
