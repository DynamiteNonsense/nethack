#!/usr/bin/env bash
# Preparation only: builds UNMODIFIED ENGLISH NetHack, not a localization.
set -euo pipefail
if [[ "${MSYSTEM:-}" != UCRT64 ]]; then
  printf '%s\n' 'Run this script in MSYS2 UCRT64 on Windows x64.' >&2
  exit 1
fi
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
for tool in gcc g++ windres make curl tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing tool: %s\n' "$tool" >&2
    exit 1
  fi
done
if [[ ! -f lib/lua-5.4.8/src/lua.h && ! -f submodules/lua/lua.h ]]; then
  mkdir -p lib
  curl --fail --location --proto '=https' --proto-redir '=https' \
    https://www.lua.org/ftp/lua-5.4.8.tar.gz -o lib/lua-5.4.8.tar.gz
  tar -xzf lib/lua-5.4.8.tar.gz -C lib
fi
cp sys/windows/GNUmakefile sys/windows/GNUmakefile.depend src/
cd src
# No clean: avoid deleting the user's prior build automatically.
make binary INTERNET_AVAILABLE=N SKIP_NETHACKW=Y DEBUGINFO=N NHV=500
printf '%s\n' 'Build finished. Inspect binary/ in the source root.'
printf '%s\n' 'This is the original English game. No Russian localization is installed.'
