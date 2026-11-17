#!/bin/sh
# Muestra BEGIN + ROLLBACK: el cliente de prueba no queda guardado.
set -eu
cd "$(dirname "$0")/.."
docker compose exec -T db mysql -h 127.0.0.1 -uroot -proot --table concesionario_db < base_de_datos/demo_transaccion.sql
