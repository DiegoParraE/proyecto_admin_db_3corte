-- Backup logico de concesionario_db para la sustentacion.
-- Generado con base_de_datos/generar_backup.sh (mysqldump --routines --triggers).
-- Restaurar: ./base_de_datos/demo_backup.sh --confirmar

-- MySQL dump 10.13  Distrib 8.4.13, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: concesionario_db
-- ------------------------------------------------------
-- Server version	8.4.13

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `concesionario_db`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `concesionario_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `concesionario_db`;

--
-- Table structure for table `AUDITORIA`
--

DROP TABLE IF EXISTS `AUDITORIA`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AUDITORIA` (
  `AuditoriaID` int NOT NULL AUTO_INCREMENT,
  `Tabla` varchar(40) NOT NULL,
  `Operacion` varchar(20) NOT NULL,
  `Registro_ID` int DEFAULT NULL,
  `Usuario_DB` varchar(128) NOT NULL,
  `Detalle` varchar(255) NOT NULL,
  `Fecha_Hora` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`AuditoriaID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AUDITORIA`
--

LOCK TABLES `AUDITORIA` WRITE;
/*!40000 ALTER TABLE `AUDITORIA` DISABLE KEYS */;
/*!40000 ALTER TABLE `AUDITORIA` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CARROS`
--

DROP TABLE IF EXISTS `CARROS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CARROS` (
  `CarroID` int NOT NULL AUTO_INCREMENT,
  `VIN` varchar(50) NOT NULL,
  `Marca` varchar(50) NOT NULL,
  `Modelo` varchar(50) NOT NULL,
  `Anio` int NOT NULL,
  `SedeID` int NOT NULL,
  `Precio_Venta` decimal(12,2) NOT NULL,
  `Estado_Inventario` varchar(20) NOT NULL DEFAULT 'Disponible',
  PRIMARY KEY (`CarroID`),
  UNIQUE KEY `uk_carro_vin` (`VIN`),
  KEY `fk_carro_sede` (`SedeID`),
  KEY `idx_carro_estado_marca` (`Estado_Inventario`,`Marca`),
  CONSTRAINT `fk_carro_sede` FOREIGN KEY (`SedeID`) REFERENCES `SEDE` (`SedeID`),
  CONSTRAINT `chk_carro_anio` CHECK ((`Anio` between 1980 and 2100)),
  CONSTRAINT `chk_carro_estado` CHECK ((`Estado_Inventario` in (_utf8mb4'Disponible',_utf8mb4'Vendido'))),
  CONSTRAINT `chk_carro_precio` CHECK ((`Precio_Venta` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CARROS`
--

LOCK TABLES `CARROS` WRITE;
/*!40000 ALTER TABLE `CARROS` DISABLE KEYS */;
INSERT INTO `CARROS` VALUES (1,'CHS10001ABC','Chevrolet','Onix',2023,1,65000000.00,'Disponible'),(2,'CHS10002ABC','Renault','Sandero',2022,2,55000000.00,'Disponible'),(3,'CHS10003ABC','Mazda','Mazda 3',2024,3,90000000.00,'Disponible'),(4,'CHS10004ABC','Kia','Picanto',2023,1,48000000.00,'Disponible'),(5,'CHS10005ABC','Toyota','Corolla',2024,2,105000000.00,'Vendido'),(6,'CHS10006ABC','Nissan','March',2021,3,45000000.00,'Vendido'),(7,'CHS10007ABC','Volkswagen','Gol',2022,1,52000000.00,'Disponible'),(8,'CHS10008ABC','Ford','Fiesta',2020,2,42000000.00,'Disponible'),(9,'CHS10009ABC','Chevrolet','Tracker',2024,3,98000000.00,'Disponible'),(10,'CHS10010ABC','Renault','Duster',2023,1,89000000.00,'Disponible'),(11,'CHS10011ABC','Mazda','CX-30',2024,2,120000000.00,'Disponible'),(12,'CHS10012ABC','Kia','Sportage',2022,3,115000000.00,'Disponible'),(13,'CHS10013ABC','Toyota','Yaris',2023,1,78000000.00,'Disponible'),(14,'CHS10014ABC','Nissan','Versa',2022,2,72000000.00,'Disponible'),(15,'CHS10015ABC','Volkswagen','T-Cross',2024,3,99000000.00,'Disponible'),(16,'CHS10016ABC','Ford','Escape',2021,1,110000000.00,'Disponible'),(17,'CHS10017ABC','Chevrolet','Spark',2020,2,42000000.00,'Disponible'),(18,'CHS10018ABC','Renault','Logan',2021,3,51000000.00,'Disponible'),(19,'CHS10019ABC','Mazda','Mazda 2',2023,1,76000000.00,'Disponible'),(20,'CHS10020ABC','Kia','Rio',2022,2,68000000.00,'Disponible');
/*!40000 ALTER TABLE `CARROS` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CARRO_PROVEEDOR`
--

DROP TABLE IF EXISTS `CARRO_PROVEEDOR`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CARRO_PROVEEDOR` (
  `CarroProveedorID` int NOT NULL AUTO_INCREMENT,
  `CarroID` int NOT NULL,
  `ProveedorID` int NOT NULL,
  `Fecha_Compra_Prov` date NOT NULL,
  `Costo_Compra_Prov` decimal(12,2) NOT NULL,
  PRIMARY KEY (`CarroProveedorID`),
  KEY `fk_cp_carro` (`CarroID`),
  KEY `fk_cp_proveedor` (`ProveedorID`),
  CONSTRAINT `fk_cp_carro` FOREIGN KEY (`CarroID`) REFERENCES `CARROS` (`CarroID`),
  CONSTRAINT `fk_cp_proveedor` FOREIGN KEY (`ProveedorID`) REFERENCES `PROVEEDOR` (`ProveedorID`),
  CONSTRAINT `chk_cp_costo` CHECK ((`Costo_Compra_Prov` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CARRO_PROVEEDOR`
--

LOCK TABLES `CARRO_PROVEEDOR` WRITE;
/*!40000 ALTER TABLE `CARRO_PROVEEDOR` DISABLE KEYS */;
INSERT INTO `CARRO_PROVEEDOR` VALUES (1,1,1,'2023-01-10',58000000.00),(2,2,1,'2023-02-15',49000000.00),(3,3,2,'2024-03-01',82000000.00),(4,4,2,'2023-04-12',42000000.00);
/*!40000 ALTER TABLE `CARRO_PROVEEDOR` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CLIENTE`
--

DROP TABLE IF EXISTS `CLIENTE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CLIENTE` (
  `ClientID` int NOT NULL AUTO_INCREMENT,
  `Nombre` varchar(50) NOT NULL,
  `Apellido` varchar(50) NOT NULL,
  `DNI` varchar(20) NOT NULL,
  `Direccion` varchar(150) DEFAULT NULL,
  `Telefono` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`ClientID`),
  UNIQUE KEY `uk_cliente_dni` (`DNI`),
  KEY `idx_cliente_apellido` (`Apellido`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CLIENTE`
--

LOCK TABLES `CLIENTE` WRITE;
/*!40000 ALTER TABLE `CLIENTE` DISABLE KEYS */;
INSERT INTO `CLIENTE` VALUES (1,'Andres','Gomez','1020304050','Calle 10 # 20-30','3201112233'),(2,'Diana','Torres','1020304051','Calle 12 # 22-32','3202223344'),(3,'Felipe','Rojas','1020304052','Calle 15 # 25-35','3203334455'),(4,'Camila','Vargas','1020304053','Calle 18 # 28-38','3204445566'),(5,'Jorge','Mendoza','1020304054','Calle 20 # 30-40','3205556677'),(6,'Lucia','Silva','1020304055','Calle 22 # 32-42','3206667788'),(7,'Mateo','Castro','1020304056','Calle 25 # 35-45','3207778899'),(8,'Valeria','Rios','1020304057','Calle 28 # 38-48','3208889900'),(9,'Esteban','Pinto','1020304058','Calle 30 # 40-50','3209990011'),(10,'Natalia','Cruz','1020304059','Calle 35 # 45-55','3200001122'),(11,'Sara','Herrera','1020304060','Carrera 7 # 12-10','3211001100'),(12,'Daniel','Moreno','1020304061','Carrera 15 # 40-20','3211002200'),(13,'Paula','Reyes','1020304062','Calle 45 # 18-12','3211003300'),(14,'Nicolas','Suarez','1020304063','Calle 53 # 22-08','3211004400'),(15,'Laura','Pardo','1020304064','Carrera 30 # 50-14','3211005500'),(16,'Sebastian','Ortiz','1020304065','Calle 72 # 10-25','3211006600'),(17,'Mariana','Cortes','1020304066','Avenida 68 # 40-30','3211007700'),(18,'Tomas','Guerrero','1020304067','Calle 80 # 25-16','3211008800'),(19,'Isabella','Navarro','1020304068','Carrera 50 # 60-22','3211009900'),(20,'Samuel','Vega','1020304069','Calle 100 # 19-40','3211010011');
/*!40000 ALTER TABLE `CLIENTE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `MANTENIMIENTO`
--

DROP TABLE IF EXISTS `MANTENIMIENTO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MANTENIMIENTO` (
  `MantenimientoID` int NOT NULL AUTO_INCREMENT,
  `CarroID` int NOT NULL,
  `ClientID` int DEFAULT NULL,
  `VendedorID` int DEFAULT NULL,
  `Fecha_Servicio` date NOT NULL,
  `Descripcion_Servicio` text NOT NULL,
  `Costo_Servicio` decimal(10,2) NOT NULL,
  PRIMARY KEY (`MantenimientoID`),
  KEY `fk_manto_carro` (`CarroID`),
  KEY `fk_manto_cliente` (`ClientID`),
  KEY `fk_manto_vendedor` (`VendedorID`),
  KEY `idx_manto_fecha` (`Fecha_Servicio`),
  CONSTRAINT `fk_manto_carro` FOREIGN KEY (`CarroID`) REFERENCES `CARROS` (`CarroID`),
  CONSTRAINT `fk_manto_cliente` FOREIGN KEY (`ClientID`) REFERENCES `CLIENTE` (`ClientID`),
  CONSTRAINT `fk_manto_vendedor` FOREIGN KEY (`VendedorID`) REFERENCES `VENDEDOR` (`VendedorID`),
  CONSTRAINT `chk_manto_costo` CHECK ((`Costo_Servicio` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `MANTENIMIENTO`
--

LOCK TABLES `MANTENIMIENTO` WRITE;
/*!40000 ALTER TABLE `MANTENIMIENTO` DISABLE KEYS */;
INSERT INTO `MANTENIMIENTO` VALUES (1,1,1,1,'2026-06-01','Revision de 5000 km y cambio de aceite',180000.00);
/*!40000 ALTER TABLE `MANTENIMIENTO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PROVEEDOR`
--

DROP TABLE IF EXISTS `PROVEEDOR`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PROVEEDOR` (
  `ProveedorID` int NOT NULL AUTO_INCREMENT,
  `Nombre_Proveedor` varchar(100) NOT NULL,
  `Contacto` varchar(100) DEFAULT NULL,
  `Telefono` varchar(20) DEFAULT NULL,
  `Direccion` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`ProveedorID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PROVEEDOR`
--

LOCK TABLES `PROVEEDOR` WRITE;
/*!40000 ALTER TABLE `PROVEEDOR` DISABLE KEYS */;
INSERT INTO `PROVEEDOR` VALUES (1,'AutoImport S.A.S.','Carlos Mesa','6019876543','Zona Industrial Bogota'),(2,'Motores Globales','Sofia Castro','6018765432','Calle 80 # 70-10');
/*!40000 ALTER TABLE `PROVEEDOR` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `SEDE`
--

DROP TABLE IF EXISTS `SEDE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SEDE` (
  `SedeID` int NOT NULL AUTO_INCREMENT,
  `Nombre_Sede` varchar(100) NOT NULL,
  `Direccion` varchar(150) NOT NULL,
  `Ciudad` varchar(100) NOT NULL,
  `Telefono` varchar(20) NOT NULL,
  PRIMARY KEY (`SedeID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `SEDE`
--

LOCK TABLES `SEDE` WRITE;
/*!40000 ALTER TABLE `SEDE` DISABLE KEYS */;
INSERT INTO `SEDE` VALUES (1,'Bogotá','Calle 100 # 15-30','Bogotá','6011234567'),(2,'Medellín','Carrera 43A # 1-50','Medellín','6043124567'),(3,'Cali','Avenida 6N # 25-40','Cali','6025550199');
/*!40000 ALTER TABLE `SEDE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `USUARIO`
--

DROP TABLE IF EXISTS `USUARIO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `USUARIO` (
  `UsuarioID` int NOT NULL AUTO_INCREMENT,
  `Username` varchar(40) NOT NULL,
  `Password_Hash` varchar(200) NOT NULL,
  `Rol` varchar(20) NOT NULL,
  `Nombre_Completo` varchar(100) NOT NULL,
  `Activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`UsuarioID`),
  UNIQUE KEY `uk_usuario_username` (`Username`),
  CONSTRAINT `chk_usuario_rol` CHECK ((`Rol` in (_utf8mb4'ADMIN',_utf8mb4'VENDEDOR',_utf8mb4'CONSULTA')))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `USUARIO`
--

LOCK TABLES `USUARIO` WRITE;
/*!40000 ALTER TABLE `USUARIO` DISABLE KEYS */;
INSERT INTO `USUARIO` VALUES (1,'admin','pbkdf2_sha256$260000$sigcon-admin$563befe9de0a58d78ff2df19208f16f1bb1a98650848ab9d564c39eb1b376a61','ADMIN','Ana Administradora',1),(2,'vendedor','pbkdf2_sha256$260000$sigcon-vendedor$fbfd0d36afcae47523771d416e90a6c15c57b02292858b0822c39849307c7166','VENDEDOR','Pedro Perez',1),(3,'consulta','pbkdf2_sha256$260000$sigcon-consulta$c99efca73fdef2e45381fdd59f6a936b5875a2dc73a826f11ddbf549ca18b84c','CONSULTA','Laura Consulta',1);
/*!40000 ALTER TABLE `USUARIO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `VENDEDOR`
--

DROP TABLE IF EXISTS `VENDEDOR`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `VENDEDOR` (
  `VendedorID` int NOT NULL AUTO_INCREMENT,
  `Nombre` varchar(50) NOT NULL,
  `Apellido` varchar(50) NOT NULL,
  `DNI` varchar(20) NOT NULL,
  `Telefono` varchar(20) DEFAULT NULL,
  `SedeID` int NOT NULL,
  PRIMARY KEY (`VendedorID`),
  UNIQUE KEY `uk_vendedor_dni` (`DNI`),
  KEY `fk_vendedor_sede` (`SedeID`),
  CONSTRAINT `fk_vendedor_sede` FOREIGN KEY (`SedeID`) REFERENCES `SEDE` (`SedeID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `VENDEDOR`
--

LOCK TABLES `VENDEDOR` WRITE;
/*!40000 ALTER TABLE `VENDEDOR` DISABLE KEYS */;
INSERT INTO `VENDEDOR` VALUES (1,'Pedro','Perez','1001234561','3101111111',1),(2,'Maria','Lopez','1001234562','3102222222',2),(3,'Juan','Ramirez','1001234563','3103333333',3);
/*!40000 ALTER TABLE `VENDEDOR` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `VENTA`
--

DROP TABLE IF EXISTS `VENTA`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `VENTA` (
  `VentaID` int NOT NULL AUTO_INCREMENT,
  `ClientID` int NOT NULL,
  `VendedorID` int NOT NULL,
  `CarroID` int NOT NULL,
  `Fecha_Venta` date NOT NULL,
  `Monto_Total` decimal(12,2) NOT NULL,
  `Forma_Pago` varchar(50) NOT NULL,
  PRIMARY KEY (`VentaID`),
  UNIQUE KEY `uk_venta_carro` (`CarroID`),
  KEY `fk_venta_cliente` (`ClientID`),
  KEY `fk_venta_vendedor` (`VendedorID`),
  KEY `idx_venta_fecha` (`Fecha_Venta`),
  CONSTRAINT `fk_venta_carro` FOREIGN KEY (`CarroID`) REFERENCES `CARROS` (`CarroID`),
  CONSTRAINT `fk_venta_cliente` FOREIGN KEY (`ClientID`) REFERENCES `CLIENTE` (`ClientID`),
  CONSTRAINT `fk_venta_vendedor` FOREIGN KEY (`VendedorID`) REFERENCES `VENDEDOR` (`VendedorID`),
  CONSTRAINT `chk_venta_monto` CHECK ((`Monto_Total` > 0)),
  CONSTRAINT `chk_venta_pago` CHECK ((`Forma_Pago` in (_utf8mb4'Contado',_utf8mb4'Financiado',_utf8mb4'Tarjeta')))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `VENTA`
--

LOCK TABLES `VENTA` WRITE;
/*!40000 ALTER TABLE `VENTA` DISABLE KEYS */;
INSERT INTO `VENTA` VALUES (1,1,1,5,'2026-05-10',105000000.00,'Financiado'),(2,2,2,6,'2026-05-12',45000000.00,'Contado');
/*!40000 ALTER TABLE `VENTA` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_before_insert` BEFORE INSERT ON `VENTA` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_after_insert` AFTER INSERT ON `VENTA` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_after_delete` AFTER DELETE ON `VENTA` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `vw_detalle_ventas`
--

DROP TABLE IF EXISTS `vw_detalle_ventas`;
/*!50001 DROP VIEW IF EXISTS `vw_detalle_ventas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_detalle_ventas` AS SELECT 
 1 AS `VentaID`,
 1 AS `Cliente`,
 1 AS `Vendedor`,
 1 AS `Marca`,
 1 AS `Modelo`,
 1 AS `Anio`,
 1 AS `Monto_Total`,
 1 AS `Forma_Pago`,
 1 AS `Fecha_Venta`,
 1 AS `Sede`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_inventario_disponible`
--

DROP TABLE IF EXISTS `vw_inventario_disponible`;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_disponible`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_inventario_disponible` AS SELECT 
 1 AS `CarroID`,
 1 AS `VIN`,
 1 AS `Marca`,
 1 AS `Modelo`,
 1 AS `Anio`,
 1 AS `Precio_Venta`,
 1 AS `Nombre_Sede`,
 1 AS `Ciudad`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_ventas_por_sede`
--

DROP TABLE IF EXISTS `vw_ventas_por_sede`;
/*!50001 DROP VIEW IF EXISTS `vw_ventas_por_sede`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_ventas_por_sede` AS SELECT 
 1 AS `SedeID`,
 1 AS `Nombre_Sede`,
 1 AS `Ciudad`,
 1 AS `Cantidad_Ventas`,
 1 AS `Total_Vendido`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'concesionario_db'
--

--
-- Dumping routines for database 'concesionario_db'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_anular_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_venta`(IN p_venta_id INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_venta`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reporte_ventas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_ventas`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `concesionario_db`
--

USE `concesionario_db`;

--
-- Final view structure for view `vw_detalle_ventas`
--

/*!50001 DROP VIEW IF EXISTS `vw_detalle_ventas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `vw_detalle_ventas` AS select `v`.`VentaID` AS `VentaID`,concat(`c`.`Nombre`,' ',`c`.`Apellido`) AS `Cliente`,concat(`ven`.`Nombre`,' ',`ven`.`Apellido`) AS `Vendedor`,`car`.`Marca` AS `Marca`,`car`.`Modelo` AS `Modelo`,`car`.`Anio` AS `Anio`,`v`.`Monto_Total` AS `Monto_Total`,`v`.`Forma_Pago` AS `Forma_Pago`,`v`.`Fecha_Venta` AS `Fecha_Venta`,`s`.`Nombre_Sede` AS `Sede` from ((((`VENTA` `v` join `CLIENTE` `c` on((`v`.`ClientID` = `c`.`ClientID`))) join `VENDEDOR` `ven` on((`v`.`VendedorID` = `ven`.`VendedorID`))) join `CARROS` `car` on((`v`.`CarroID` = `car`.`CarroID`))) join `SEDE` `s` on((`car`.`SedeID` = `s`.`SedeID`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_inventario_disponible`
--

/*!50001 DROP VIEW IF EXISTS `vw_inventario_disponible`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `vw_inventario_disponible` AS select `c`.`CarroID` AS `CarroID`,`c`.`VIN` AS `VIN`,`c`.`Marca` AS `Marca`,`c`.`Modelo` AS `Modelo`,`c`.`Anio` AS `Anio`,`c`.`Precio_Venta` AS `Precio_Venta`,`s`.`Nombre_Sede` AS `Nombre_Sede`,`s`.`Ciudad` AS `Ciudad` from (`CARROS` `c` join `SEDE` `s` on((`s`.`SedeID` = `c`.`SedeID`))) where (`c`.`Estado_Inventario` = 'Disponible') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_ventas_por_sede`
--

/*!50001 DROP VIEW IF EXISTS `vw_ventas_por_sede`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `vw_ventas_por_sede` AS select `s`.`SedeID` AS `SedeID`,`s`.`Nombre_Sede` AS `Nombre_Sede`,`s`.`Ciudad` AS `Ciudad`,count(`v`.`VentaID`) AS `Cantidad_Ventas`,coalesce(sum(`v`.`Monto_Total`),0) AS `Total_Vendido` from ((`SEDE` `s` left join `CARROS` `c` on((`c`.`SedeID` = `s`.`SedeID`))) left join `VENTA` `v` on((`v`.`CarroID` = `c`.`CarroID`))) group by `s`.`SedeID`,`s`.`Nombre_Sede`,`s`.`Ciudad` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-17  1:57:09
