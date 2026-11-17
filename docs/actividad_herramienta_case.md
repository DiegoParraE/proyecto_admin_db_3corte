# Herramienta CASE para probar la base del concesionario

**Asignatura:** Administración de Bases de Datos  
**Programa:** Ingeniería de Sistemas, CTIC Teinco  
**Actividad:** investigar una herramienta CASE que permita hacer pruebas a la base creada por el grupo  
**Base:** `concesionario_db` (MySQL 8.4)  
**Equipo:** Diego Parra, Edison Bohorquez y Fernando Benitez  
**Fecha:** 16 de noviembre de 2026

## Qué se investigó

El proyecto del grupo ya tiene la base del concesionario: diez tablas, la relación N:M entre carros y proveedores, tres vistas, tres procedimientos, tres triggers, usuarios con `GRANT` y `REVOKE`, índices y la aplicación Flask. Esta actividad no vuelve a modelar ese dominio. Busca una herramienta CASE capaz de conectarse a esa base ya creada y probarla.

CASE quiere decir ingeniería de software asistida por computador. En bases de datos, una herramienta CASE dibuja el modelo, genera el esquema o lo recupera desde un servidor vivo, y compara el modelo con lo que realmente quedó instalado. Para esta tarea hacía falta, además, poder ejecutar pruebas contra `concesionario_db`: reglas, procedimientos, triggers, permisos y el plan de una consulta.

## Criterios de elección

La herramienta tenía que servirle a este proyecto, no a una base genérica.

| Criterio | Por qué importa aquí |
| --- | --- |
| Conectarse a MySQL 8.4 ya creado | La base corre en Docker, en `127.0.0.1`, puerto `3307`. No se parte de un modelo vacío. |
| Leer el esquema real | Tiene que mostrar tablas, llaves, vistas, procedimientos y triggers de `concesionario_db`. |
| Comparar modelo y servidor | Así se detecta si el servidor se apartó de los scripts `01_ddl.sql` a `07_indices.sql`. |
| Ejecutar SQL de prueba | CHECK, UNIQUE, llaves foráneas, `sp_registrar_venta`, triggers y `AUDITORIA`. |
| Ver el plan de ejecución | La materia pide índices. La herramienta debe mostrar `EXPLAIN` de forma gráfica. |
| Abrir dos sesiones | Una como `admin_concesionario` y otra como `consulta_concesionario`, para el `REVOKE`. |
| Poder usarla en el equipo | El desarrollo está en macOS. La licencia tiene que alcanzar para una entrega de clase. |

## Herramientas revisadas

Se revisaron tres. Las tres abren una conexión a MySQL. No cubren igual el ciclo de una herramienta CASE ni las pruebas que pide la actividad.

| | MySQL Workbench 8.0 Community | dbForge Studio for MySQL | DBeaver Community |
| --- | --- | --- | --- |
| Qué es | Herramienta CASE de Oracle para modelar, administrar y consultar MySQL | IDE comercial de Devart para diseñar, comparar y poblar MySQL | Cliente universal para muchos motores |
| Licencia | Gratuita (GPL) | De pago. Hay edición Express recortada y prueba de 30 días | Gratuita (Apache 2.0) |
| Modelo | Diagrama EER, ingeniería directa e inversa | Diseñador de base y comparación de esquemas | Diagrama a partir de las tablas |
| Probar una base ya creada | Reverse Engineer, Compare Schemas, editor SQL, Visual Explain, cuentas de usuario | Schema Compare, Data Compare, editor SQL, generador de datos | Editor SQL y diagrama |
| Datos masivos de prueba | No trae un generador | Data Generator, con más de 200 generadores | No es su función |
| En este equipo | Instalador nativo para macOS, Windows y Linux | Aplicación de Windows. En macOS depende de CrossOver | Instalador nativo |
| Encaje con `concesionario_db` | Se conecta al MySQL del `docker-compose.yml` y contrasta el modelo con el servidor | Sirve mejor si hubiera que fabricar miles de filas | Alcanza para consultar. El ciclo modelo contra servidor queda corto |

Fuentes de esas capacidades: el manual de MySQL Workbench (ingeniería inversa, sincronización y el menú Database), la matriz de funciones de dbForge Studio for MySQL y los requisitos de instalación de Devart. Los enlaces están al final.

## Herramienta elegida

La herramienta elegida es **MySQL Workbench 8.0 Community**.

