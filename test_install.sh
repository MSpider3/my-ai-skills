#!/usr/bin/env bash
# Offline self-check for install.sh: fake `npx` and `codex` record what they would run.
# Run: bash test_install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home"
printf '#!/bin/sh\necho "npx $*" >> "%s/calls"\n' "$T" > "$T/bin/npx"
printf '#!/bin/sh\necho "codex $*" >> "%s/calls"\nexit "${CODEX_EXIT:-0}"\n' "$T" > "$T/bin/codex"
chmod +x "$T/bin/npx" "$T/bin/codex"

run() {  # run <PATH> <args...>; output in $out, calls in $calls
  : > "$T/calls"
  out=$(HOME="$T/home" PATH="$1" bash "$here/install.sh" "${@:2}" 2>&1) && rc=0 || rc=$?
  calls=$(cat "$T/calls")
}
with_codex="$T/bin:/usr/bin:/bin"
no_codex="$T/nocodex:/usr/bin:/bin"
mkdir -p "$T/nocodex"; ln -s "$T/bin/npx" "$T/nocodex/npx"
fail() { echo "FAIL: $*"; echo "--- output:"; echo "$out"; echo "--- calls:"; echo "$calls"; exit 1; }

# Full install for several harnesses: GSD gets every supported flag, DeepSeek is reported as skipped.
run "$with_codex" claude-code codex hermes-agent deepseek
[[ $rc -eq 0 ]] || fail "full install exit $rc"
grep -qx 'npx -y @opengsd/gsd-core@latest --global --claude --codex --hermes' <<<"$calls" || fail "GSD flags"
grep -q 'GSD does not support: deepseek' <<<"$out" || fail "deepseek skip note"
grep -qx 'codex plugin add codex-security@openai-api-curated' <<<"$calls" || fail "codex security"
[[ $(grep -c '^npx -y skills add' <<<"$calls") -eq 9 ]] || fail "expected 9 skill sources (mine + 8)"
grep -q 'skills add .* -a claude-code -a codex -a hermes-agent -a codex' <<<"$calls" || fail "agent flags"
[[ -d $T/home/.dsh/skills ]] || fail "dsh dir not created"

# --mine: only my skills, no GSD, no Codex Security.
run "$with_codex" --mine claude-code
[[ $rc -eq 0 && $(wc -l <<<"$calls") -eq 1 ]] || fail "--mine should make exactly one call"
grep -q 'gsd-core\|codex plugin' <<<"$calls" && fail "--mine must skip GSD and Codex Security"

# Antigravity, even with the codex command present: GSD only, no Codex Security attempt.
run "$with_codex" antigravity
grep -qx 'npx -y @opengsd/gsd-core@latest --global --antigravity' <<<"$calls" || fail "antigravity GSD flag"
grep -q 'codex plugin' <<<"$calls" && fail "codex security must not run for antigravity"

# Codex requested but the codex command is missing: skipped with a note, not a failure.
run "$no_codex" codex
[[ $rc -eq 0 ]] || fail "missing codex command should not fail"
grep -q 'Codex Security skipped' <<<"$out" || fail "missing-codex note"

# A failing step is reported and makes the run exit non-zero, after everything else ran.
CODEX_EXIT=3 run "$with_codex" codex
[[ $rc -eq 1 ]] || fail "failure should exit 1, got $rc"
grep -q 'these failed .*Codex Security' <<<"$out" || fail "failure not reported"

# Only DeepSeek: GSD has nothing to install, so it is not called at all.
run "$with_codex" deepseek
grep -q 'gsd-core' <<<"$calls" && fail "GSD should not run when no harness supports it"

run "$with_codex" --help
grep -q 'Codex Security plugin' <<<"$out" || fail "help text incomplete"

echo "all install.sh checks passed"
