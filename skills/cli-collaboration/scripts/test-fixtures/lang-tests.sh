#!/usr/bin/env bash
# Isolated test suite for lang.sh. Each case runs against a fresh temporary
# XDG_CONFIG_HOME so the real user config is never touched.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LANG_SH="$ROOT/lang.sh"
failures=0

new_home() { XDG_CONFIG_HOME="$(mktemp -d)"; export XDG_CONFIG_HOME; }
cleanup_home() { [ -n "${XDG_CONFIG_HOME:-}" ] && rm -rf "$XDG_CONFIG_HOME"; }

assert_exit() { # name expected actual
  if [ "$3" -ne "$2" ]; then
    echo "not ok - $1 (exit expected $2 got $3)"; failures=$((failures + 1))
  else
    echo "ok - $1"
  fi
}
assert_eq() { # name expected actual
  if [ "$3" != "$2" ]; then
    echo "not ok - $1 (expected '$2' got '$3')"; failures=$((failures + 1))
  else
    echo "ok - $1"
  fi
}

# --- Task 1: get with no config ---
new_home
out="$("$LANG_SH" get 2>/dev/null)"; rc=$?
assert_exit "get-unset-exit3" 3 "$rc"
assert_eq   "get-unset-empty" "" "$out"
cleanup_home

# --- Task 2: set recognized language, then get ---
new_home
"$LANG_SH" set italiano >/dev/null; rc_set=$?
assert_exit "set-italiano-exit0" 0 "$rc_set"
out="$("$LANG_SH" get)"; rc=$?
assert_exit "get-after-set-exit0" 0 "$rc"
assert_eq   "get-after-set-code" "it" "$out"
cleanup_home

# --- Task 3: permissions on file and dir ---
new_home
"$LANG_SH" set english >/dev/null
cfg="$XDG_CONFIG_HOME/cli-collaboration/config.json"
dir="$XDG_CONFIG_HOME/cli-collaboration"
if stat -c '%a' "$cfg" >/dev/null 2>&1; then
  fmode="$(stat -c '%a' "$cfg")"; dmode="$(stat -c '%a' "$dir")"
else
  fmode="$(stat -f '%Lp' "$cfg")"; dmode="$(stat -f '%Lp' "$dir")"
fi
assert_eq "file-mode-0600" "600" "$fmode"
assert_eq "dir-mode-0700"  "700" "$dmode"
cleanup_home

# --- Task 4: normalization breadth + verbatim fallback ---
new_home
"$LANG_SH" set ENGLISH >/dev/null
assert_eq "norm-uppercase-english" "en" "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" set "español" >/dev/null
assert_eq "norm-spanish" "es" "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" set "Klingon" >/dev/null; rc=$?
assert_exit "set-unrecognized-exit0" 0 "$rc"
assert_eq "get-unrecognized-label" "Klingon" "$("$LANG_SH" get)"
new_lang="$(sed -n 's/.*\"language\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p' "$XDG_CONFIG_HOME/cli-collaboration/config.json" | head -n1)"
assert_eq "unrecognized-code-empty" "" "$new_lang"
cleanup_home

# --- Task 5: no-overwrite without --force; --force changes language ---
new_home
"$LANG_SH" set italiano >/dev/null
"$LANG_SH" set english >/dev/null
assert_eq "no-force-keeps-original" "it" "$("$LANG_SH" get)"
"$LANG_SH" set english --force >/dev/null
assert_eq "force-changes-language" "en" "$("$LANG_SH" get)"
cleanup_home

# set_by is recorded from --by
new_home
"$LANG_SH" set italiano --by CLAUDE >/dev/null
by="$(sed -n 's/.*\"set_by\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p' "$XDG_CONFIG_HOME/cli-collaboration/config.json" | head -n1)"
assert_eq "set-by-recorded" "CLAUDE" "$by"
cleanup_home

# --- Task 6: ensure-noninteractive ---
new_home
CLI_COLLAB_LANG=de "$LANG_SH" ensure-noninteractive >/dev/null; rc=$?
assert_exit "ensure-env-exit0" 0 "$rc"
assert_eq   "ensure-env-de" "de" "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" ensure-noninteractive >/dev/null
assert_eq "ensure-fallback-en" "en" "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" set italiano >/dev/null
CLI_COLLAB_LANG=de "$LANG_SH" ensure-noninteractive >/dev/null
assert_eq "ensure-noop-when-set" "it" "$("$LANG_SH" get)"
cleanup_home

# --- Task 7: JSON escaping round-trip (quotes and backslashes) ---
# Unrecognized input containing " or \ must read back verbatim through get,
# not truncated at the first escaped quote (regression: errori.md Errore 2).
new_home
"$LANG_SH" set 'A"B\C' >/dev/null
assert_eq "json-escaped-label-roundtrip" 'A"B\C' "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" set 'pir"ate' >/dev/null
assert_eq "json-escaped-label-quote" 'pir"ate' "$("$LANG_SH" get)"
cleanup_home

new_home
"$LANG_SH" set 'back\slash' >/dev/null
assert_eq "json-escaped-label-backslash" 'back\slash' "$("$LANG_SH" get)"
cleanup_home

# set_by has no public getter, so exercise read_field directly by sourcing.
new_home
# shellcheck source=/dev/null
by_read="$( . "$LANG_SH"; cmd_set 'Klingon' --by 'Q"R\S' >/dev/null 2>&1; read_field set_by )"
assert_eq "json-escaped-setby-roundtrip" 'Q"R\S' "$by_read"
cleanup_home

# config.json must remain valid JSON after hostile input.
new_home
"$LANG_SH" set 'A"B\C' --by 'Q"R\S' >/dev/null
cfg="$XDG_CONFIG_HOME/cli-collaboration/config.json"
if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$cfg" 2>/dev/null; then
    echo "ok - json-valid-after-hostile-input"
  else
    echo "not ok - json-valid-after-hostile-input"; failures=$((failures + 1))
  fi
fi
cleanup_home

if [ "$failures" -ne 0 ]; then exit 1; fi
echo "# all lang.sh tests passed"
