#!/bin/sh
set -eu

intentos=30
i=1
while [ "$i" -le "$intentos" ]; do
  if python - <<'PY'
import os
import sys
import pymysql

try:
    pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["AUTH_DB_USER"],
        password=os.environ["AUTH_DB_PASSWORD"],
        database=os.environ["DB_NAME"],
    ).close()
except Exception:
    sys.exit(1)
PY
  then
    break
  fi
  i=$((i + 1))
  sleep 2
done

exec gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 60 --access-logfile - --error-logfile - app:app