Es una herramienta CASE reconocida para MySQL: el modelo entidad-relación extendido, la ingeniería directa (del dibujo al servidor) y la ingeniería inversa (del servidor al dibujo) están en el mismo producto. Sobre la base que el grupo ya creó, la prueba no consiste en generar otro esquema. Consiste en traer `concesionario_db` al modelo, comparar, y ejecutar el SQL de prueba en el editor.

dbForge Studio for MySQL prueba el esquema con Schema Compare y, además, fabrica datos de prueba realistas. Para este concesionario los datos ya están en `02_dml.sql` (20 clientes y 20 carros). El generador no cambia el resultado de la entrega. En macOS, dbForge no corre nativo: hace falta CrossOver, que es otra licencia. Por eso queda como alternativa, no como la herramienta de la actividad.

DBeaver Community abre el servidor y dibuja las tablas. Sirve de apoyo para mirar datos. No reemplaza la ingeniería inversa ni la comparación de catálogos de Workbench.

## Cómo se conecta a la base del grupo

Con `docker compose up` en la raíz del repositorio, Workbench usa esta conexión:

| Campo | Valor |
| --- | --- |
| Connection method | Standard (TCP/IP) |
| Hostname | `127.0.0.1` |
| Port | `3307` |
| Username | `admin_concesionario` |
| Password | `Admin#2026` |
| Default schema | `concesionario_db` |

El puerto del equipo es 3307 porque el 3306 local ya está ocupado. Dentro de Docker, MySQL sigue en 3306. La cuenta de las pruebas de escritura es `admin_concesionario`. Tiene todos los privilegios dentro de `concesionario_db` y no es `root`.

Para la prueba de permisos se crea una segunda conexión, con el mismo host y puerto, usuario `consulta_concesionario` y clave `Consulta#2026`. Esas claves son las de la práctica. Están en `docker-compose.yml` y en el `README`.

## Prueba 1. El esquema que quedó en el servidor

En Workbench: **Database, Reverse Engineer**. Se elige la conexión anterior, el esquema `concesionario_db`, y se dejan marcados tablas, vistas, rutinas y triggers. **Place imported objects on a diagram** arma el diagrama.

El catálogo importado debe mostrar estos objetos. Si falta uno, la base cargada no coincide con los scripts del repositorio.

**Tablas (10)**

| Tabla | Papel en la prueba |
| --- | --- |
| `SEDE` | Bogotá, Medellín y Cali |
| `CLIENTE` | `DNI` único |
| `PROVEEDOR` | Quien vende el carro al concesionario |
| `VENDEDOR` | Cada vendedor pertenece a una sede |
| `CARROS` | Chasis único, precio, año y estado |
| `CARRO_PROVEEDOR` | Relación N:M entre carro y proveedor, con costo y fecha de compra |
| `VENTA` | Un carro se vende una sola vez (`uk_venta_carro`) |
| `MANTENIMIENTO` | Servicio de taller |
| `USUARIO` | Login de la página. No es el usuario de MySQL |
| `AUDITORIA` | La llena el trigger de `VENTA` |

**Vistas:** `vw_detalle_ventas`, `vw_inventario_disponible`, `vw_ventas_por_sede`.

**Procedimientos:** `sp_registrar_venta`, `sp_anular_venta`, `sp_reporte_ventas`.

**Triggers:** `trg_venta_before_insert`, `trg_venta_after_insert`, `trg_venta_after_delete`.

En el diagrama se sigue la N:M: `CARROS` — `CARRO_PROVEEDOR` — `PROVEEDOR`. Las 1:N que se ven de una vez son sede con vendedores, sede con carros, cliente con ventas y carro con ventas.

Después, con el modelo abierto: **Database, Compare Schemas** (en el manual figura como la comparación del catálogo con la base viva o con un script). El resultado esperado es que las diez tablas, las tres vistas, los tres procedimientos y los tres triggers existan en los dos lados. Si el asistente marca una diferencia, se abre el SQL de ese objeto y se compara con el archivo de `base_de_datos/`. Una diferencia típica, y que no es un fallo del concesionario, es dejar creada la tabla auxiliar de la prueba funcional. El script de la sección siguiente la borra al terminar.

Workbench a veces no redibuja un `CHECK` con el mismo texto del script. En ese caso la prueba sigue siendo el `INSERT` rechazado, que es la sección que viene, y no solo el dibujo.

## Prueba 2. Reglas, procedimiento, trigger y vistas

