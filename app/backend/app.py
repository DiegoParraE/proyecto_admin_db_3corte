"""Concesionario. Flask se conecta directo a MySQL, sin API.

La clave del formulario no es la clave de MySQL.
Las consultas usan %s para no armar el SQL con texto del usuario.
"""

import binascii
import hashlib
import hmac
import os
import secrets
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path

import pymysql
from flask import (
    Flask,
    abort,
    flash,
    g,
    redirect,
    render_template,
    request,
    session,
    url_for,
)

CARPETA_APP = Path(__file__).resolve().parent.parent
app = Flask(
    __name__,
    template_folder=str(CARPETA_APP / "frontend" / "templates"),
    static_folder=str(CARPETA_APP / "frontend" / "static"),
)
app.secret_key = os.environ["SECRET_KEY"]
app.config.update(SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax")

PERMISOS = {
    "clientes": {
        "ver": {"ADMIN", "VENDEDOR", "CONSULTA"},
        "crear": {"ADMIN", "VENDEDOR"},
        "editar": {"ADMIN", "VENDEDOR"},
        "eliminar": {"ADMIN"},
    },
    "carros": {
        "ver": {"ADMIN", "VENDEDOR", "CONSULTA"},
        "crear": {"ADMIN"},
        "editar": {"ADMIN"},
        "eliminar": {"ADMIN"},
    },
    "ventas": {
        "ver": {"ADMIN", "VENDEDOR", "CONSULTA"},
        "crear": {"ADMIN", "VENDEDOR"},
        "eliminar": {"ADMIN"},
    },
    "mantenimientos": {
        "ver": {"ADMIN", "VENDEDOR", "CONSULTA"},
        "crear": {"ADMIN", "VENDEDOR"},
        "editar": {"ADMIN"},
        "eliminar": {"ADMIN"},
    },
    "catalogo": {
        "ver": {"ADMIN", "VENDEDOR", "CONSULTA"},
        "crear": {"ADMIN"},
        "editar": {"ADMIN"},
        "eliminar": {"ADMIN"},
    },
    "auditoria": {"ver": {"ADMIN"}},
    "reporte": {"ver": {"ADMIN", "VENDEDOR", "CONSULTA"}},
}

NOMBRE_ROL = {
    "ADMIN": "Administrador",
    "VENDEDOR": "Vendedor",
    "CONSULTA": "Solo consulta",
}

CUENTAS = {
    "ADMIN": ("ADMIN_DB_USER", "ADMIN_DB_PASSWORD"),
    "VENDEDOR": ("VENDEDOR_DB_USER", "VENDEDOR_DB_PASSWORD"),
    "CONSULTA": ("CONSULTA_DB_USER", "CONSULTA_DB_PASSWORD"),
}


class ValidationError(Exception):
    pass


def verificar_clave(clave, almacenada):
    partes = (almacenada or "").split("$")
    if len(partes) != 4 or partes[0] != "pbkdf2_sha256":
        return False
    _, iteraciones, salt, esperado = partes
    try:
        vueltas = int(iteraciones)
    except ValueError:
        return False
    derivado = hashlib.pbkdf2_hmac("sha256", clave.encode(), salt.encode(), vueltas)
    return hmac.compare_digest(binascii.hexlify(derivado).decode(), esperado)


def conectar(usuario, clave):
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=usuario,
        password=clave,
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
        init_command="SET time_zone = '-05:00'",
        client_flag=pymysql.constants.CLIENT.MULTI_RESULTS,
    )


def get_db():
    if "db" not in g:
        rol = session["usuario"]["rol"]
        variable_usuario, variable_clave = CUENTAS[rol]
        g.db = conectar(os.environ[variable_usuario], os.environ[variable_clave])
    return g.db


@app.teardown_appcontext
def cerrar_conexion(_exc):
    conexion = g.pop("db", None)
    if conexion is not None:
        conexion.close()


def mensaje_error(exc):
    codigo = exc.args[0] if exc.args else None
    texto = exc.args[1] if len(exc.args) > 1 else str(exc)
    if codigo == 1062:
        return "Ya existe un registro con esa cédula, ese chasis o ese vehículo."
    if codigo == 1451:
        return "No se puede eliminar: hay otros registros que dependen de este."
    if codigo == 1452:
        return "La referencia elegida no existe."
    if codigo in (1142, 1370):
        return "El usuario de base de datos de tu rol no tiene permiso para esa operación."
    if codigo == 3819:
        return "Hay un dato fuera de las reglas de la tabla (precio, año, estado o forma de pago)."
    if codigo == 1644:
        return texto
    return texto


def ejecutar(sql, params=()):
    try:
        with get_db().cursor() as cur:
            cur.execute(sql, params)
            filas = cur.fetchall() if cur.description else []
            while cur.nextset():
                if cur.description:
                    cur.fetchall()
            return filas
    except pymysql.MySQLError as exc:
        raise ValidationError(mensaje_error(exc)) from exc


def uno(sql, params=()):
    filas = ejecutar(sql, params)
    return filas[0] if filas else None


def exigir(modulo, accion):
    if "usuario" not in session:
        return redirect(url_for("login"))
    rol = session["usuario"]["rol"]
    if rol not in PERMISOS[modulo][accion]:
        flash("Con este usuario no puedes hacer eso.", "error")
        return redirect(url_for("dashboard"))
    return None


