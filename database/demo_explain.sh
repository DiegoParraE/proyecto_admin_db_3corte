#!/bin/sh
# Sustentacion: EXPLAIN antes y despues del indice.
# Ejecutar desde la raiz: ./database/demo_explain.sh
set -eu
cd "$(dirname "$0")/.."
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot --table concesionario_db < database/demo_explain.sql
