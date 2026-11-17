-- Concesionario / concesionario_db
-- 02_dml.sql: datos de prueba tomados del dump original, mas los tres
-- usuarios de la aplicacion. Las claves web estan hasheadas (PBKDF2-SHA256).

USE concesionario_db;
SET NAMES utf8mb4;

INSERT INTO SEDE (SedeID, Nombre_Sede, Direccion, Ciudad, Telefono) VALUES
  (1, 'Bogotá', 'Calle 100 # 15-30', 'Bogotá', '6011234567'),
  (2, 'Medellín', 'Carrera 43A # 1-50', 'Medellín', '6043124567'),
  (3, 'Cali', 'Avenida 6N # 25-40', 'Cali', '6025550199');

INSERT INTO CLIENTE (ClientID, Nombre, Apellido, DNI, Direccion, Telefono) VALUES
  (1, 'Andres', 'Gomez', '1020304050', 'Calle 10 # 20-30', '3201112233'),
  (2, 'Diana', 'Torres', '1020304051', 'Calle 12 # 22-32', '3202223344'),
  (3, 'Felipe', 'Rojas', '1020304052', 'Calle 15 # 25-35', '3203334455'),
  (4, 'Camila', 'Vargas', '1020304053', 'Calle 18 # 28-38', '3204445566'),
  (5, 'Jorge', 'Mendoza', '1020304054', 'Calle 20 # 30-40', '3205556677'),
  (6, 'Lucia', 'Silva', '1020304055', 'Calle 22 # 32-42', '3206667788'),
  (7, 'Mateo', 'Castro', '1020304056', 'Calle 25 # 35-45', '3207778899'),
  (8, 'Valeria', 'Rios', '1020304057', 'Calle 28 # 38-48', '3208889900'),
  (9, 'Esteban', 'Pinto', '1020304058', 'Calle 30 # 40-50', '3209990011'),
  (10, 'Natalia', 'Cruz', '1020304059', 'Calle 35 # 45-55', '3200001122'),
  (11, 'Sara', 'Herrera', '1020304060', 'Carrera 7 # 12-10', '3211001100'),
  (12, 'Daniel', 'Moreno', '1020304061', 'Carrera 15 # 40-20', '3211002200'),
  (13, 'Paula', 'Reyes', '1020304062', 'Calle 45 # 18-12', '3211003300'),
  (14, 'Nicolas', 'Suarez', '1020304063', 'Calle 53 # 22-08', '3211004400'),
  (15, 'Laura', 'Pardo', '1020304064', 'Carrera 30 # 50-14', '3211005500'),
  (16, 'Sebastian', 'Ortiz', '1020304065', 'Calle 72 # 10-25', '3211006600'),
  (17, 'Mariana', 'Cortes', '1020304066', 'Avenida 68 # 40-30', '3211007700'),
  (18, 'Tomas', 'Guerrero', '1020304067', 'Calle 80 # 25-16', '3211008800'),
  (19, 'Isabella', 'Navarro', '1020304068', 'Carrera 50 # 60-22', '3211009900'),
  (20, 'Samuel', 'Vega', '1020304069', 'Calle 100 # 19-40', '3211010011');

INSERT INTO PROVEEDOR (ProveedorID, Nombre_Proveedor, Contacto, Telefono, Direccion) VALUES
  (1, 'AutoImport S.A.S.', 'Carlos Mesa', '6019876543', 'Zona Industrial Bogota'),
  (2, 'Motores Globales', 'Sofia Castro', '6018765432', 'Calle 80 # 70-10');

INSERT INTO VENDEDOR (VendedorID, Nombre, Apellido, DNI, Telefono, SedeID) VALUES
  (1, 'Pedro', 'Perez', '1001234561', '3101111111', 1),
  (2, 'Maria', 'Lopez', '1001234562', '3102222222', 2),
  (3, 'Juan', 'Ramirez', '1001234563', '3103333333', 3);

