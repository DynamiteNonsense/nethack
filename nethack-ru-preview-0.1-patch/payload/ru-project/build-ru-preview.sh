#!/usr/bin/env bash
# Incremental Windows x64 build. Never deletes saved games or cleans binary/.
set -euo pipefail
if [[ "${MSYSTEM:-}" != UCRT64 ]]; then
    printf '%s\n' 'Use MSYS2 UCRT64 on Windows x64.' >&2
    exit 1
fi
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
for tool in gcc g++ windres make curl tar; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'Missing: %s\n' "$tool" >&2; exit 1; }
done
mkdir -p ru-project/test-build
gcc -std=c99 -Wall -Wextra -Werror ru-project/test_messages.c -o ru-project/test-build/test_messages.exe
NETHACK_RU=1 ru-project/test-build/test_messages.exe
NETHACK_RU=0 ru-project/test-build/test_messages.exe --expect-disabled
if [[ ! -f lib/lua-5.4.8/src/lua.h && ! -f submodules/lua/lua.h ]]; then
    mkdir -p lib
    curl --fail --location --proto '=https' --proto-redir '=https' \
      https://www.lua.org/ftp/lua-5.4.8.tar.gz -o lib/lua-5.4.8.tar.gz
    tar -xzf lib/lua-5.4.8.tar.gz -C lib
fi
cp sys/windows/GNUmakefile sys/windows/GNUmakefile.depend src/
make -C src binary INTERNET_AVAILABLE=N SKIP_NETHACKW=Y DEBUGINFO=N NHV=500
test -s binary/nhdat500
printf '%s\n' 'RU preview 0.1 build complete. Output: binary/.'
printf '%s\n' 'Partial translation only: 285 exact game messages, Windows TTY.'
