#!/bin/sh
# Build steps for every provider. The ::bench:: markers delimit the install and build phases in the build log.
set -eu

# Each marker carries the wall-clock time in epoch milliseconds, so a parser does not depend on the time at which
# the provider received the log line. A `date` without %N (BusyBox) falls back to whole seconds.
mark() {
  now="$(date +%s%3N)"
  case "$now" in *[!0-9]*) now="$(date +%s)000" ;; esac
  printf '::bench::%s %s\n' "$1" "$now"
}

install() {
  mark install_start
  # Railpack sets VIRTUAL_ENV and copies that venv into the image, but only its default install step creates it.
  # Render and the Dockerfiles have the venv already, so this is a no-op there.
  if [ -n "${VIRTUAL_ENV:-}" ] && [ ! -x "$VIRTUAL_ENV/bin/python" ]; then
    python -m venv "$VIRTUAL_ENV"
  fi
  "${VIRTUAL_ENV:+$VIRTUAL_ENV/bin/}python" -m pip install --disable-pip-version-check --require-hashes -r requirements.txt
  mark install_done
}

# Python has no compile step that the app needs. The closest equivalent is the bytecode compile of the app
# sources, plus the commit file that /version serves.
build() {
  mark build_start
  python -m compileall -q apps config helpers manage.py
  write_commit
  mark build_done
}

# The deployed commit comes from the build environment, so an old deployment keeps reporting its own commit.
# BENCH_COMMIT is for builds without a provider variable (Fly, local); git is the last resort.
write_commit() {
  commit="${BENCH_COMMIT:-${RENDER_GIT_COMMIT:-${RAILWAY_GIT_COMMIT_SHA:-${VERCEL_GIT_COMMIT_SHA:-}}}}"
  if [ -z "$commit" ]; then
    commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
  fi
  printf '%s\n' "$commit" > .build-commit
}

case "${1:-all}" in
  install) install ;;
  build) build ;;
  all) install; build ;;
  *) printf 'Usage: %s {install|build|all}\n' "$0" >&2; exit 2 ;;
esac
