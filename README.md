# Concesionario — Cali, Medellín y Bogotá

Sistema para las sedes de Cali, Medellín y Bogotá: inventario de vehículos, clientes, vendedores, proveedores, ventas y mantenimientos. La base salió del dump `concesionario_db` y este repositorio la deja lista para la sustentación de Administración de Bases de Datos.

## Tecnologías

- MySQL 8.4 (InnoDB): tablas, vistas, procedimientos, triggers, usuarios y índices
- Python 3, Flask y Gunicorn
- PyMySQL, consultas con parámetros
- Docker Compose

## Cómo levantarlo

Hace falta Docker Desktop encendido.

```bash
docker compose up --build
```

- Aplicación: http://localhost:8080
- MySQL, desde el equipo: `127.0.0.1:3307`, usuario `root`, clave `root`

El puerto 3306 de esta máquina ya lo usa otro MySQL, y el 5000 lo toma AirPlay. Por eso Compose publica 3307 y 8080. Dentro de la red de Docker no cambia nada.

La primera vez MySQL ejecuta `database/01_ddl.sql` … `07_indices.sql` y carga los datos. Si ya existe el volumen y quieres empezar de cero:

```bash
docker compose down -v
docker compose up --build
```

`down -v` borra el volumen. Sin `-v`, un segundo `up` no vuelve a correr los scripts.

## Usuarios de prueba

Hay dos capas. No uses la clave de MySQL en el formulario, ni la clave del formulario en la consola.

### Aplicación web (http://localhost:8080)

| Usuario | Clave | Qué puede hacer |
| --- | --- | --- |
| `admin` | `admin123` | CRUD completo y auditoría |
| `vendedor` | `vendedor123` | Crea clientes, ventas y mantenimientos. No elimina |
| `consulta` | `consulta123` | Solo lectura y reporte |

### Cuentas del SGBD (consola)

Conéctate por TCP (`-h 127.0.0.1`). El host de estas cuentas es `%`; por socket, `localhost` no coincide.

| Cuenta | Clave | Permiso |
| --- | --- | --- |
| `consulta_concesionario` | `Consulta#2026` | Solo `SELECT` y el reporte. El `INSERT` falla |
| `vendedor_concesionario` | `Vendedor#2026` | Lee, crea clientes, ventas y mantenimientos. No borra ni lee la auditoría |
| `admin_concesionario` | `Admin#2026` | Todo dentro de `concesionario_db` |
| `auth_concesionario` | `Auth#2026` | Solo lee `USUARIO`, para el login |
| `root` | `root` | Administración del servidor y el backup |

`app/config.example.env` es la plantilla sin credenciales. Las claves de esta tabla están en `docker-compose.yml` porque el enunciado pide levantar todo con un comando y publicar los usuarios de prueba. No son claves de producción.

## Qué hay en el repositorio

- `database/01_ddl.sql` a `07_indices.sql`: carga ordenada
- `database/concesionario_backup.sql`: backup lógico (se genera con el script de abajo)
- `database/demo_permisos.sh`, `demo_procedimiento.sh`, `demo_explain.sh`, `demo_backup.sh`, `demo_transaccion.sh`: la sustentación en el SGBD, incluida una transacción con `BEGIN` y `ROLLBACK`
- `docs/modelo_er.drawio`: modelo entidad-relación para abrir en draw.io
- `app/`: formulario web
- `docs/documento_tecnico.pdf`: documento técnico

Después del primer arranque, genera el backup que vas a restaurar en vivo:

```bash
./database/generar_backup.sh
```

## Guion de sustentación (15 + 5)

Ensayen con el reloj. Todos hablan.

1. **Problema y modelo (3 min).** El concesionario llevaba sedes, inventario, compras, ventas y taller en hojas de cálculo. Un carro se podía vender dos veces y el precio de lista se mezclaba con el de la venta. Muestren el E-R del PDF: `SEDE`, `CLIENTE`, `VENDEDOR`, `PROVEEDOR`, `CARROS`, `CARRO_PROVEEDOR`, `VENTA`, `MANTENIMIENTO`. `USUARIO` y `AUDITORIA` son el apoyo de la aplicación y del trigger.
2. **Aplicación (4 min).** Entren como `admin`. Creen un cliente. Entren como `vendedor` / `vendedor123` y registren una venta del Chevrolet Onix: el monto no se digita y el vehículo pasa a Vendido. Entren como `consulta` / `consulta123` y muestren que no aparece «Nuevo». Abran Reporte con el rango 1 ene 2026 – 31 dic 2026 (las ventas de prueba son de mayo).
3. **SGBD (4 min).** En otra terminal, desde la raíz del repo:
   ```bash
   ./database/demo_permisos.sh
   ./database/demo_procedimiento.sh
   ```
   Lo primero debe mostrar `INSERT` denegado. Lo segundo vende un carro, escribe `AUDITORIA` y el segundo `INSERT` lo rechaza el trigger.