Archivo: `base_de_datos/pruebas_mysql_workbench.sql`.

Se abre con **File, Open SQL Script**, conectado como `admin_concesionario`, y se ejecuta completo. El script crea un procedimiento de apoyo, corre 15 pruebas, muestra la grilla y el total, llama al reporte y después borra el procedimiento y la tabla `resultado_pruebas_case`. Esas dos cosas no hacen parte del esquema del concesionario. Por eso el archivo no está montado en `docker-compose.yml`.

Cada prueba que debe fallar está metida en un bloque con manejador. Si MySQL rechaza el dato, la fila queda en `PASO` y el mensaje real va en `detalle`. Si el dato entra, la fila queda en `FALLO` y el script borra lo que haya alcanzado a guardar.

| # | Qué toca de la base | Resultado esperado |
| --- | --- | --- |
| 1 | `chk_carro_precio` | Precio 0 rechazado |
| 2 | `chk_carro_estado` | Estado `Reservado` rechazado |
| 3 | `chk_carro_anio` | Año 1970 rechazado |
| 4 | `uk_carro_vin` | El chasis `CHS10001ABC` no se repite |
| 5 | `fk_carro_sede` | `SedeID` 999 rechazado |
| 6 | `trg_venta_before_insert` | El Corolla (ya vendido) no se vende otra vez |
| 7 | `trg_venta_before_insert` | No se vende un `CarroID` que no existe |
| 8 | `chk_venta_pago` | La forma de pago `Efectivo` se rechaza |
| 9 | `fk_cp_proveedor` | La N:M no acepta un proveedor inexistente |
| 10 | `sp_registrar_venta` | El procedimiento rechaza `Efectivo` y hace `ROLLBACK` |
| 11 | `sp_anular_venta` | Anular la venta 999999 avisa que no existe |
| 12 | `DEFAULT` de `CARROS` | Sin estado, el carro queda `Disponible` |
| 13 | Venta completa | Vende un carro libre, el trigger lo marca `Vendido`, `AUDITORIA` recibe el `INSERT`, `sp_anular_venta` lo devuelve a `Disponible` y audita el `DELETE`. Luego borra solo esa auditoría de prueba |
| 14 | Tres vistas | El inventario visible coincide con los carros `Disponible`, hay 2 ventas y 3 sedes |
| 15 | `07_indices.sql` | Están `idx_venta_fecha`, `idx_carro_estado_marca`, `idx_cliente_apellido` e `idx_manto_fecha` |

La grilla final debe decir 15 en `pasaron` y 0 en `fallaron`.

La prueba 13 usa `START TRANSACTION` y `COMMIT` que ya están dentro de `sp_registrar_venta` y `sp_anular_venta`. Si algo sale mal a mitad de camino, el manejador intenta anular la venta de prueba. Si se corta la conexión antes de eso, queda un carro vendido de más: se anula con `CALL sp_anular_venta(id)` usando el `VentaID` nuevo.

Al final del mismo script, esta llamada devuelve las dos ventas de mayo de 2026:

```sql
CALL sp_reporte_ventas('2026-01-01', '2026-12-31');
```

Corolla en Medellín, 10 de mayo, financiado. March en Cali, 12 de mayo, de contado. Bogotá no tiene venta de prueba. Es el mismo procedimiento que usa la pantalla de reporte.

## Prueba 3. El usuario sin permiso

Nueva pestaña de consulta, conexión `consulta_concesionario` / `Consulta#2026`.

Primero:

```sql
SELECT CURRENT_USER();
```

Tiene que verse `consulta_concesionario@%`. Con otra cuenta no se corre lo que sigue, porque el `INSERT` entraría.

```sql
INSERT INTO CLIENTE (Nombre, Apellido, DNI)
VALUES ('Prueba', 'CASE', '9000000001');
```

MySQL debe responder el error **1142**, con un texto de este estilo: `INSERT command denied to user 'consulta_concesionario'@'127.0.0.1' for table 'CLIENTE'`. El host del mensaje es el de esta conexión TCP. `CURRENT_USER()` sigue mostrando `consulta_concesionario@%`. Esa cuenta solo tiene `SELECT` sobre las tablas de negocio y `EXECUTE` de `sp_reporte_ventas`. No tiene fila en `GRANT` para escribir, y `06_usuarios.sql` le quitó al vendedor el `DELETE` y el `EXECUTE` de `sp_anular_venta` con `REVOKE`. La cuenta de consulta nunca los tuvo.

