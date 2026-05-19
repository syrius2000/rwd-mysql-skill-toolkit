#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_SATELLITE="$(cd "$ROOT/.." && pwd)/agentic-evidence-analysis"
SATELLITE="${AGENTIC_EVIDENCE_ANALYSIS_DIR:-$DEFAULT_SATELLITE}"
MODE="sync"

SKILLS=(
  "questionnaire-batch-analysis"
  "vcd-bayesian-evidence-analysis"
  "vcd-categorical-analysis"
  "vcd-categorical-reporting"
  "vcd-pass0-consultation"
)

usage() {
  cat <<'USAGE'
Usage: scripts/sync-agentic-evidence-skills.sh [OPTIONS]

Sync the five shared VCD/Questionnaire skills from rwd-mysql-skill-toolkit
to agentic-evidence-analysis.

Options:
  --check              Only compare the shared skills; do not copy files.
  --satellite <dir>    Path to agentic-evidence-analysis.
  -h, --help           Show this help.

Environment:
  AGENTIC_EVIDENCE_ANALYSIS_DIR  Default satellite path override.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --satellite)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        echo "sync-agentic-evidence-skills: --satellite requires a directory" >&2
        exit 2
      fi
      SATELLITE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "sync-agentic-evidence-skills: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SATELLITE="$(cd "$SATELLITE" && pwd)"
SRC_ROOT="$ROOT/.agent/skills"
DST_ROOT="$SATELLITE/.agent/skills"

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "sync-agentic-evidence-skills: missing source directory: $SRC_ROOT" >&2
  exit 1
fi

if [[ ! -d "$DST_ROOT" ]]; then
  echo "sync-agentic-evidence-skills: missing destination directory: $DST_ROOT" >&2
  exit 1
fi

check_skill() {
  local skill="$1"
  local src="$SRC_ROOT/$skill"
  local dst="$DST_ROOT/$skill"

  if [[ ! -d "$src" ]]; then
    echo "sync-agentic-evidence-skills: missing source skill: $src" >&2
    return 1
  fi
  if [[ ! -d "$dst" ]]; then
    echo "sync-agentic-evidence-skills: missing destination skill: $dst" >&2
    return 1
  fi
  diff -qr "$src" "$dst"
}

if [[ "$MODE" == "check" ]]; then
  for skill in "${SKILLS[@]}"; do
    check_skill "$skill"
  done
  echo "sync-agentic-evidence-skills: OK (shared skills match)"
  exit 0
fi

for skill in "${SKILLS[@]}"; do
  src="$SRC_ROOT/$skill/"
  dst="$DST_ROOT/$skill/"
  if [[ ! -d "$src" ]]; then
    echo "sync-agentic-evidence-skills: missing source skill: $src" >&2
    exit 1
  fi
  mkdir -p "$dst"
  rsync -a --delete "$src" "$dst"
done

for skill in "${SKILLS[@]}"; do
  check_skill "$skill"
done

echo "sync-agentic-evidence-skills: OK (toolkit -> agentic shared skills)"
