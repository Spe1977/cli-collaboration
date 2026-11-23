#!/usr/bin/env bash
# lang.sh — manage the cli-collaboration language preference.
# Precedence on `get`:
#   1. Global config: ${CLI_COLLAB_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json}
#   2. Project-local config: ${CLI_COLLAB_LOCAL_CONFIG:-.cli-collaboration.json}
#   3. Environment fallback: $CLI_COLLAB_LANG
# Exit codes:
#   0  success
#   2  usage error
#   3  get: language not configured
#   4  set: target config directory/file is read-only or sandboxed
set -u

config_dir()  { printf '%s/cli-collaboration' "${XDG_CONFIG_HOME:-$HOME/.config}"; }
config_path() { printf '%s' "${CLI_COLLAB_CONFIG_FILE:-$(config_dir)/config.json}"; }
local_config_path() { printf '%s' "${CLI_COLLAB_LOCAL_CONFIG:-.cli-collaboration.json}"; }

# read_field <field> [file] -> prints the string value (possibly empty); returns 1 if unreadable.
# Reads symmetrically with the JSON escaping done by escape_json: the value may
# contain escaped quotes (\") and backslashes (\\), so we cannot stop at the
# first quote. We isolate the value between the opening quote and the line's
# trailing quote, then unescape \\ -> \ and \" -> " (no jq dependency).
read_field() {
  local field="$1"
  local file line val
  file="${2:-$(config_path)}"
  [ -f "$file" ] && [ -r "$file" ] || return 1
  line="$(grep -m1 "\"$field\"[[:space:]]*:" "$file" 2>/dev/null)" || true
  [ -n "$line" ] || return 0
  val="${line#*\""$field"\"}"               # drop everything up to and incl. "field"
  val="${val#*:}"                          # drop the colon separator
  val="${val#"${val%%[![:space:]]*}"}"     # ltrim spaces before the value
  val="${val#\"}"                          # drop the opening quote
  val="${val%,}"                           # drop a trailing comma if present
  val="${val%\"}"                          # drop the closing quote
  val="${val//\\\\/\\}"                    # unescape \\ -> \
  val="${val//\\\"/\"}"                    # unescape \" -> "
  printf '%s' "$val"
}

read_lang_from_file() {
  local file="$1"
  local lang label
  lang="$(read_field language "$file" 2>/dev/null || true)"
  label="$(read_field language_label "$file" 2>/dev/null || true)"
  if [ -n "$lang" ]; then
    printf '%s\n' "$lang"
    return 0
  fi
  if [ -n "$label" ]; then
    printf '%s\n' "$label"
    return 0
  fi
  return 1
}

cmd_get() {
  local global_file local_file
  global_file="$(config_path)"
  if read_lang_from_file "$global_file"; then
    return 0
  fi

  local_file="$(local_config_path)"
  if read_lang_from_file "$local_file"; then
    return 0
  fi

  if [ -n "${CLI_COLLAB_LANG:-}" ]; then
    normalize_lang "$CLI_COLLAB_LANG"
    if [ -n "$NL_CODE" ]; then
      printf '%s\n' "$NL_CODE"
    else
      printf '%s\n' "$NL_LABEL"
    fi
    return 0
  fi

  return 3
}

escape_json() {
  local val="$1"
  val="${val//\\/\\\\}"
  val="${val//\"/\\\"}"
  printf '%s' "$val"
}

# Sets NL_CODE and NL_LABEL. Unrecognized input -> NL_CODE empty, NL_LABEL=verbatim (trimmed).
normalize_lang() {
  local raw="$1" key
  raw="${raw#"${raw%%[![:space:]]*}"}"   # ltrim
  raw="${raw%"${raw##*[![:space:]]}"}"   # rtrim
  key="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$key" in
    it|italian|italiano)               NL_CODE=it; NL_LABEL=Italiano ;;
    en|english|inglese)                NL_CODE=en; NL_LABEL=English ;;
    es|spanish|espanol|español)        NL_CODE=es; NL_LABEL=Español ;;
    fr|french|francais|français)       NL_CODE=fr; NL_LABEL=Français ;;
    de|german|deutsch|tedesco)         NL_CODE=de; NL_LABEL=Deutsch ;;
    pt|portuguese|portugues|português) NL_CODE=pt; NL_LABEL=Português ;;
    *)                                 NL_CODE="";  NL_LABEL="$raw" ;;
  esac
}

