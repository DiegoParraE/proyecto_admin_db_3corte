#!/bin/sh
# Backup logico con rutinas y triggers. Sobreescribe database/concesionario_backup.sql
set -eu
cd "$(dirname "$0")/.."
tmp="database/.backup_tmp.sql"
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
  echo "-- Generado con database/generar_backup.sh (mysqldump --routines --triggers)."
  echo "-- Restaurar: ./database/demo_backup.sh --confirmar"
  echo ""
  cat "$tmp"
} > database/concesionario_backup.sql
rm -f "$tmp"
echo "Backup escrito en database/concesionario_backup.sql"
