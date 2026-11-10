#!/bin/sh
# Build steps for every provider. The ::bench:: markers delimit the install and build phases in the build log.
set -eu

install() {
  printf '%s\n' '::bench::install_start'
  python -m pip install --disable-pip-version-check --require-hashes -r requirements.txt
  printf '%s\n' '::bench::install_done'
}

# Python has no compile step that the app needs. The closest equivalent is the bytecode compile of the app
# sources, plus the commit file that /version serves.
build() {
  printf '%s\n' '::bench::build_start'
  python -m compileall -q apps config helpers manage.py
  write_commit
  printf '%s\n' '::bench::build_done'
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
