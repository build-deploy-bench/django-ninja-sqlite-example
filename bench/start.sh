#!/bin/sh
# Start command for every provider, so app boot work is the same everywhere.
set -eu

# The SQLite file is in /tmp, the only path that is writable on every provider. It starts empty on each new
# instance, so the migrations run at boot, before the server opens its port.
export DATABASE_URL="${DATABASE_URL:-sqlite:////tmp/conduit.sqlite3}"
# Provider hostnames differ (onrender.com, up.railway.app, vercel.app, fly.dev, deployment URLs).
export ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"

python manage.py migrate --noinput
exec gunicorn config.wsgi --bind "0.0.0.0:${PORT:-8000}" --access-logfile -
