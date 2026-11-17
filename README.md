# Concesionario

Sistema para el inventario, las ventas y el taller de un concesionario con sedes en Bogotá, Medellín y Cali. La página está hecha en Flask y habla directo con MySQL. No hay una API en el medio.

Es el trabajo de Administración de Bases de Datos, Ingeniería de Sistemas, TEINCO. La base se llama `concesionario_db`.

## Requisitos

Hace falta Docker Desktop encendido. Este proyecto no se prende con `npm` ni con `yarn`.

## Cómo ejecutarlo

Desde la raíz del repositorio:

```bash
docker compose up --build
```

- Página: http://localhost:8080
- MySQL, desde el equipo: `127.0.0.1`, puerto `3307`, usuario `root`, clave `root`

El puerto 3306 de la máquina ya lo usa otro MySQL y el 5000 lo toma AirPlay. Por eso Compose publica 3307 y 8080. Adentro de Docker, MySQL sigue en 3306 y Flask en 5000. La variable `DB_HOST` vale `db`, que es el nombre del servicio.

La primera vez, MySQL corre `base_de_datos/01_ddl.sql` hasta `07_indices.sql` y carga los datos. Un segundo `docker compose up` no vuelve a ejecutar esos scripts.

Para apagarlo, Control + C en esa terminal. Para borrar los datos y volver a cargar los scripts:

```bash
docker compose down -v
docker compose up --build
```

`down -v` borra el volumen. Editar `02_dml.sql` y guardar el archivo no cambia la base que ya está corriendo: hay que borrar el volumen y levantarla otra vez. Las claves hasheadas de `USUARIO` no se reescriben; si se cambian, el ingreso deja de funcionar.

Si se cambia una pantalla o `app.py`, la imagen se arma al construir. Hace falta:

```bash
docker compose up --build -d web
```

## Usuarios de la página

En http://localhost:8080 se entra con estas cuentas. No son las cuentas de MySQL.

| Usuario | Clave | Nombre en pantalla | Qué puede hacer |
| --- | --- | --- | --- |
| `admin` | `admin123` | Diego Parra | Ver, crear, editar y eliminar. Es el único que ve Auditoría |
| `vendedor` | `vendedor123` | Edison Bohorquez | Crear clientes, ventas y servicios de taller. No elimina |
| `consulta` | `consulta123` | Fernando Benitez | Solo mira. No le sale el botón de agregar |

Esos nombres salen de `USUARIO.Nombre_Completo` en `base_de_datos/02_dml.sql`. Los vendedores de las sedes son otros: Pedro Perez en Bogotá, Maria Lopez en Medellín y Juan Ramirez en Cali.

## Usuarios de MySQL

La página, después del login, abre MySQL con la cuenta del rol. Nunca entra como `root`. Estas cuentas sirven para la consola. Hay que conectar por TCP, porque el host es `%` y el socket `localhost` no coincide:

```bash
mysql -h 127.0.0.1 -P 3307 -u consulta_concesionario -p
```

| Cuenta | Clave | Permiso |
| --- | --- | --- |
| `consulta_concesionario` | `Consulta#2026` | Solo lectura y el reporte |
| `vendedor_concesionario` | `Vendedor#2026` | Lee y crea clientes, ventas y mantenimientos. No borra ventas |
| `admin_concesionario` | `Admin#2026` | Todo dentro de `concesionario_db` |
| `auth_concesionario` | `Auth#2026` | Solo lee `USUARIO`, para validar el login |
| `root` | `root` | Init del contenedor y el backup |

`app/backend/config.example.env` es la plantilla sin credenciales. Las claves de prueba están en `docker-compose.yml` para poder levantar todo con un comando. No sirven para un entorno real. En YAML la clave va entre comillas, porque `#` empieza un comentario.

## Carpetas

