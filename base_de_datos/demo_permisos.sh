#!/bin/sh
# Sustentacion, minuto de administracion: un usuario sin permiso.
# Ejecutar desde la raiz del repositorio: ./base_de_datos/demo_permisos.sh
set -eu
cd "$(dirname "$0")/.."

echo ""
echo "=== Usuario consulta_concesionario intenta insertar un cliente ==="
echo "=== Debe fallar con ERROR 1142 (INSERT denegado) ==="
echo ""
set +e
docker compose exec -T db mysql -h 127.0.0.1 -uconsulta_concesionario -p'Consulta#2026' concesionario_db -e "INSERT INTO CLIENTE (Nombre, Apellido, DNI) VALUES ('Intruso', 'SinPermiso', '999999');"
codigo=$?
set -e
if [ "$codigo" -eq 0 ]; then
  echo "ERROR de la demo: la insercion no debio permitirse."
  exit 1
fi
echo ""
echo "Correcto: consulta_concesionario no puede insertar."
echo ""
echo "=== El mismo usuario intenta ejecutar sp_registrar_venta ==="
echo "=== Debe fallar: no tiene EXECUTE sobre ese procedimiento ==="
echo ""
set +e
docker compose exec -T db mysql -h 127.0.0.1 -uconsulta_concesionario -p'Consulta#2026' concesionario_db -e "CALL sp_registrar_venta(1, 1, 1, 'Contado');"
codigo=$?
set -e
if [ "$codigo" -eq 0 ]; then
  echo "ERROR de la demo: no debio poder vender."
  exit 1
fi
echo ""
echo "Correcto: tampoco puede registrar ventas."
echo "Si puede leer. Prueba manual:"
echo "  docker compose exec db mysql -h 127.0.0.1 -uconsulta_concesionario -p'Consulta#2026' concesionario_db -e 'SELECT COUNT(*) FROM CLIENTE;'"
