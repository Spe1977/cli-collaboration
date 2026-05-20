#!/usr/bin/env bash
set -u
set -o pipefail

usage() {
  cat >&2 <<'USAGE'
usage: install-skill.sh [--dry-run] [--source DIR] [--target DIR ...]

Installs the cli-collaboration skill directory into explicit targets. If no
target is supplied, defaults to:
  ${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration
  ${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration

Exit codes:
  0  install completed (or unchanged) for every target
  2  usage error or missing source directory
  3  install failed for a target; if a pre-existing target was backed up,
     it is restored automatically before exit
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
  if ! mkdir -p "$parent"; then
    echo "install failed: could not create parent directory $parent" >&2
    exit 3
  fi

  backup=""
  if [ -e "$target" ]; then
    if diff -qr "$source_dir" "$target" >/dev/null 2>&1; then
      echo "unchanged: $target"
      continue
    fi
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    if ! mv "$target" "$backup"; then
      echo "install failed: could not move $target to $backup" >&2
      exit 3
    fi
    echo "backup: $backup"
  fi

  if ! cp -R "$source_dir" "$target"; then
    echo "install failed: cp -R '$source_dir' -> '$target' returned non-zero" >&2
    if [ -n "$backup" ] && [ -e "$backup" ]; then
      rm -rf "$target" 2>/dev/null || true
      if mv "$backup" "$target"; then
        echo "rollback: restored $target from $backup" >&2
      else
        echo "rollback failed: $backup could not be restored to $target" >&2
      fi
    fi
    exit 3
  fi
done
