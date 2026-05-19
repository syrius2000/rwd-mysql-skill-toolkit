#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SRC=".agent/skills/"
DST=".cursor/skills/"

if [[ ! -d "$SRC" ]]; then
  echo "sync-cursor-skills: missing $SRC" >&2
  exit 1
fi

mkdir -p "$DST"
rsync -a --delete "$SRC" "$DST"

if diff -rq "$SRC" "$DST" >/dev/null 2>&1; then
  echo "sync-cursor-skills: OK (.agent/skills == .cursor/skills)"
  exit 0
fi

echo "sync-cursor-skills: diff after rsync:" >&2
diff -rq "$SRC" "$DST" >&2 || true
exit 1
