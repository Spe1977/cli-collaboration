#!/usr/bin/env bash
set -u

usage() {
  cat >&2 <<'USAGE'
usage: sync-skill.sh [--install] [--source DIR] [--target DIR ...]

Reports drift between the source skill and install targets. Read-only by
default. Use --install to delegate updates to install-skill.sh.
USAGE
}

install=0
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
targets=()

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

drift=0

for target in "${targets[@]}"; do
  if [ ! -e "$target" ]; then
    echo "missing: $target"
    drift=1
    continue
  fi

  if diff -qr "$source_dir" "$target" >/dev/null 2>&1; then
    echo "ok: $target"
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