def token_csrf():
    if "csrf" not in session:
        session["csrf"] = secrets.token_hex(16)
    return session["csrf"]


@app.before_request
def revisar_csrf():
    if request.method == "POST":
        enviado = request.form.get("csrf_token", "")
        if not hmac.compare_digest(enviado, session.get("csrf", "")):
            abort(400)


@app.context_processor
def contexto():
    usuario = session.get("usuario")
    return {
        "csrf": token_csrf(),
        "usuario_actual": usuario,
        "nombre_rol": NOMBRE_ROL.get(usuario["rol"], "") if usuario else "",
        "puede": lambda modulo, accion: bool(
            usuario and usuario["rol"] in PERMISOS.get(modulo, {}).get(accion, set())
        ),
    }


@app.template_filter("cop")
def filtro_cop(valor):
    if valor is None:
        return "—"
    numero = Decimal(valor)
    texto = f"{numero:,.0f}".replace(",", ".")
    return f"$ {texto}"


@app.template_filter("fecha")
def filtro_fecha(valor):
    if valor is None:
        return "—"
    if isinstance(valor, datetime):
        valor = valor.date()
    if isinstance(valor, date):
        return valor.strftime("%d/%m/%Y")
    return str(valor)


def texto(nombre, maximo, etiqueta, requerido=True):
    valor = request.form.get(nombre, "").strip()
    if not valor:
        if requerido:
            raise ValidationError(f"{etiqueta} es obligatorio.")
        return None
    if len(valor) > maximo:
        raise ValidationError(f"{etiqueta} supera los {maximo} caracteres.")
    return valor


def entero(nombre, minimo, maximo, etiqueta):
    crudo = request.form.get(nombre, "").strip()
    if not crudo.isdigit():
        raise ValidationError(f"{etiqueta} debe ser un número entero.")
    valor = int(crudo)
    if valor < minimo or valor > maximo:
        raise ValidationError(f"{etiqueta} está fuera del rango permitido.")
    return valor


def dinero(nombre, etiqueta, maximo):
    crudo = request.form.get(nombre, "").strip().replace(",", ".")
    try:
        valor = Decimal(crudo)
    except InvalidOperation:
        raise ValidationError(f"{etiqueta} no es un valor numérico.")
    if valor <= 0 or valor > maximo:
        raise ValidationError(f"{etiqueta} debe ser mayor que cero.")
    return valor


def fecha_form(nombre, etiqueta):
    crudo = request.form.get(nombre, "").strip()
    try:
        return datetime.strptime(crudo, "%Y-%m-%d").date()
    except ValueError:
        raise ValidationError(f"{etiqueta} no es una fecha válida.")


def prefijo(valor):
    limpio = valor.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return limpio + "%"


def campo(nombre, etiqueta, tipo="text", valor="", requerido=True, opciones=None):
    return {
        "nombre": nombre,
        "etiqueta": etiqueta,
        "tipo": tipo,
        "valor": "" if valor is None else valor,
        "requerido": requerido,
        "opciones": opciones or [],
    }


def opciones_sedes():
    filas = ejecutar("SELECT SedeID, Nombre_Sede, Ciudad FROM SEDE ORDER BY Nombre_Sede")
    return [
        {"valor": fila["SedeID"], "texto": f"{fila['Nombre_Sede']} ({fila['Ciudad']})"}
        for fila in filas
    ]


def opciones_personas(tabla, id_col, vacio=None):
    filas = ejecutar(
        f"SELECT {id_col} AS id, Nombre, Apellido FROM {tabla} ORDER BY Apellido, Nombre"
    )
    opciones = []
    if vacio is not None:
        opciones.append({"valor": "", "texto": vacio})
    opciones.extend(
        {"valor": fila["id"], "texto": f"{fila['Nombre']} {fila['Apellido']}"}
        for fila in filas
    )
    return opciones


def opciones_carros(solo_disponibles=False):
    sql = """
        SELECT CarroID, Marca, Modelo, Anio, Precio_Venta
        FROM CARROS
    """
    if solo_disponibles:
        sql += " WHERE Estado_Inventario = 'Disponible'"
    sql += " ORDER BY Marca, Modelo"
    filas = ejecutar(sql)
    return [
        {
            "valor": fila["CarroID"],
            "texto": f"{fila['Marca']} {fila['Modelo']} {fila['Anio']} — {filtro_cop(fila['Precio_Venta'])}",
        }
        for fila in filas
    ]


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        clave = request.form.get("clave", "")
        try:
            conexion = conectar(os.environ["AUTH_DB_USER"], os.environ["AUTH_DB_PASSWORD"])
        except pymysql.MySQLError:
            flash("No hay conexión con la base de datos.", "error")
            return render_template("login.html")
        try:
            with conexion.cursor() as cur:
                cur.execute(
                    """
                    SELECT UsuarioID, Username, Password_Hash, Rol, Nombre_Completo
                    FROM USUARIO
                    WHERE Username = %s AND Activo = 1
                    """,
                    (username,),
                )
                fila = cur.fetchone()
        finally:
            conexion.close()
        hash_guardado = fila["Password_Hash"] if fila else "pbkdf2_sha256$260000$x$" + ("0" * 64)
        if fila and verificar_clave(clave, hash_guardado) and fila["Rol"] in CUENTAS:
            session["usuario"] = {
                "id": fila["UsuarioID"],
                "username": fila["Username"],
                "rol": fila["Rol"],
                "nombre": fila["Nombre_Completo"],
            }
            session["csrf"] = secrets.token_hex(16)
            return redirect(url_for("dashboard"))
        flash("Usuario o clave incorrectos.", "error")
    return render_template("login.html")


