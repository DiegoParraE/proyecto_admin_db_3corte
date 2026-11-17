#!/bin/sh
# Backup logico con rutinas y triggers. Sobreescribe base_de_datos/concesionario_backup.sql
set -eu
cd "$(dirname "$0")/.."
tmp="base_de_datos/.backup_tmp.sql"
docker compose exec -T db mysqldump \
  -h 127.0.0.1 -uroot -proot \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  --databases concesionario_db > "$tmp"
{
  echo "-- Backup logico de concesionario_db para la sustentacion."
  echo "-- Generado con base_de_datos/generar_backup.sh (mysqldump --routines --triggers)."
  echo "-- Restaurar: ./base_de_datos/demo_backup.sh --confirmar"
  echo ""
  cat "$tmp"
} > base_de_datos/concesionario_backup.sql
rm -f "$tmp"
echo "Backup escrito en base_de_datos/concesionario_backup.sql"
