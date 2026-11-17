#!/bin/sh
# Sustentacion: ejecutar sp_registrar_venta y mostrar el trigger.
# Ejecutar desde la raiz: ./base_de_datos/demo_procedimiento.sh
set -eu
cd "$(dirname "$0")/.."

echo ""
echo "=== Vendedor registra la primera unidad disponible con sp_registrar_venta ==="
docker compose exec -T db mysql -h 127.0.0.1 -uvendedor_concesionario -p'Vendedor#2026' --table concesionario_db <<'SQL'
SELECT CarroID INTO @carro
FROM CARROS
WHERE Estado_Inventario = 'Disponible'
ORDER BY CarroID
LIMIT 1;

SELECT @carro AS carro_elegido;

CALL sp_registrar_venta(3, 1, @carro, 'Contado');

SELECT CarroID, Marca, Modelo, Estado_Inventario
FROM CARROS
WHERE CarroID = @carro;
SQL

echo ""
echo "=== Auditoria escrita por trg_venta_after_insert (solo la ve el admin) ==="
docker compose exec -T db mysql -h 127.0.0.1 -uadmin_concesionario -p'Admin#2026' --table concesionario_db -e "SELECT AuditoriaID, Fecha_Hora, Tabla, Operacion, Usuario_DB, Detalle FROM AUDITORIA ORDER BY AuditoriaID DESC LIMIT 5;"

echo ""
echo "=== Insertar otra vez el carro recien vendido, sin procedimiento ==="
echo "=== Debe fallar con el mensaje de trg_venta_before_insert ==="
set +e
docker compose exec -T db mysql -h 127.0.0.1 -uvendedor_concesionario -p'Vendedor#2026' concesionario_db <<'SQL'
INSERT INTO VENTA (ClientID, VendedorID, CarroID, Fecha_Venta, Monto_Total, Forma_Pago)
SELECT 4, 1, CarroID, CURDATE(), 1000000, 'Contado'
FROM CARROS
WHERE Estado_Inventario = 'Vendido'
ORDER BY CarroID
LIMIT 1;
SQL
codigo=$?
set -e
if [ "$codigo" -eq 0 ]; then
  echo "ERROR de la demo: el trigger debio rechazar la segunda venta."
  exit 1
fi
echo ""
echo "Correcto: trg_venta_before_insert rechazo la venta duplicada."
