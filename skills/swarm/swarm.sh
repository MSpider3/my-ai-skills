#!/usr/bin/env bash
# Board + worktree helper for the /swarm skill. Run from inside the target repo or any of its worktrees.
set -euo pipefail

die() { echo "swarm: $*" >&2; exit 1; }

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not inside a git repo"
ROOT=$(dirname "$common")   # main worktree, even when called from a worker's worktree
DIR="$ROOT/.swarm"
BOARD="$DIR/board.md"

# Member names become branch names and grep patterns, so keep them plain.
name_ok() { [[ ${1:-} =~ ^[a-z0-9][a-z0-9-]{0,30}$ ]] || die "bad member name '${1:-}' (use a-z, 0-9, -)"; }

cmd=${1:-help}; shift || true
case $cmd in
  init)
    git -C "$ROOT" rev-parse -q --verify HEAD >/dev/null || die "repo has no commits; make one first"
    mkdir -p "$DIR/wt" "$common/info"; touch "$BOARD"
    grep -qxF '.swarm/' "$common/info/exclude" 2>/dev/null || echo '.swarm/' >> "$common/info/exclude"
    [[ -z $(git -C "$ROOT" status --porcelain) ]] ||
      echo "swarm: WARNING: uncommitted changes in $ROOT; workers branch from HEAD and will not see them" >&2
    echo "$BOARD" ;;
  post)
    (( $# >= 3 )) || die "usage: post <from> <to|all> <message>"
    from=$1 to=$2; shift 2
    name_ok "$from"; [[ $to == all ]] || name_ok "$to"
    [[ -f $BOARD ]] || die "no board; run init first"
    msg=$*; msg=${msg//$'\n'/ }   # one message = one line, so the board stays append-only and greppable
    {
      flock 9
      n=$(( $(wc -l < "$BOARD") + 1 ))
      printf '#%d %s %s -> %s: %s\n' "$n" "$(date +%H:%M:%S)" "$from" "$to" "$msg" >> "$BOARD"
    } 9>"$BOARD.lock" ;;
  show)  tail -n "${1:-50}" "$BOARD" ;;
  status)
    # Members roster: everyone with a worktree or a board post.
    printf '%-14s %-7s %-6s %s\n' MEMBER MERGED DIRTY LAST-POST
    { ls "$DIR/wt" 2>/dev/null; cut -d' ' -f3 "$BOARD"; } | sort -u | while read -r m; do
      merged=- dirty=-
      if [[ -d $DIR/wt/$m ]]; then
        git -C "$ROOT" merge-base --is-ancestor "swarm/$m" HEAD && merged=yes || merged=no
        dirty=$(git -C "$DIR/wt/$m" status --porcelain | wc -l)
      fi
      last=$( { grep -E "^#[0-9]+ [0-9:]+ $m -> " "$BOARD" || true; } | tail -n 1 | cut -d' ' -f5- | cut -c1-70)
      printf '%-14s %-7s %-6s %s\n' "$m" "$merged" "$dirty" "$last"
    done ;;
  watch) tail -n 20 -f "$BOARD" ;;
  inbox)
    name_ok "${1:-}"
    grep -E "^#[0-9]+ [0-9:]+ [a-z0-9-]+ -> ($1|all): " "$BOARD" || true ;;
  wt)
    name_ok "${1:-}"; path="$DIR/wt/$1"
    [[ -e $path ]] && die "worktree for $1 already exists: $path"
    git -C "$ROOT" worktree add -q -b "swarm/$1" "$path" HEAD
    echo "$path" ;;
  merge)
    name_ok "${1:-}"
    git -C "$ROOT" merge --no-ff --no-edit "swarm/$1" ||
      die "merge of swarm/$1 failed. Resolve the conflict in $ROOT, or run: git -C $ROOT merge --abort" ;;
  clean)
    # Never forces: a worktree with uncommitted work or an unmerged branch is kept and reported.
    for path in "$DIR"/wt/*/; do
      [[ -d $path ]] || continue
      m=$(basename "$path")
      git -C "$ROOT" worktree remove "$path" || { echo "swarm: kept $path (uncommitted changes)" >&2; continue; }
      git -C "$ROOT" branch -d "swarm/$m" >/dev/null || echo "swarm: kept branch swarm/$m (not merged)" >&2
    done ;;
  *)
    echo "usage: swarm.sh init | post <from> <to|all> <msg> | show [n] | watch | inbox <member> | wt <member> | merge <member> | clean"
    [[ $cmd == help ]] ;;
esac
