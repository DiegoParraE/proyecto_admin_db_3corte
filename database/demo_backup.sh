#!/bin/sh
# Sustentacion: borrar ventas y recuperarlas desde el backup logico.
# Ejecutar desde la raiz: ./database/demo_backup.sh --confirmar
set -eu
cd "$(dirname "$0")/.."

if [ "${1:-}" != "--confirmar" ]; then
  echo "Este script borra las ventas y restaura database/concesionario_backup.sql"
  echo "Uso: ./database/demo_backup.sh --confirmar"
  exit 1
fi

if [ ! -f database/concesionario_backup.sql ]; then
  echo "No esta database/concesionario_backup.sql"
  echo "Generelo con: ./database/generar_backup.sh"
  exit 1
fi

echo ""
echo "=== Ventas antes de borrar ==="
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot --table -e "SELECT VentaID, CarroID, Monto_Total, Fecha_Venta FROM concesionario_db.VENTA;"

echo "=== Borrando ventas de prueba ==="
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot -e "DELETE FROM concesionario_db.VENTA; SELECT COUNT(*) AS ventas_despues_de_borrar FROM concesionario_db.VENTA;"

echo "=== Restaurando backup ==="
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot < database/concesionario_backup.sql

echo "=== Ventas recuperadas ==="
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot --table -e "SELECT VentaID, CarroID, Monto_Total, Fecha_Venta FROM concesionario_db.VENTA;"