@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/")
def dashboard():
    bloqueo = exigir("reporte", "ver")
    if bloqueo:
        return bloqueo
    totales = uno(
        """
        SELECT
          (SELECT COUNT(*) FROM CARROS WHERE Estado_Inventario = 'Disponible') AS disponibles,
          (SELECT COUNT(*) FROM CARROS WHERE Estado_Inventario = 'Vendido') AS vendidos,
          (SELECT COUNT(*) FROM CLIENTE) AS clientes,
          (SELECT COUNT(*) FROM VENTA) AS ventas,
          (SELECT COALESCE(SUM(Monto_Total), 0) FROM VENTA) AS total
        """
    )
    recientes = ejecutar(
        """
        SELECT VentaID, Cliente, Vendedor, Marca, Modelo, Monto_Total, Fecha_Venta
        FROM vw_detalle_ventas
        ORDER BY Fecha_Venta DESC, VentaID DESC
        LIMIT 5
        """
    )
    return render_template("dashboard.html", totales=totales, recientes=recientes)


@app.route("/reporte")
def reporte():
    bloqueo = exigir("reporte", "ver")
    if bloqueo:
        return bloqueo
    desde = request.args.get("desde", "2026-01-01")
    hasta = request.args.get("hasta", "2026-12-31")
    try:
        datetime.strptime(desde, "%Y-%m-%d")
        datetime.strptime(hasta, "%Y-%m-%d")
    except ValueError:
        flash("El rango de fechas no es válido.", "error")
        return redirect(url_for("reporte"))
    filas = ejecutar("CALL sp_reporte_ventas(%s, %s)", (desde, hasta))
    resumen = ejecutar(
        """
        SELECT SedeID, Nombre_Sede, Ciudad, Cantidad_Ventas, Total_Vendido
        FROM vw_ventas_por_sede
        ORDER BY Nombre_Sede
        """
    )
    total = sum((fila["Monto_Total"] or 0) for fila in filas)
    return render_template(
        "reporte.html",
        filas=filas,
        resumen=resumen,
        desde=desde,
        hasta=hasta,
        total=total,
    )


