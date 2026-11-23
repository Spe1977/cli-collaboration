#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: sync-skill.sh [--install] [--source DIR] [--target DIR ...]
                     [--codex] [--agents] [--grok] [--claude]
                     [--antigravity] [--gemini] [--all]

Reports drift between the source skill and install targets. Read-only by
default. Use --install to delegate updates to install-skill.sh.
USAGE
}

install=0
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    --install) install=1; shift ;;
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

drift=0
for target in "${targets[@]}"; do
  if [ ! -d "$target" ]; then
    echo "missing: $target"
    drift=1
    continue
  fi

  if diff -qr "$source_dir" "$target" >/dev/null 2>&1; then
    echo "in-sync: $target"
  else
    echo "drift: $target"
    drift=1
  fi
done

if [ "$install" -eq 1 ]; then
  args=(--source "$source_dir")
  for target in "${targets[@]}"; do
    args+=(--target "$target")
  done
  "$script_dir/install-skill.sh" "${args[@]}"
  exit $?
fi

exit "$drift"