4. **Backup (2 min).**
   ```bash
   ./database/demo_backup.sh --confirmar
   ```
   Borra las ventas (el conteo queda en 0) y el backup las devuelve.
5. **EXPLAIN (2 min).**
   ```bash
   ./database/demo_explain.sh
   ```
   En `VENTA` el plan ya usa `idx_venta_fecha` (`type = range`). El contraste grande está en la tabla de laboratorio de 5000 filas: antes `type = ALL`, `key = NULL`, 5000 filas; después `type = ref`, `key = idx_demo_fecha`, unas 6 filas. El script borra esa tabla al final.
6. **Preguntas (5 min).** Cada quien responde lo que construyó. Abajo hay una lista corta para repartirse.

## Preguntas que conviene poder responder

- **Vista, procedimiento y trigger.** La vista (`vw_detalle_ventas`) solo lee y no guarda datos. El procedimiento (`sp_registrar_venta`) toma el precio y hace el `INSERT`. El trigger corre solo, en todo `INSERT` o `DELETE` de `VENTA`, aunque nadie llame al procedimiento: rechaza un carro que no está disponible, lo marca vendido y deja la fila en `AUDITORIA`.
- **Por qué el monto se guarda en `VENTA`.** Es el precio del día de la venta. Si mañana cambia `CARROS.Precio_Venta`, la venta histórica no se mueve. No es redundancia: depende de la venta, no del vehículo.
- **Por qué no hay otro índice en `DNI` o `VIN`.** Esas columnas ya son `UNIQUE`, e InnoDB también indexa las llaves foráneas. Repetirlas no acelera nada y encarece cada escritura.
- **Por qué `idx_carro_estado_marca` empieza por el estado.** La pantalla filtra por estado sin obligar a elegir marca. El prefijo izquierdo del índice tiene que ser esa columna.
- **Dos cuentas distintas.** `vendedor` / `vendedor123` entra al sitio. `vendedor_concesionario` entra a MySQL. Al iniciar sesión, Flask abre la conexión con la cuenta del rol, así un `DELETE` del vendedor también lo niega el SGBD.
- **`SQL SECURITY INVOKER`.** La vista y el procedimiento usan los permisos de quien llama, no los de `root`. El trigger sí queda como `root`, y por eso puede actualizar `CARROS` aunque el vendedor no tenga `UPDATE` sobre esa tabla.
- **Las dos ventas iniciales no salen en auditoría.** `02_dml.sql` corre antes de `05_triggers.sql`. El trigger solo ve lo que ocurre después.
- **Backup.** `mysqldump --single-transaction --routines --triggers`. Restaurar ese archivo rehace la base. No incluye las cuentas de MySQL: esas viven en `06_usuarios.sql`. En el mismo servidor, después de borrar datos, el backup alcanza porque los usuarios siguen ahí.

## Instalación sin Docker

Hace falta MySQL 8 y Python 3.11+.

```bash
mysql -h 127.0.0.1 -uroot -p < database/01_ddl.sql
mysql -h 127.0.0.1 -uroot -p < database/02_dml.sql
mysql -h 127.0.0.1 -uroot -p < database/03_vistas.sql
mysql -h 127.0.0.1 -uroot -p < database/04_procedimientos.sql
mysql -h 127.0.0.1 -uroot -p < database/05_triggers.sql
mysql -h 127.0.0.1 -uroot -p < database/06_usuarios.sql
mysql -h 127.0.0.1 -uroot -p < database/07_indices.sql
```

Si el servidor tiene el binlog prendido y rechaza el trigger, activen `log_bin_trust_function_creators=1` o créenlos como administrador.

```bash
cd app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config.example.env .env
```

Completen `app/.env` con las claves reales de su MySQL y ejecuten:

```bash
set -a
source .env
set +a
flask --app app run --port 8080
```

## Documento

`docs/documento_tecnico.pdf` tiene portada, problema, alcance, justificación de MySQL, modelos, normalización, diccionario, seguridad, respaldo, índices, arquitectura y manual de instalación.

Antes de entregar, completen en la portada los nombres y códigos del equipo. El PDF se regenera abriendo `docs/documento_tecnico.html` en el navegador e imprimiendo a PDF, o con el comando que quedó anotado al final de ese HTML.

## Entrega en Git

El enunciado pide historial de todos los integrantes. Cada quien hace sus propios commits, con su usuario de GitHub o GitLab. No hace falta un commit por archivo: sí hace falta que no exista un único autor para todo el trabajo.