@app.route("/auditoria")
def auditoria():
    bloqueo = exigir("auditoria", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar(
        """
        SELECT AuditoriaID, Fecha_Hora, Tabla, Operacion, Registro_ID, Usuario_DB, Detalle
        FROM AUDITORIA
        ORDER BY AuditoriaID DESC
        LIMIT 100
        """
    )
    return render_template("auditoria.html", filas=filas)


def render_lista(**kwargs):
    return render_template("listado.html", **kwargs)


@app.route("/clientes")
def clientes():
    bloqueo = exigir("clientes", "ver")
    if bloqueo:
        return bloqueo
    q = request.args.get("q", "").strip()
    if q:
        busqueda = prefijo(q)
        filas = ejecutar(
            """
            SELECT ClientID, Nombre, Apellido, DNI, Direccion, Telefono
            FROM CLIENTE
            WHERE Apellido LIKE %s OR DNI LIKE %s
            ORDER BY Apellido, Nombre
            """,
            (busqueda, busqueda),
        )
    else:
        filas = ejecutar(
            """
            SELECT ClientID, Nombre, Apellido, DNI, Direccion, Telefono
            FROM CLIENTE
            ORDER BY Apellido, Nombre
            """
        )
    return render_lista(
        titulo="Clientes",
        descripcion="Busca por apellido o por cédula.",
        modulo="clientes",
        columnas=[
            ("Nombre", "Nombre", None),
            ("Apellido", "Apellido", None),
            ("DNI", "Cédula", None),
            ("Telefono", "Teléfono", None),
            ("Direccion", "Dirección", None),
        ],
        filas=filas,
        id_campo="ClientID",
        url_nuevo=url_for("cliente_nuevo"),
        endpoint_editar="cliente_editar",
        endpoint_eliminar="cliente_eliminar",
        buscar=True,
        q=q,
        placeholder="Apellido o cédula",
    )


def campos_cliente(origen):
    return [
        campo("nombre", "Nombre", valor=origen.get("nombre", "")),
        campo("apellido", "Apellido", valor=origen.get("apellido", "")),
        campo("dni", "Cédula", valor=origen.get("dni", "")),
        campo("telefono", "Teléfono", valor=origen.get("telefono", ""), requerido=False),
        campo("direccion", "Dirección", valor=origen.get("direccion", ""), requerido=False),
    ]


def leer_cliente():
    return (
        texto("nombre", 50, "El nombre"),
        texto("apellido", 50, "El apellido"),
        texto("dni", 20, "La cédula"),
        texto("direccion", 150, "La dirección", requerido=False),
        texto("telefono", 20, "El teléfono", requerido=False),
    )


@app.route("/clientes/nuevo", methods=["GET", "POST"])
def cliente_nuevo():
    bloqueo = exigir("clientes", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {}
    if request.method == "POST":
        try:
            ejecutar(
                """
                INSERT INTO CLIENTE (Nombre, Apellido, DNI, Direccion, Telefono)
                VALUES (%s, %s, %s, %s, %s)
                """,
                leer_cliente(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Cliente registrado.", "ok")
            return redirect(url_for("clientes"))
    return render_template(
        "formulario.html",
        titulo="Nuevo cliente",
        campos=campos_cliente(origen),
        volver=url_for("clientes"),
    )


@app.route("/clientes/<int:registro_id>/editar", methods=["GET", "POST"])
def cliente_editar(registro_id):
    bloqueo = exigir("clientes", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        "SELECT ClientID, Nombre, Apellido, DNI, Direccion, Telefono FROM CLIENTE WHERE ClientID = %s",
        (registro_id,),
    )
    if fila is None:
        flash("Ese cliente ya no existe.", "error")
        return redirect(url_for("clientes"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE CLIENTE
                   SET Nombre = %s, Apellido = %s, DNI = %s, Direccion = %s, Telefono = %s
                 WHERE ClientID = %s
                """,
                (*leer_cliente(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Cliente actualizado.", "ok")
            return redirect(url_for("clientes"))
        origen = request.form
    else:
        origen = {
            "nombre": fila["Nombre"],
            "apellido": fila["Apellido"],
            "dni": fila["DNI"],
            "direccion": fila["Direccion"],
            "telefono": fila["Telefono"],
        }
    return render_template(
        "formulario.html",
        titulo="Editar cliente",
        campos=campos_cliente(origen),
        volver=url_for("clientes"),
    )


@app.post("/clientes/<int:registro_id>/eliminar")
def cliente_eliminar(registro_id):
    bloqueo = exigir("clientes", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM CLIENTE WHERE ClientID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Cliente eliminado.", "ok")
    return redirect(url_for("clientes"))


@app.route("/carros")
def carros():
    bloqueo = exigir("carros", "ver")
    if bloqueo:
        return bloqueo
    estado = request.args.get("estado", "")
    marca = request.args.get("marca", "")
    condiciones = []
    params = []
    if estado in ("Disponible", "Vendido"):
        condiciones.append("c.Estado_Inventario = %s")
        params.append(estado)
    if marca:
        condiciones.append("c.Marca = %s")
        params.append(marca)
    where = ("WHERE " + " AND ".join(condiciones)) if condiciones else ""
    filas = ejecutar(
        f"""
        SELECT c.CarroID, c.VIN, c.Marca, c.Modelo, c.Anio, c.Precio_Venta,
               c.Estado_Inventario, s.Nombre_Sede
        FROM CARROS c
        JOIN SEDE s ON s.SedeID = c.SedeID
        {where}
        ORDER BY c.Marca, c.Modelo
        """,
        params,
    )
    marcas = ejecutar("SELECT DISTINCT Marca FROM CARROS ORDER BY Marca")
    return render_template(
        "carros.html",
        filas=filas,
        marcas=marcas,
        estado=estado,
        marca=marca,
    )


def campos_carro(origen, estado_actual=None):
    campos = [
        campo("vin", "Número de chasis", valor=origen.get("vin", "")),
        campo("marca", "Marca", valor=origen.get("marca", "")),
        campo("modelo", "Modelo", valor=origen.get("modelo", "")),
        campo("anio", "Año", tipo="number", valor=origen.get("anio", "")),
        campo("precio", "Precio de venta", tipo="number", valor=origen.get("precio", "")),
        campo(
            "sede_id",
            "Sede",
            tipo="select",
            valor=origen.get("sede_id", ""),
            opciones=opciones_sedes(),
        ),
    ]
    if estado_actual:
        campos.append(campo("estado", "Estado de inventario", tipo="info", valor=estado_actual))
    return campos


def leer_carro():
    return (
        texto("vin", 50, "El número de chasis"),
        texto("marca", 50, "La marca"),
        texto("modelo", 50, "El modelo"),
        entero("anio", 1980, 2100, "El año"),
        dinero("precio", "El precio", Decimal("9999999999.99")),
        entero("sede_id", 1, 10**9, "La sede"),
    )


@app.route("/carros/nuevo", methods=["GET", "POST"])
def carro_nuevo():
    bloqueo = exigir("carros", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {}
    if request.method == "POST":
        try:
            ejecutar(
                """
                INSERT INTO CARROS (VIN, Marca, Modelo, Anio, Precio_Venta, SedeID)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                leer_carro(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Vehículo ingresado al inventario. Queda disponible.", "ok")
            return redirect(url_for("carros"))
    return render_template(
        "formulario.html",
        titulo="Nuevo vehículo",
        descripcion="El carro entra como Disponible. Al venderlo, pasa a Vendido.",
        campos=campos_carro(origen),
        volver=url_for("carros"),
    )


@app.route("/carros/<int:registro_id>/editar", methods=["GET", "POST"])
def carro_editar(registro_id):
    bloqueo = exigir("carros", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        """
        SELECT CarroID, VIN, Marca, Modelo, Anio, Precio_Venta, SedeID, Estado_Inventario
        FROM CARROS WHERE CarroID = %s
        """,
        (registro_id,),
    )
    if fila is None:
        flash("Ese vehículo ya no existe.", "error")
        return redirect(url_for("carros"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE CARROS
                   SET VIN = %s, Marca = %s, Modelo = %s, Anio = %s,
                       Precio_Venta = %s, SedeID = %s
                 WHERE CarroID = %s
                """,
                (*leer_carro(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Vehículo actualizado.", "ok")
            return redirect(url_for("carros"))
        origen = request.form
    else:
        origen = {
            "vin": fila["VIN"],
            "marca": fila["Marca"],
            "modelo": fila["Modelo"],
            "anio": fila["Anio"],
            "precio": fila["Precio_Venta"],
            "sede_id": fila["SedeID"],
        }
    return render_template(
        "formulario.html",
        titulo="Editar vehículo",
        descripcion="Si cambias el precio, las ventas ya hechas conservan el valor de ese día.",
        campos=campos_carro(origen, fila["Estado_Inventario"]),
        volver=url_for("carros"),
    )


@app.post("/carros/<int:registro_id>/eliminar")
def carro_eliminar(registro_id):
    bloqueo = exigir("carros", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM CARROS WHERE CarroID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Vehículo eliminado.", "ok")
    return redirect(url_for("carros"))


@app.route("/ventas")
def ventas():
    bloqueo = exigir("ventas", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar(
        """
        SELECT VentaID, Cliente, Vendedor, Marca, Modelo, Anio, Monto_Total, Forma_Pago, Fecha_Venta, Sede
        FROM vw_detalle_ventas
        ORDER BY Fecha_Venta DESC, VentaID DESC
        """
    )
    return render_lista(
        titulo="Ventas",
        descripcion="Al registrar una venta, el carro queda vendido.",
        modulo="ventas",
        columnas=[
            ("Fecha_Venta", "Fecha", "fecha"),
            ("Cliente", "Cliente", None),
            ("Vendedor", "Vendedor", None),
            ("Marca", "Marca", None),
            ("Modelo", "Modelo", None),
            ("Sede", "Sede", None),
            ("Forma_Pago", "Pago", None),
            ("Monto_Total", "Monto", "cop"),
        ],
        filas=filas,
        id_campo="VentaID",
        url_nuevo=url_for("venta_nueva"),
        endpoint_editar=None,
        endpoint_eliminar="venta_eliminar",
    )


@app.route("/ventas/nueva", methods=["GET", "POST"])
def venta_nueva():
    bloqueo = exigir("ventas", "crear")
    if bloqueo:
        return bloqueo
    if request.method == "POST":
        try:
            ejecutar(
                "CALL sp_registrar_venta(%s, %s, %s, %s)",
                (
                    entero("client_id", 1, 10**9, "El cliente"),
                    entero("vendedor_id", 1, 10**9, "El vendedor"),
                    entero("carro_id", 1, 10**9, "El vehículo"),
                    texto("forma_pago", 50, "La forma de pago"),
                ),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Venta registrada. El carro quedó vendido.", "ok")
            return redirect(url_for("ventas"))
    origen = request.form if request.method == "POST" else {}
    return render_template(
        "formulario.html",
        titulo="Registrar venta",
        descripcion="El precio se toma del vehículo. No hay que escribirlo.",
        campos=[
            campo(
                "client_id",
                "Cliente",
                tipo="select",
                valor=origen.get("client_id", ""),
                opciones=opciones_personas("CLIENTE", "ClientID"),
            ),
            campo(
                "vendedor_id",
                "Vendedor",
                tipo="select",
                valor=origen.get("vendedor_id", ""),
                opciones=opciones_personas("VENDEDOR", "VendedorID"),
            ),
            campo(
                "carro_id",
                "Vehículo disponible",
                tipo="select",
                valor=origen.get("carro_id", ""),
                opciones=opciones_carros(solo_disponibles=True),
            ),
            campo(
                "forma_pago",
                "Forma de pago",
                tipo="select",
                valor=origen.get("forma_pago", "Contado"),
                opciones=[
                    {"valor": "Contado", "texto": "Contado"},
                    {"valor": "Financiado", "texto": "Financiado"},
                    {"valor": "Tarjeta", "texto": "Tarjeta"},
                ],
            ),
        ],
        volver=url_for("ventas"),
    )


@app.post("/ventas/<int:registro_id>/eliminar")
def venta_eliminar(registro_id):
    bloqueo = exigir("ventas", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("CALL sp_anular_venta(%s)", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Venta anulada. El carro volvió a estar disponible.", "ok")
    return redirect(url_for("ventas"))


@app.route("/mantenimientos")
def mantenimientos():
    bloqueo = exigir("mantenimientos", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar(
        """
        SELECT m.MantenimientoID, m.Fecha_Servicio, m.Descripcion_Servicio, m.Costo_Servicio,
               CONCAT(c.Marca, ' ', c.Modelo) AS Vehiculo,
               CONCAT(cl.Nombre, ' ', cl.Apellido) AS Cliente
        FROM MANTENIMIENTO m
        JOIN CARROS c ON c.CarroID = m.CarroID
        LEFT JOIN CLIENTE cl ON cl.ClientID = m.ClientID
        ORDER BY m.Fecha_Servicio DESC, m.MantenimientoID DESC
        """
    )
    return render_lista(
        titulo="Taller",
        descripcion="También puedes anotar el taller de un carro ya vendido.",
        modulo="mantenimientos",
        columnas=[
            ("Fecha_Servicio", "Fecha", "fecha"),
            ("Vehiculo", "Vehículo", None),
            ("Cliente", "Cliente", None),
            ("Descripcion_Servicio", "Servicio", None),
            ("Costo_Servicio", "Costo", "cop"),
        ],
        filas=filas,
        id_campo="MantenimientoID",
        url_nuevo=url_for("mantenimiento_nuevo"),
        endpoint_editar="mantenimiento_editar",
        endpoint_eliminar="mantenimiento_eliminar",
    )


def campos_mantenimiento(origen):
    return [
        campo(
            "carro_id",
            "Vehículo",
            tipo="select",
            valor=origen.get("carro_id", ""),
            opciones=opciones_carros(),
        ),
        campo(
            "client_id",
            "Cliente",
            tipo="select",
            valor=origen.get("client_id", ""),
            requerido=False,
            opciones=opciones_personas("CLIENTE", "ClientID", vacio="Sin cliente"),
        ),
        campo(
            "vendedor_id",
            "Asesor",
            tipo="select",
            valor=origen.get("vendedor_id", ""),
            requerido=False,
            opciones=opciones_personas("VENDEDOR", "VendedorID", vacio="Sin asesor"),
        ),
        campo("fecha", "Fecha del servicio", tipo="date", valor=origen.get("fecha", "")),
        campo("descripcion", "Descripción", tipo="textarea", valor=origen.get("descripcion", "")),
        campo("costo", "Costo", tipo="number", valor=origen.get("costo", "")),
    ]


def leer_mantenimiento():
    cliente = request.form.get("client_id", "").strip()
    asesor = request.form.get("vendedor_id", "").strip()
    return (
        entero("carro_id", 1, 10**9, "El vehículo"),
        int(cliente) if cliente.isdigit() else None,
        int(asesor) if asesor.isdigit() else None,
        fecha_form("fecha", "La fecha"),
        texto("descripcion", 2000, "La descripción"),
        dinero("costo", "El costo", Decimal("99999999.99")),
    )


@app.route("/mantenimientos/nuevo", methods=["GET", "POST"])
def mantenimiento_nuevo():
    bloqueo = exigir("mantenimientos", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {"fecha": date.today().isoformat()}
    if request.method == "POST":
        try:
            ejecutar(
                """
                INSERT INTO MANTENIMIENTO
                  (CarroID, ClientID, VendedorID, Fecha_Servicio, Descripcion_Servicio, Costo_Servicio)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                leer_mantenimiento(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Servicio registrado.", "ok")
            return redirect(url_for("mantenimientos"))
    return render_template(
        "formulario.html",
        titulo="Nuevo servicio",
        campos=campos_mantenimiento(origen),
        volver=url_for("mantenimientos"),
    )


@app.route("/mantenimientos/<int:registro_id>/editar", methods=["GET", "POST"])
def mantenimiento_editar(registro_id):
    bloqueo = exigir("mantenimientos", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        """
        SELECT MantenimientoID, CarroID, ClientID, VendedorID, Fecha_Servicio,
               Descripcion_Servicio, Costo_Servicio
        FROM MANTENIMIENTO WHERE MantenimientoID = %s
        """,
        (registro_id,),
    )
    if fila is None:
        flash("Ese servicio ya no existe.", "error")
        return redirect(url_for("mantenimientos"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE MANTENIMIENTO
                   SET CarroID = %s, ClientID = %s, VendedorID = %s, Fecha_Servicio = %s,
                       Descripcion_Servicio = %s, Costo_Servicio = %s
                 WHERE MantenimientoID = %s
                """,
                (*leer_mantenimiento(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Servicio actualizado.", "ok")
            return redirect(url_for("mantenimientos"))
        origen = request.form
    else:
        origen = {
            "carro_id": fila["CarroID"],
            "client_id": fila["ClientID"] or "",
            "vendedor_id": fila["VendedorID"] or "",
            "fecha": fila["Fecha_Servicio"],
            "descripcion": fila["Descripcion_Servicio"],
            "costo": fila["Costo_Servicio"],
        }
    return render_template(
        "formulario.html",
        titulo="Editar servicio",
        campos=campos_mantenimiento(origen),
        volver=url_for("mantenimientos"),
    )


@app.post("/mantenimientos/<int:registro_id>/eliminar")
def mantenimiento_eliminar(registro_id):
    bloqueo = exigir("mantenimientos", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM MANTENIMIENTO WHERE MantenimientoID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Servicio eliminado.", "ok")
    return redirect(url_for("mantenimientos"))


@app.route("/sedes")
def sedes():
    bloqueo = exigir("catalogo", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar("SELECT SedeID, Nombre_Sede, Direccion, Ciudad, Telefono FROM SEDE ORDER BY Nombre_Sede")
    return render_lista(
        titulo="Sedes",
        descripcion="Las tres ciudades donde está el concesionario.",
        modulo="catalogo",
        columnas=[
            ("Nombre_Sede", "Sede", None),
            ("Ciudad", "Ciudad", None),
            ("Direccion", "Dirección", None),
            ("Telefono", "Teléfono", None),
        ],
        filas=filas,
        id_campo="SedeID",
        url_nuevo=url_for("sede_nueva"),
        endpoint_editar="sede_editar",
        endpoint_eliminar="sede_eliminar",
    )


def campos_sede(origen):
    return [
        campo("nombre", "Nombre", valor=origen.get("nombre", "")),
        campo("ciudad", "Ciudad", valor=origen.get("ciudad", "")),
        campo("direccion", "Dirección", valor=origen.get("direccion", "")),
        campo("telefono", "Teléfono", valor=origen.get("telefono", "")),
    ]


def leer_sede():
    return (
        texto("nombre", 100, "El nombre"),
        texto("direccion", 150, "La dirección"),
        texto("ciudad", 100, "La ciudad"),
        texto("telefono", 20, "El teléfono"),
    )


@app.route("/sedes/nueva", methods=["GET", "POST"])
def sede_nueva():
    bloqueo = exigir("catalogo", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {}
    if request.method == "POST":
        try:
            ejecutar(
                "INSERT INTO SEDE (Nombre_Sede, Direccion, Ciudad, Telefono) VALUES (%s, %s, %s, %s)",
                leer_sede(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Sede registrada.", "ok")
            return redirect(url_for("sedes"))
    return render_template(
        "formulario.html", titulo="Nueva sede", campos=campos_sede(origen), volver=url_for("sedes")
    )


@app.route("/sedes/<int:registro_id>/editar", methods=["GET", "POST"])
def sede_editar(registro_id):
    bloqueo = exigir("catalogo", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        "SELECT SedeID, Nombre_Sede, Direccion, Ciudad, Telefono FROM SEDE WHERE SedeID = %s",
        (registro_id,),
    )
    if fila is None:
        flash("Esa sede ya no existe.", "error")
        return redirect(url_for("sedes"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE SEDE
                   SET Nombre_Sede = %s, Direccion = %s, Ciudad = %s, Telefono = %s
                 WHERE SedeID = %s
                """,
                (*leer_sede(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Sede actualizada.", "ok")
            return redirect(url_for("sedes"))
        origen = request.form
    else:
        origen = {
            "nombre": fila["Nombre_Sede"],
            "direccion": fila["Direccion"],
            "ciudad": fila["Ciudad"],
            "telefono": fila["Telefono"],
        }
    return render_template(
        "formulario.html", titulo="Editar sede", campos=campos_sede(origen), volver=url_for("sedes")
    )


@app.post("/sedes/<int:registro_id>/eliminar")
def sede_eliminar(registro_id):
    bloqueo = exigir("catalogo", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM SEDE WHERE SedeID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Sede eliminada.", "ok")
    return redirect(url_for("sedes"))


@app.route("/vendedores")
def vendedores():
    bloqueo = exigir("catalogo", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar(
        """
        SELECT v.VendedorID, v.Nombre, v.Apellido, v.DNI, v.Telefono, s.Nombre_Sede
        FROM VENDEDOR v
        JOIN SEDE s ON s.SedeID = v.SedeID
        ORDER BY v.Apellido, v.Nombre
        """
    )
    return render_lista(
        titulo="Vendedores",
        descripcion="Cada vendedor trabaja en una sede.",
        modulo="catalogo",
        columnas=[
            ("Nombre", "Nombre", None),
            ("Apellido", "Apellido", None),
            ("DNI", "Cédula", None),
            ("Telefono", "Teléfono", None),
            ("Nombre_Sede", "Sede", None),
        ],
        filas=filas,
        id_campo="VendedorID",
        url_nuevo=url_for("vendedor_nuevo"),
        endpoint_editar="vendedor_editar",
        endpoint_eliminar="vendedor_eliminar",
    )


def campos_vendedor(origen):
    return [
        campo("nombre", "Nombre", valor=origen.get("nombre", "")),
        campo("apellido", "Apellido", valor=origen.get("apellido", "")),
        campo("dni", "Cédula", valor=origen.get("dni", "")),
        campo("telefono", "Teléfono", valor=origen.get("telefono", ""), requerido=False),
        campo(
            "sede_id",
            "Sede",
            tipo="select",
            valor=origen.get("sede_id", ""),
            opciones=opciones_sedes(),
        ),
    ]


def leer_vendedor():
    return (
        texto("nombre", 50, "El nombre"),
        texto("apellido", 50, "El apellido"),
        texto("dni", 20, "La cédula"),
        texto("telefono", 20, "El teléfono", requerido=False),
        entero("sede_id", 1, 10**9, "La sede"),
    )


@app.route("/vendedores/nuevo", methods=["GET", "POST"])
def vendedor_nuevo():
    bloqueo = exigir("catalogo", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {}
    if request.method == "POST":
        try:
            ejecutar(
                """
                INSERT INTO VENDEDOR (Nombre, Apellido, DNI, Telefono, SedeID)
                VALUES (%s, %s, %s, %s, %s)
                """,
                leer_vendedor(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Vendedor registrado.", "ok")
            return redirect(url_for("vendedores"))
    return render_template(
        "formulario.html",
        titulo="Nuevo vendedor",
        campos=campos_vendedor(origen),
        volver=url_for("vendedores"),
    )


@app.route("/vendedores/<int:registro_id>/editar", methods=["GET", "POST"])
def vendedor_editar(registro_id):
    bloqueo = exigir("catalogo", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        "SELECT VendedorID, Nombre, Apellido, DNI, Telefono, SedeID FROM VENDEDOR WHERE VendedorID = %s",
        (registro_id,),
    )
    if fila is None:
        flash("Ese vendedor ya no existe.", "error")
        return redirect(url_for("vendedores"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE VENDEDOR
                   SET Nombre = %s, Apellido = %s, DNI = %s, Telefono = %s, SedeID = %s
                 WHERE VendedorID = %s
                """,
                (*leer_vendedor(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Vendedor actualizado.", "ok")
            return redirect(url_for("vendedores"))
        origen = request.form
    else:
        origen = {
            "nombre": fila["Nombre"],
            "apellido": fila["Apellido"],
            "dni": fila["DNI"],
            "telefono": fila["Telefono"],
            "sede_id": fila["SedeID"],
        }
    return render_template(
        "formulario.html",
        titulo="Editar vendedor",
        campos=campos_vendedor(origen),
        volver=url_for("vendedores"),
    )


@app.post("/vendedores/<int:registro_id>/eliminar")
def vendedor_eliminar(registro_id):
    bloqueo = exigir("catalogo", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM VENDEDOR WHERE VendedorID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Vendedor eliminado.", "ok")
    return redirect(url_for("vendedores"))


@app.route("/proveedores")
def proveedores():
    bloqueo = exigir("catalogo", "ver")
    if bloqueo:
        return bloqueo
    filas = ejecutar(
        """
        SELECT ProveedorID, Nombre_Proveedor, Contacto, Telefono, Direccion
        FROM PROVEEDOR
        ORDER BY Nombre_Proveedor
        """
    )
    return render_lista(
        titulo="Proveedores",
        descripcion="Empresas que le venden los carros al concesionario.",
        modulo="catalogo",
        columnas=[
            ("Nombre_Proveedor", "Proveedor", None),
            ("Contacto", "Contacto", None),
            ("Telefono", "Teléfono", None),
            ("Direccion", "Dirección", None),
        ],
        filas=filas,
        id_campo="ProveedorID",
        url_nuevo=url_for("proveedor_nuevo"),
        endpoint_editar="proveedor_editar",
        endpoint_eliminar="proveedor_eliminar",
    )


def campos_proveedor(origen):
    return [
        campo("nombre", "Nombre", valor=origen.get("nombre", "")),
        campo("contacto", "Contacto", valor=origen.get("contacto", ""), requerido=False),
        campo("telefono", "Teléfono", valor=origen.get("telefono", ""), requerido=False),
        campo("direccion", "Dirección", valor=origen.get("direccion", ""), requerido=False),
    ]


def leer_proveedor():
    return (
        texto("nombre", 100, "El nombre"),
        texto("contacto", 100, "El contacto", requerido=False),
        texto("telefono", 20, "El teléfono", requerido=False),
        texto("direccion", 150, "La dirección", requerido=False),
    )


@app.route("/proveedores/nuevo", methods=["GET", "POST"])
def proveedor_nuevo():
    bloqueo = exigir("catalogo", "crear")
    if bloqueo:
        return bloqueo
    origen = request.form if request.method == "POST" else {}
    if request.method == "POST":
        try:
            ejecutar(
                """
                INSERT INTO PROVEEDOR (Nombre_Proveedor, Contacto, Telefono, Direccion)
                VALUES (%s, %s, %s, %s)
                """,
                leer_proveedor(),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Proveedor registrado.", "ok")
            return redirect(url_for("proveedores"))
    return render_template(
        "formulario.html",
        titulo="Nuevo proveedor",
        campos=campos_proveedor(origen),
        volver=url_for("proveedores"),
    )


@app.route("/proveedores/<int:registro_id>/editar", methods=["GET", "POST"])
def proveedor_editar(registro_id):
    bloqueo = exigir("catalogo", "editar")
    if bloqueo:
        return bloqueo
    fila = uno(
        """
        SELECT ProveedorID, Nombre_Proveedor, Contacto, Telefono, Direccion
        FROM PROVEEDOR WHERE ProveedorID = %s
        """,
        (registro_id,),
    )
    if fila is None:
        flash("Ese proveedor ya no existe.", "error")
        return redirect(url_for("proveedores"))
    if request.method == "POST":
        try:
            ejecutar(
                """
                UPDATE PROVEEDOR
                   SET Nombre_Proveedor = %s, Contacto = %s, Telefono = %s, Direccion = %s
                 WHERE ProveedorID = %s
                """,
                (*leer_proveedor(), registro_id),
            )
        except ValidationError as exc:
            flash(str(exc), "error")
        else:
            flash("Proveedor actualizado.", "ok")
            return redirect(url_for("proveedores"))
        origen = request.form
    else:
        origen = {
            "nombre": fila["Nombre_Proveedor"],
            "contacto": fila["Contacto"],
            "telefono": fila["Telefono"],
            "direccion": fila["Direccion"],
        }
    return render_template(
        "formulario.html",
        titulo="Editar proveedor",
        campos=campos_proveedor(origen),
        volver=url_for("proveedores"),
    )


@app.post("/proveedores/<int:registro_id>/eliminar")
def proveedor_eliminar(registro_id):
    bloqueo = exigir("catalogo", "eliminar")
    if bloqueo:
        return bloqueo
    try:
        ejecutar("DELETE FROM PROVEEDOR WHERE ProveedorID = %s", (registro_id,))
    except ValidationError as exc:
        flash(str(exc), "error")
    else:
        flash("Proveedor eliminado.", "ok")
    return redirect(url_for("proveedores"))


@app.errorhandler(400)
def error_csrf(_exc):
    return render_template("error.html", mensaje="El formulario expiró. Vuelve a enviarlo."), 400


@app.errorhandler(404)
def error_404(_exc):
    return render_template("error.html", mensaje="Esa página no existe."), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