```text
app/
  frontend/          pantallas HTML y style.css
  backend/           app.py, requirements.txt, config.example.env
base_de_datos/
  01_ddl.sql         tablas, llaves, CHECK y DEFAULT
  02_dml.sql         datos de prueba
  03_vistas.sql      tres vistas
  04_procedimientos.sql
  05_triggers.sql
  06_usuarios.sql    GRANT y REVOKE
  07_indices.sql
  concesionario_backup.sql
  demo_*.sh          pruebas de permisos, venta, transacción, EXPLAIN y backup
  pruebas_mysql_workbench.sql   batería para correr en MySQL Workbench
docs/
  Manual_de_usuario.pdf
  Manual_tecnico.pdf
  actividad_herramienta_case.md   investigación de la herramienta CASE
docker-compose.yml
```

## Datos de prueba

Hay 3 sedes, 20 clientes, 20 carros, 2 proveedores, 4 compras, 2 ventas de mayo de 2026 y 1 mantenimiento. El chasis está en la columna `VIN` y en la página se muestra como número de chasis. Los de ejemplo empiezan por `CHS`.

El reporte, con el rango del 1 de enero de 2026 al 31 de diciembre de 2026, muestra esas dos ventas. Bogotá queda con inventario y sin ventas de prueba: el Corolla se vendió en Medellín y el March en Cali.

Las dos ventas iniciales no aparecen en Auditoría. `02_dml.sql` corre antes de los triggers, y el trigger solo ve lo que pasa después.

## Probar lo que pide la materia

Con la base ya levantada, desde la raíz:

```bash
./base_de_datos/demo_permisos.sh
./base_de_datos/demo_procedimiento.sh
./base_de_datos/demo_transaccion.sh
./base_de_datos/demo_explain.sh
./base_de_datos/generar_backup.sh
./base_de_datos/demo_backup.sh --confirmar
```

- `demo_permisos.sh`: el `INSERT` de consulta falla y el vendedor no puede anular una venta.
- `demo_procedimiento.sh`: registra una venta, el carro queda vendido y Auditoría recibe la fila. Una segunda venta del mismo carro la rechaza el trigger.
- `demo_transaccion.sh`: hace `BEGIN`, inserta un cliente y hace `ROLLBACK`. Ese cliente no queda.
- `demo_explain.sh`: en `VENTA` el plan usa `idx_venta_fecha`. En una tabla de laboratorio de 5000 filas, sin índice el plan es `ALL`; con índice baja a unas 6 filas. El script borra esa tabla al terminar.
- `demo_backup.sh --confirmar`: borra las ventas y las restaura desde `concesionario_backup.sql`. Conviene generar el backup antes, con la base ya cargada.

## Documentos

- `docs/Manual_de_usuario.pdf`: cómo prender el sistema y qué hace cada pantalla.
- `docs/Manual_tecnico.pdf`: carpetas, puertos y cómo se conecta Flask con MySQL.

El documento de presentación, el que repasa cada requisito del docente, no va en el repositorio. Quedó en Descargas, con el nombre `Documento_presentacion_Administracion_de_Bases_de_Datos.pdf`.

## Actividad adicional: herramienta CASE

La investigación está en `docs/actividad_herramienta_case.md`. La herramienta elegida es MySQL Workbench. Con la base ya levantada, el script de pruebas se abre en Workbench conectado como `admin_concesionario` por el puerto `3307`:

`base_de_datos/pruebas_mysql_workbench.sql`

Ese archivo no se carga al crear el contenedor. Al terminar borra la tabla y el procedimiento de apoyo. La prueba del usuario `consulta_concesionario` y el Visual Explain quedan explicados en el mismo documento.

## Sin Docker

Hace falta MySQL 8 y Python 3.11 o superior.

```bash
mysql -h 127.0.0.1 -uroot -p < base_de_datos/01_ddl.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/02_dml.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/03_vistas.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/04_procedimientos.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/05_triggers.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/06_usuarios.sql
mysql -h 127.0.0.1 -uroot -p < base_de_datos/07_indices.sql
```

Si el servidor tiene el binlog prendido y rechaza el trigger, hay que activar `log_bin_trust_function_creators=1`.

```bash
cd app/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config.example.env .env
```

En `.env` van el host, el puerto y las claves de ese MySQL. Después:

```bash
set -a
source .env
set +a
flask --app app run --port 8080
```
