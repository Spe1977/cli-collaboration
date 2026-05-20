#!/usr/bin/env bash
set -u
set -o pipefail

# Ownership parsing was originally Bash-native, but macOS Bash 3.2.57
# proved unreliable when handoff ownership lines carried multibyte UTF-8
# bytes (en-dash, em-dash). Seven rounds of Bash-only mitigations were
# tried and the same two fixtures (endash-owner, glob-crosses-slash)
# kept failing on macos-latest. The parser was therefore migrated to
# parse-ownership.py (Plan C), and this file is now a thin CLI wrapper
# that delegates everything. Invocation, flags, env var, and exit codes
# are unchanged.
#
# usage: check-ownership.sh [--handoff PATH] [--agent NAME] FILE...
# exit codes:
#   0  no conflict
#   1  conflict against agent-owned, user-reserved, or frozen
#   2  usage error or malformed/missing ## File ownership section

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/parse-ownership.py" "$@"
