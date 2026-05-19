#!/usr/bin/env bash
set -u

usage() {
  cat >&2 <<'USAGE'
usage: install-skill.sh [--dry-run] [--source DIR] [--target DIR ...]

Installs the cli-collaboration skill directory into explicit targets. If no
target is supplied, defaults to:
  ${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration
  ${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration
USAGE
}

dry_run=0
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
targets=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --source)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      source_dir="$2"
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      targets+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ -d "$source_dir" ] || { echo "source not found: $source_dir" >&2; exit 2; }

if [ "${#targets[@]}" -eq 0 ]; then
  targets+=("${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration")
  targets+=("${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration")
fi

for target in "${targets[@]}"; do
  echo "install: $source_dir -> $target"
  if [ "$dry_run" -eq 1 ]; then
    continue
  fi

  parent="$(dirname "$target")"
  mkdir -p "$parent"

  if [ -e "$target" ]; then
    if diff -qr "$source_dir" "$target" >/dev/null 2>&1; then
      echo "unchanged: $target"
      continue
    fi
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "backup: $backup"
  fi

  cp -R "$source_dir" "$target"
done
