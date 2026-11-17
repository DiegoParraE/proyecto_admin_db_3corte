#!/bin/sh
# Sustentacion: EXPLAIN antes y despues del indice.
# Ejecutar desde la raiz: ./base_de_datos/demo_explain.sh
set -eu
cd "$(dirname "$0")/.."
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot --table concesionario_db < base_de_datos/demo_explain.sql
