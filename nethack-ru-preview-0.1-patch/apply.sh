#!/usr/bin/env bash
# NetHack RU preview 0.1. Guarded source installer, 2026-09-09.
# Does not touch saved games, binary/, or user configuration files.
set -euo pipefail
if [[ $# -ne 1 ]]; then
    printf '%s\n' 'Usage: bash apply.sh /d/games/NetHack' >&2
    exit 2
fi
PKG="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$1" && pwd)"
test -f "$ROOT/include/hack.h" || { echo 'Not a NetHack source root.' >&2; exit 2; }
function hash_file() {
    local digest remainder
    read -r digest remainder < <(sha256sum -- "$1")
    printf '%s' "$digest"
}
# Validate every payload and every destination before writing anything.
while IFS=$'\t' read -r rel oldhash newhash; do
    [[ -n "$rel" ]] || continue
    [[ "$rel" != /* && "$rel" != *'..'* ]] || { echo 'Invalid manifest path.' >&2; exit 2; }
    [[ "$(hash_file "$PKG/payload/$rel")" == "$newhash" ]] || {
        printf 'Damaged package: %s\n' "$rel" >&2; exit 1;
    }
    if [[ -e "$ROOT/$rel" ]]; then
        current="$(hash_file "$ROOT/$rel")"
        if [[ "$current" != "$oldhash" && "$current" != "$newhash" ]]; then
            printf 'STOP: local changes in %s. No files have been updated.\n' "$rel" >&2
            exit 1
        fi
    elif [[ "$oldhash" != '-' ]]; then
        printf 'STOP: missing original file: %s\n' "$rel" >&2
        exit 1
    fi
done < "$PKG/manifest.tsv"
BACKUP="$ROOT/ru-project/backup-preview-0.1-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$BACKUP"
# Back up all existing destinations before replacing the first one.
while IFS=$'\t' read -r rel oldhash newhash; do
    [[ -n "$rel" ]] || continue
    if [[ -f "$ROOT/$rel" ]]; then
        mkdir -p "$BACKUP/$(dirname -- "$rel")"
        cp -p -- "$ROOT/$rel" "$BACKUP/$rel"
    fi
done < "$PKG/manifest.tsv"
while IFS=$'\t' read -r rel oldhash newhash; do
    [[ -n "$rel" ]] || continue
    mkdir -p "$ROOT/$(dirname -- "$rel")"
    cp -- "$PKG/payload/$rel" "$ROOT/$rel"
done < "$PKG/manifest.tsv"
printf 'Installed RU preview 0.1. Backup: %s\n' "$BACKUP"
printf '%s\n' 'Next: cd to the source root and run bash ru-project/build-ru-preview.sh'
