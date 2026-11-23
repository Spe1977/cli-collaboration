#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: install-skill.sh [--dry-run] [--source DIR] [--target DIR ...]
                        [--codex] [--agents] [--grok] [--claude]
                        [--antigravity] [--gemini] [--all]

Installs the cli-collaboration skill directory into selected targets. If neither
--target nor any runtime preset flag is supplied, defaults to:
  ${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration
  ${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration
  ${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration

Preset flags:
  --codex        ${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration
  --agents       ${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration
  --grok         ${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration
  --claude       ${CLAUDE_HOME:-$HOME/.claude}/skills/cli-collaboration
  --antigravity  ${ANTIGRAVITY_CONFIG_HOME:-$HOME/.gemini/config}/skills/cli-collaboration
  --gemini       ${GEMINI_HOME:-$HOME/.gemini}/skills/cli-collaboration
                 (explicit opt-in: do not combine with --agents if Gemini CLI
                  already discovers ~/.agents/skills, to avoid duplicate errors)
  --all          --codex --agents --grok --claude --antigravity

Divergent pre-existing targets are backed up into a sibling `skills-backups/`
directory (outside the scanned `skills/` root) before copying, and restored
automatically if copying fails.

Exit codes:
  0  install completed (or unchanged) for every target
  2  usage error or invalid source
  3  install failed for a target; pre-existing target restored from backup
USAGE
}

dry_run=0
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
targets=()

add_target() {
  local candidate="$1"
  local existing
  while [ "$candidate" != "/" ] && [ "${candidate%/}" != "$candidate" ]; do
    candidate="${candidate%/}"
  done
  for existing in "${targets[@]+"${targets[@]}"}"; do
    if [ "$existing" = "$candidate" ]; then
      return 0
    fi
  done
  targets+=("$candidate")
}

codex_target()       { printf '%s/skills/cli-collaboration' "${CODEX_HOME:-$HOME/.codex}"; }
agents_target()      { printf '%s/skills/cli-collaboration' "${AGENTS_HOME:-$HOME/.agents}"; }
grok_target()        { printf '%s/skills/cli-collaboration' "${GROK_HOME:-$HOME/.grok}"; }
claude_target()      { printf '%s/skills/cli-collaboration' "${CLAUDE_HOME:-$HOME/.claude}"; }
antigravity_target() { printf '%s/skills/cli-collaboration' "${ANTIGRAVITY_CONFIG_HOME:-$HOME/.gemini/config}"; }
gemini_target()      { printf '%s/skills/cli-collaboration' "${GEMINI_HOME:-$HOME/.gemini}"; }

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
      add_target "$2"
      shift 2
      ;;
    --codex)       add_target "$(codex_target)"; shift ;;
    --agents)      add_target "$(agents_target)"; shift ;;
    --grok)        add_target "$(grok_target)"; shift ;;
    --claude)      add_target "$(claude_target)"; shift ;;
    --antigravity) add_target "$(antigravity_target)"; shift ;;
    --gemini)      add_target "$(gemini_target)"; shift ;;
    --all)
      add_target "$(codex_target)"
      add_target "$(agents_target)"
      add_target "$(grok_target)"
      add_target "$(claude_target)"
      add_target "$(antigravity_target)"
      shift
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
[ -f "$source_dir/SKILL.md" ] || {
  echo "source missing SKILL.md: $source_dir" >&2
  exit 2
}

if [ "${#targets[@]}" -eq 0 ]; then
  add_target "$(codex_target)"
  add_target "$(agents_target)"
  add_target "$(grok_target)"
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

  if [ -d "$target" ] && diff -qr "$source_dir" "$target" >/dev/null 2>&1; then
    echo "unchanged: $target"
    continue
  fi

  backup=""
  backup_root=""
  if [ -e "$target" ]; then
    grandparent="$(dirname "$parent")"
    skill_name="$(basename "$target")"
    backup_root="$grandparent/skills-backups"
    if ! mkdir -p "$backup_root"; then
      echo "install failed: could not create backup directory $backup_root" >&2
      exit 3
    fi
    backup="$backup_root/$skill_name.backup.$(date +%Y%m%d%H%M%S)"
    if [ -e "$backup" ]; then
      backup="${backup}.$$"
    fi
    if ! mv "$target" "$backup"; then
      echo "install failed: could not move $target to $backup" >&2
      rmdir "$backup_root" 2>/dev/null || true
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
        if [ -n "$backup_root" ]; then
          rmdir "$backup_root" 2>/dev/null || true
        fi
      else
        echo "rollback failed: $backup could not be restored to $target" >&2
      fi
    fi
    exit 3
  fi
done
