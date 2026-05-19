#!/usr/bin/env bash
set -u

usage() {
  cat >&2 <<'USAGE'
usage: check-ownership.sh [--handoff PATH] [--agent NAME] FILE...

Exit codes:
  0  handoff ownership is valid and no conflicts were detected
  1  requested file conflicts with agent-owned, user-reserved, or frozen ownership
  2  usage error or malformed/missing ownership section
USAGE
}

handoff="AGENT_HANDOFF.md"
agent="${CLI_COLLAB_AGENT:-Codex}"
files=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --handoff)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      handoff="$2"
      shift 2
      ;;
    --agent)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      agent="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        files+=("$1")
        shift
      done
      ;;
    -*)
      usage
      exit 2
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

[ -f "$handoff" ] || { echo "handoff not found: $handoff" >&2; exit 2; }

normalize_owner() {
  local value="$1"
  value="${value%%(*}"
  value="${value%%[[:space:]]}"
  printf '%s' "$value"
}

matches_pattern() {
  local pattern="$1"
  local path="$2"
  case "$path" in
    $pattern) return 0 ;;
    *) return 1 ;;
  esac
}

declare -a owned_patterns=()
declare -a owned_agents=()
declare -a user_patterns=()
declare -a frozen_patterns=()

current=""
valid_lines=0
malformed=0
in_ownership=0
seen_agent_owned=0
seen_user_reserved=0
seen_frozen=0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "## File ownership")
      in_ownership=1
      current=""
      continue
      ;;
    "## "*)
      if [ "$in_ownership" -eq 1 ]; then
        break
      fi
      ;;
  esac

  [ "$in_ownership" -eq 1 ] || continue

  case "$line" in
    "### agent-owned") current="agent-owned"; seen_agent_owned=1; continue ;;
    "### user-reserved") current="user-reserved"; seen_user_reserved=1; continue ;;
    "### frozen") current="frozen"; seen_frozen=1; continue ;;
    ""|" "*|"	"*) continue ;;
  esac

  if [[ "$line" == "- "* ]]; then
    if [ -z "$current" ]; then
      malformed=1
      continue
    fi
    entry="${line#- }"
    if [[ "$entry" != *:* ]]; then
      malformed=1
      continue
    fi
    path="${entry%%:*}"
    rest="${entry#*: }"
    rest="${rest//–/—}"
    rest="${rest// -- / — }"
    if [ -z "$path" ] || [ -z "$rest" ]; then
      malformed=1
      continue
    fi
    if [[ "$rest" == *" — "* ]]; then
      owner="${rest%% — *}"
    elif [[ "$rest" == *" - "* ]]; then
      owner="${rest%% - *}"
    elif [[ "$rest" == *"—"* ]]; then
      owner="${rest%%—*}"
    else
      malformed=1
      continue
    fi
    owner="$(normalize_owner "$owner")"
    if [ -z "$owner" ]; then
      malformed=1
      continue
    fi

    case "$current" in
      agent-owned)
        owned_patterns+=("$path")
        owned_agents+=("$owner")
        ;;
      user-reserved)
        user_patterns+=("$path")
        ;;
      frozen)
        frozen_patterns+=("$path")
        ;;
    esac
    valid_lines=$((valid_lines + 1))
  fi
done < "$handoff"

if [ "$in_ownership" -ne 1 ] || [ "$seen_agent_owned" -ne 1 ] || [ "$seen_user_reserved" -ne 1 ] || [ "$seen_frozen" -ne 1 ] || [ "$valid_lines" -eq 0 ] || [ "$malformed" -ne 0 ]; then
  echo "malformed or missing ## File ownership section in $handoff" >&2
  exit 2
fi

conflicts=0

for file in "${files[@]}"; do
  for pattern in "${frozen_patterns[@]}"; do
    if matches_pattern "$pattern" "$file"; then
      echo "conflict: $file matches frozen ownership $pattern" >&2
      conflicts=1
    fi
  done

  for pattern in "${user_patterns[@]}"; do
    if matches_pattern "$pattern" "$file"; then
      echo "conflict: $file matches user-reserved ownership $pattern" >&2
      conflicts=1
    fi
  done

  for i in "${!owned_patterns[@]}"; do
    pattern="${owned_patterns[$i]}"
    owner="${owned_agents[$i]}"
    if matches_pattern "$pattern" "$file" && [ "$owner" != "$agent" ]; then
      echo "conflict: $file is owned by $owner via $pattern, not $agent" >&2
      conflicts=1
    fi
  done
done

if [ "$conflicts" -ne 0 ]; then
  exit 1
fi

exit 0
