#!/bin/sh
# Start command for every provider, so app boot work is the same everywhere.
set -eu
cd "$(dirname "$0")/.."

# Each marker carries the wall-clock time in epoch milliseconds, so a parser does not depend on the time at which
# the provider received the log line. A `date` without %N (BusyBox) falls back to whole seconds.
mark() {
  now="$(date +%s%3N)"
  case "$now" in *[!0-9]*) now="$(date +%s)000" ;; esac
  printf '::bench::%s %s\n' "$1" "$now"
}

mark start

# Render and Railpack install into the repo-local .venv. Railpack puts it on PATH only with its default install
# command, so add it here. The Docker images have /opt/venv on PATH instead.
if [ -x .venv/bin/python ]; then
  PATH="$PWD/.venv/bin:$PATH"
  export PATH
fi

# The SQLite file is in /tmp, the only path that is writable on every provider. It starts empty on each new
# instance, so the migrations run at boot, before the server opens its port.
export DATABASE_URL="${DATABASE_URL:-sqlite:////tmp/conduit.sqlite3}"
# Provider hostnames differ (onrender.com, up.railway.app, vercel.app, fly.dev, deployment URLs).
export ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"

python manage.py migrate --noinput
exec gunicorn config.wsgi --config bench/gunicorn.conf.py --bind "0.0.0.0:${PORT:-8000}" --access-logfile -