is_configured_file() {
  local file="$1"
  local lang label
  lang="$(read_field language "$file" 2>/dev/null || true)"
  label="$(read_field language_label "$file" 2>/dev/null || true)"
  [ -n "$lang" ] || [ -n "$label" ]
}

is_configured() {
  is_configured_file "$(config_path)"
}

write_config() {
  local code="$1" label="$2" by="$3"
  local file dir tmp ts esc_label esc_by
  file="${4:-$(config_path)}"
  dir="$(dirname "$file")"
  ts="$(date +%Y-%m-%dT%H:%M:%S%z)"
  esc_label="$(escape_json "$label")"
  esc_by="$(escape_json "$by")"

  if ! mkdir -p "$dir" 2>/dev/null; then
    printf 'lang.sh: cannot write config at %s (sandboxed or read-only); pass --local or use prompt language\n' "$file" >&2
    return 4
  fi

  if [ "$dir" = "$(config_dir)" ]; then
    chmod 0700 "$dir" 2>/dev/null || true
  fi

  if ! tmp="$(mktemp "$dir/.config.json.XXXXXX" 2>/dev/null)"; then
    printf 'lang.sh: cannot write config at %s (sandboxed or read-only); pass --local or use prompt language\n' "$file" >&2
    return 4
  fi

  if ! printf '{\n  "version": 1,\n  "language": "%s",\n  "language_label": "%s",\n  "set_by": "%s",\n  "set_at": "%s"\n}\n' \
    "$code" "$esc_label" "$esc_by" "$ts" > "$tmp" 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null || true
    printf 'lang.sh: cannot write config at %s (sandboxed or read-only); pass --local or use prompt language\n' "$file" >&2
    return 4
  fi

  chmod 0600 "$tmp" 2>/dev/null || true
  if ! mv "$tmp" "$file" 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null || true
    printf 'lang.sh: cannot write config at %s (sandboxed or read-only); pass --local or use prompt language\n' "$file" >&2
    return 4
  fi
}

cmd_set() {
  local input="" by="${CLI_COLLAB_AGENT:-unknown}" force=0 use_local=0 target_file rc
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force) force=1 ;;
      --local) use_local=1 ;;
      --by)
        shift
        if [ "$#" -eq 0 ]; then
          printf 'lang.sh: --by requires an argument\n' >&2
          return 2
        fi
        by="$1"
        ;;
      -*) printf 'lang.sh: unknown option: %s\n' "$1" >&2; return 2 ;;
      *) if [ -z "$input" ]; then input="$1"; else input="$input $1"; fi ;;
    esac
    shift
  done

  [ -n "$input" ] || { printf 'lang.sh: set requires a language argument\n' >&2; return 2; }

  if [ "$use_local" -eq 1 ]; then
    target_file="$(local_config_path)"
  else
    target_file="$(config_path)"
  fi

  if [ "$force" -eq 0 ] && is_configured_file "$target_file"; then
    read_lang_from_file "$target_file" || true
    return 0
  fi

  normalize_lang "$input"
  write_config "$NL_CODE" "$NL_LABEL" "$by" "$target_file"
  rc=$?
  [ "$rc" -eq 0 ] || return "$rc"

  if [ -n "$NL_CODE" ]; then
    printf '%s\n' "$NL_CODE"
  else
    printf '%s\n' "$NL_LABEL"
  fi
}

cmd_ensure_noninteractive() {
  if is_configured; then return 0; fi
  cmd_set "${CLI_COLLAB_LANG:-en}" --by "${CLI_COLLAB_AGENT:-noninteractive}"
}

main() {
  local sub="${1:-}"
  [ "$#" -gt 0 ] && shift
  case "$sub" in
    get) cmd_get "$@" ;;
    set) cmd_set "$@" ;;
    ensure-noninteractive) cmd_ensure_noninteractive "$@" ;;
    *)   printf 'usage: lang.sh {get|set <lang> [--force] [--local] [--by NAME]|ensure-noninteractive}\n' >&2; return 2 ;;
  esac
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  main "$@"
fi
