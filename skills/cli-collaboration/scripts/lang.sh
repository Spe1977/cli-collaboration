#!/usr/bin/env bash
# lang.sh — manage the cli-collaboration global language preference.
# Single source of truth: ${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json
# No runtime dependency on jq: writes via printf, reads via portable sed.
set -u

config_dir()  { printf '%s/cli-collaboration' "${XDG_CONFIG_HOME:-$HOME/.config}"; }
config_path() { printf '%s/config.json' "$(config_dir)"; }

# read_field <field> -> prints the string value (possibly empty); returns 1 if file missing.
# Reads symmetrically with the JSON escaping done by escape_json: the value may
# contain escaped quotes (\") and backslashes (\\), so we cannot stop at the
# first quote. We isolate the value between the opening quote and the line's
# trailing quote, then unescape \\ -> \ and \" -> " (no jq dependency).
read_field() {
  local field="$1" file line val
  file="$(config_path)"
  [ -f "$file" ] || return 1
  line="$(grep -m1 "\"$field\"[[:space:]]*:" "$file" 2>/dev/null)" || true
  [ -n "$line" ] || return 0
  val="${line#*\"$field\"}"               # drop everything up to and incl. "field"
  val="${val#*:}"                          # drop the colon separator
  val="${val#"${val%%[![:space:]]*}"}"     # ltrim spaces before the value
  val="${val#\"}"                          # drop the opening quote
  val="${val%,}"                           # drop a trailing comma if present
  val="${val%\"}"                          # drop the closing quote
  val="${val//\\\\/\\}"                    # unescape \\ -> \
  val="${val//\\\"/\"}"                    # unescape \" -> "
  printf '%s' "$val"
}

cmd_get() {
  local lang label
  lang="$(read_field language 2>/dev/null || true)"
  label="$(read_field language_label 2>/dev/null || true)"
  if [ -n "$lang" ];  then printf '%s\n' "$lang";  return 0; fi
  if [ -n "$label" ]; then printf '%s\n' "$label"; return 0; fi
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

is_configured() {
  local lang label
  lang="$(read_field language 2>/dev/null || true)"
  label="$(read_field language_label 2>/dev/null || true)"
  [ -n "$lang" ] || [ -n "$label" ]
}

write_config() {
  local code="$1" label="$2" by="$3" dir file tmp ts esc_label esc_by
  dir="$(config_dir)"; file="$(config_path)"
  ts="$(date +%Y-%m-%dT%H:%M:%S%z)"
  esc_label="$(escape_json "$label")"
  esc_by="$(escape_json "$by")"
  mkdir -p "$dir"; chmod 0700 "$dir" 2>/dev/null || true
  tmp="$(mktemp "$dir/.config.json.XXXXXX")"
  printf '{\n  "version": 1,\n  "language": "%s",\n  "language_label": "%s",\n  "set_by": "%s",\n  "set_at": "%s"\n}\n' \
    "$code" "$esc_label" "$esc_by" "$ts" > "$tmp"
  chmod 0600 "$tmp"
  mv "$tmp" "$file"
}

cmd_set() {
  local input="" by="${CLI_COLLAB_AGENT:-unknown}" force=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force) force=1 ;;
      --by) shift; by="${1:-unknown}" ;;
      -*) printf 'lang.sh: unknown option: %s\n' "$1" >&2; return 2 ;;
      *) if [ -z "$input" ]; then input="$1"; else input="$input $1"; fi ;;
    esac
    shift
  done
  [ -n "$input" ] || { printf 'lang.sh: set requires a language argument\n' >&2; return 2; }
  if [ "$force" -eq 0 ] && is_configured; then
    cmd_get
    return 0
  fi
  normalize_lang "$input"
  write_config "$NL_CODE" "$NL_LABEL" "$by"
  cmd_get
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
    *)   printf 'usage: lang.sh {get|set <lang> [--force] [--by NAME]|ensure-noninteractive}\n' >&2; return 2 ;;
  esac
}

main "$@"
