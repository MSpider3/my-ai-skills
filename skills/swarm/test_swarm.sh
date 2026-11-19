#!/usr/bin/env bash
# Self-check for swarm.sh. Run: bash test_swarm.sh (from this folder)
set -euo pipefail
S="$(cd "$(dirname "$0")" && pwd)/swarm.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
cd "$T" && git init -q && git commit -q --allow-empty -m init

bash "$S" init >/dev/null
grep -qxF '.swarm/' .git/info/exclude

# Concurrent posts: no lost lines, no duplicate sequence numbers.
for i in $(seq 1 20); do bash "$S" post "w$((i % 2))" all "msg $i" & done; wait
[[ $(wc -l < .swarm/board.md) -eq 20 ]]
[[ $(cut -d' ' -f1 .swarm/board.md | sort -u | wc -l) -eq 20 ]]

# Multi-line messages collapse to one line; inbox filters by recipient.
bash "$S" post add mul "your turn
line2"
bash "$S" inbox mul | grep -q 'your turn line2'
[[ $(bash "$S" inbox add | grep -c 'your turn') -eq 0 ]]

# Bad names are rejected. (`! cmd` is ignored by set -e, so check explicitly.)
must_fail() { if "$@" 2>/dev/null; then echo "FAIL: expected error from: $*"; exit 1; fi; }
must_fail bash "$S" post 'Bad Name' all x
must_fail bash "$S" wt '../x'

# Worker flow: worktree -> commit -> post from inside worktree -> merge.
wt=$(bash "$S" wt add)
(cd "$wt" && echo 'def add(a, b): return a + b' > m.py && git add m.py && git commit -qm add \
  && bash "$S" post add coordinator done)
grep -q 'add -> coordinator: done' .swarm/board.md
bash "$S" merge add >/dev/null
[[ -f m.py ]]
[[ -z $(git status --porcelain) ]]

# Roster: merged worker shows yes; unmerged shows no; board-only member shows -.
wt2=$(bash "$S" wt mul)
(cd "$wt2" && echo x > x.py && git add x.py && git commit -qm x)
bash "$S" post verifier coordinator "verdict: PASS"
roster=$(bash "$S" status)
grep -qE '^add +yes +0 +coordinator: done$' <<<"$roster"
grep -qE '^mul +no +0 *$' <<<"$roster"
grep -qE '^verifier +- +- +coordinator: verdict: PASS$' <<<"$roster"

# Clean keeps unmerged work, removes merged.
bash "$S" clean 2>/dev/null
[[ -z $(git worktree list | grep '/.swarm/wt/add') ]]
[[ -z $(git branch | grep 'swarm/add') ]]
git branch | grep -q 'swarm/mul'

echo "all swarm.sh checks passed"