INSERT INTO CARROS (CarroID, VIN, Marca, Modelo, Anio, SedeID, Precio_Venta, Estado_Inventario) VALUES
  (1, 'CHS10001ABC', 'Chevrolet', 'Onix', 2023, 1, 65000000.00, 'Disponible'),
  (2, 'CHS10002ABC', 'Renault', 'Sandero', 2022, 2, 55000000.00, 'Disponible'),
  (3, 'CHS10003ABC', 'Mazda', 'Mazda 3', 2024, 3, 90000000.00, 'Disponible'),
  (4, 'CHS10004ABC', 'Kia', 'Picanto', 2023, 1, 48000000.00, 'Disponible'),
  (5, 'CHS10005ABC', 'Toyota', 'Corolla', 2024, 2, 105000000.00, 'Vendido'),
  (6, 'CHS10006ABC', 'Nissan', 'March', 2021, 3, 45000000.00, 'Vendido'),
  (7, 'CHS10007ABC', 'Volkswagen', 'Gol', 2022, 1, 52000000.00, 'Disponible'),
  (8, 'CHS10008ABC', 'Ford', 'Fiesta', 2020, 2, 42000000.00, 'Disponible'),
  (9, 'CHS10009ABC', 'Chevrolet', 'Tracker', 2024, 3, 98000000.00, 'Disponible'),
  (10, 'CHS10010ABC', 'Renault', 'Duster', 2023, 1, 89000000.00, 'Disponible'),
  (11, 'CHS10011ABC', 'Mazda', 'CX-30', 2024, 2, 120000000.00, 'Disponible'),
  (12, 'CHS10012ABC', 'Kia', 'Sportage', 2022, 3, 115000000.00, 'Disponible'),
  (13, 'CHS10013ABC', 'Toyota', 'Yaris', 2023, 1, 78000000.00, 'Disponible'),
  (14, 'CHS10014ABC', 'Nissan', 'Versa', 2022, 2, 72000000.00, 'Disponible'),
  (15, 'CHS10015ABC', 'Volkswagen', 'T-Cross', 2024, 3, 99000000.00, 'Disponible'),
  (16, 'CHS10016ABC', 'Ford', 'Escape', 2021, 1, 110000000.00, 'Disponible'),
  (17, 'CHS10017ABC', 'Chevrolet', 'Spark', 2020, 2, 42000000.00, 'Disponible'),
  (18, 'CHS10018ABC', 'Renault', 'Logan', 2021, 3, 51000000.00, 'Disponible'),
  (19, 'CHS10019ABC', 'Mazda', 'Mazda 2', 2023, 1, 76000000.00, 'Disponible'),
  (20, 'CHS10020ABC', 'Kia', 'Rio', 2022, 2, 68000000.00, 'Disponible');

INSERT INTO CARRO_PROVEEDOR (CarroProveedorID, CarroID, ProveedorID, Fecha_Compra_Prov, Costo_Compra_Prov) VALUES
  (1, 1, 1, '2023-01-10', 58000000.00),
  (2, 2, 1, '2023-02-15', 49000000.00),
  (3, 3, 2, '2024-03-01', 82000000.00),
  (4, 4, 2, '2023-04-12', 42000000.00);

INSERT INTO VENTA (VentaID, ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago) VALUES
  (1, 1, 1, 5, '2026-05-10', 105000000.00, 'Financiado'),
  (2, 2, 2, 6, '2026-05-12', 45000000.00, 'Contado');

INSERT INTO MANTENIMIENTO (MantenimientoID, CarroID, ClientID, VendedorID, Fecha_Servicio, Descripcion_Servicio, Costo_Servicio) VALUES
  (1, 1, 1, 1, '2026-06-01', 'Revision de 5000 km y cambio de aceite', 180000.00);

-- Claves de prueba de la aplicacion (no son los usuarios de MySQL):
--   admin / admin123
--   vendedor / vendedor123
--   consulta / consulta123
INSERT INTO USUARIO (UsuarioID, Username, Password_Hash, Rol, Nombre_Completo, Activo) VALUES
  (1, 'admin', 'pbkdf2_sha256$260000$sigcon-admin$563befe9de0a58d78ff2df19208f16f1bb1a98650848ab9d564c39eb1b376a61', 'ADMIN', 'Ana Administradora', 1),
  (2, 'vendedor', 'pbkdf2_sha256$260000$sigcon-vendedor$fbfd0d36afcae47523771d416e90a6c15c57b02292858b0822c39849307c7166', 'VENDEDOR', 'Pedro Perez', 1),
  (3, 'consulta', 'pbkdf2_sha256$260000$sigcon-consulta$c99efca73fdef2e45381fdd59f6a936b5875a2dc73a826f11ddbf549ca18b84c', 'CONSULTA', 'Laura Consulta', 1);

ALTER TABLE SEDE AUTO_INCREMENT = 4;
ALTER TABLE CLIENTE AUTO_INCREMENT = 21;
ALTER TABLE PROVEEDOR AUTO_INCREMENT = 3;
ALTER TABLE VENDEDOR AUTO_INCREMENT = 4;
ALTER TABLE CARROS AUTO_INCREMENT = 21;
ALTER TABLE CARRO_PROVEEDOR AUTO_INCREMENT = 5;
ALTER TABLE VENTA AUTO_INCREMENT = 3;
ALTER TABLE MANTENIMIENTO AUTO_INCREMENT = 2;
ALTER TABLE USUARIO AUTO_INCREMENT = 4;