En la misma sesión, esto sí debe funcionar:

```sql
SELECT * FROM vw_inventario_disponible;
CALL sp_reporte_ventas('2026-01-01', '2026-12-31');
```

Y esto debe volver a fallar, porque `AUDITORIA` no está en sus privilegios:

```sql
SELECT * FROM AUDITORIA;
```

`SQL SECURITY INVOKER` en las vistas hace que esta sesión use los permisos de `consulta_concesionario`, no los de quien creó la vista.

## Prueba 4. El índice, con Visual Explain

Con dos filas en `VENTA`, el optimizador suele preferir leer la tabla completa. Usar `idx_venta_fecha` sale más caro que abrir esa página. Por eso el antes y el después no se juzga sobre las ventas reales.

En Workbench se abre `base_de_datos/demo_explain.sql` y se ejecuta. El script arma `DEMO_BUSQUEDA` con 5000 filas, corre `EXPLAIN` sin índice, crea `idx_demo_fecha`, vuelve a correr `EXPLAIN` y borra la tabla de laboratorio.

Para verlo en la herramienta, se selecciona cada `EXPLAIN` y se usa **Query, Explain Current Statement**, o el botón Explain, y la pestaña **Visual Explain**.

| Momento | Qué debe mostrar el plan |
| --- | --- |
| Antes del índice | `type` = `ALL`, `key` vacío. Recorrido completo |
| Después de `idx_demo_fecha` | `type` = `ref`, `key` = `idx_demo_fecha`. Unas pocas filas, las de esa fecha |

Esa consulta tiene la misma forma que el filtro por fecha de `sp_reporte_ventas` (`Fecha_Venta` entre dos fechas, y en el laboratorio `fecha` igual a una constante). El índice del negocio que cubre el reporte es `idx_venta_fecha`, creado en `07_indices.sql`. La prueba 15 del script comprueba que ese índice sigue en el catálogo.

## Orden para mostrar la actividad

1. `docker compose up` y abrir Workbench en `127.0.0.1:3307`.
2. Reverse Engineer de `concesionario_db` y recorrer el diagrama (tablas, N:M, vistas, procedimientos, triggers).
3. Compare Schemas. Explicar cualquier diferencia contra los scripts.
4. Ejecutar `pruebas_mysql_workbench.sql` como `admin_concesionario`. Mostrar 15 pruebas en `PASO` y las dos filas del reporte.
5. En la otra conexión, el `INSERT` de `consulta_concesionario` con el error 1142.
6. Visual Explain de `demo_explain.sql`: `ALL` antes del índice y `ref` después.

## Qué queda por fuera de la herramienta

MySQL Workbench no es un framework de pruebas unitarias al estilo de tSQLt en SQL Server. No guarda una batería con semáforo propio. La batería de esta actividad es el script del repositorio, y Workbench es quien lo ejecuta contra el servidor, muestra el error real y conserva las grillas.

Tampoco genera por sí solo miles de clientes ficticios. Si más adelante hubiera que probar rendimiento con un volumen grande dentro de `CLIENTE` o `VENTA`, dbForge Data Generator sería la herramienta a sumar. Para la base que el grupo ya cargó, Workbench alcanza: recupera el modelo, compara, ejecuta las reglas y enseña el plan.

## Referencias

- MySQL. *MySQL Workbench Manual*, 9.4.2.2 Reverse Engineering a Live Database. https://dev.mysql.com/doc/workbench/en/wb-reverse-engineer-live.html
- MySQL. *MySQL Workbench Manual*, 9.5.1 Database Synchronization. https://dev.mysql.com/doc/workbench/en/wb-database-synchronization.html
- MySQL. *MySQL Workbench Manual*, 9.1.1.1 Modeling Menus (Reverse Engineer, Forward Engineer, Synchronize Model, Compare Schemas y Query Database). https://dev.mysql.com/doc/workbench/en/wb-data-modeling-menus.html
- MySQL. *MySQL Workbench Manual*, Visual Explain. https://dev.mysql.com/doc/workbench/en/wb-performance-explain.html
- Devart. dbForge Studio for MySQL, funciones (Schema Compare, Data Compare, Data Generator). https://www.devart.com/dbforge/mysql/studio/features.html
- Devart. Requisitos: en macOS y Linux hace falta CrossOver. https://docs.devart.com/studio-for-mysql/getting-started/requirements.html
