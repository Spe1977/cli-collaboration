#!/usr/bin/env bash
set -u
set -o pipefail

# Force byte-mode locale. macOS ships Bash 3.2.57 whose multibyte handling
# in `${var//pat/rep}`, `[[ str == pat ]]`, and `${var%%pat*}` is unreliable.
# Treating all strings as raw bytes lets the dash detection below work on
# both modern Bash 5.x and stock macOS Bash 3.2.
export LC_ALL=C

# Dash bytes defined via ANSI-C quoting so the script source has no literal
# multibyte characters in patterns — those broke on Bash 3.2 (en-dash and
# em-dash were not matched/substituted, owner extraction returned the whole
# tail of the line, and the fixture tests for en-dash and glob-crosses-slash
# both reported phantom conflicts).
EN_DASH=$'\xe2\x80\x93'  # U+2013
EM_DASH=$'\xe2\x80\x94'  # U+2014

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
  while [[ "$value" == *[[:space:]] ]]; do
    value="${value%[[:space:]]}"
  done
  while [[ "$value" == [[:space:]]* ]]; do
    value="${value#[[:space:]]}"
  done
  printf '%s' "$value"
}

normalize_dashes() {
  # Keep all multibyte dash matching out of Bash pattern operations.
  # BSD/GNU sed handle these byte strings consistently under LC_ALL=C;
  # after this step, owner delimiter parsing below uses ASCII-only Bash
  # patterns. This is the only reliable way to handle U+2013 / U+2014 on
  # macOS Bash 3.2.57, which mis-handles multibyte content in `${var//}`
  # and `[[ str == *pat* ]]` even when the dash is sourced from a variable
  # defined via ANSI-C quoting.
  printf '%s' "$1" | sed "s/${EN_DASH}/-/g; s/${EM_DASH}/-/g; s/ -- / - /g"
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
    rest="$(normalize_dashes "$rest")"
    if [ -z "$path" ] || [ -z "$rest" ]; then
      malformed=1
      continue
    fi
    if [[ "$rest" == *" - "* ]]; then
      owner="${rest%% - *}"
    elif [[ "$rest" == *"-"* ]]; then
      owner="${rest%%-*}"
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
