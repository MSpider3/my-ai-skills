#!/usr/bin/env bash
# Install this skill collection into one or more AI harnesses.
#   ./install.sh                        Claude Code
#   ./install.sh codex hermes-agent     those harnesses (any number)
#   ./install.sh --mine claude-code     only my own skills (swarm, skill_select, prompt_improvement)
# Harnesses: claude-code, codex, antigravity, antigravity-cli, hermes-agent, gemini-cli, deepseek,
# or any other agent id supported by `npx skills` (https://github.com/vercel-labs/skills).
set -euo pipefail

# Skill collections this one builds on, installed straight from their authors (credits: README.md).
SOURCES=(
  NousResearch/hermes-agent
  affaan-m/ECC
  addyosmani/agent-skills
  DietrichGebert/ponytail
  snarktank/ralph
  vercel-labs/skills
  heygen-com/hyperframes
  openai/skills
)

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mine="MSpider3/my-ai-skills"
[[ -d $here/skills/swarm ]] && mine=$here   # run from a clone: install the local copy

mine_only=0; harnesses=()
for arg in "$@"; do
  case $arg in
    --mine) mine_only=1 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    *) harnesses+=("$arg") ;;
  esac
done
(( ${#harnesses[@]} )) || harnesses=(claude-code)

command -v npx >/dev/null || { echo "Needs Node.js 18+ (for npx). Install Node.js first." >&2; exit 1; }
export DISABLE_TELEMETRY=1 DO_NOT_TRACK=1   # the skills CLI sends no install telemetry

# DeepSeek Harness reads ~/.dsh/skills, which npx skills does not know: install for codex
# (~/.agents/skills) and link from there.
agent_args=(); dsh=0
for h in "${harnesses[@]}"; do
  if [[ $h == deepseek ]]; then dsh=1; h=codex; fi
  agent_args+=(-a "$h")
done

failed=()
add() {
  echo "==> $1"
  npx -y skills add "$1" -g -y -s '*' --full-depth "${agent_args[@]}" || failed+=("$1")
}

add "$mine"
if (( ! mine_only )); then
  for src in "${SOURCES[@]}"; do add "$src"; done
fi

if (( dsh )); then
  mkdir -p "$HOME/.dsh/skills"
  for d in "$HOME"/.agents/skills/*/; do
    n=$(basename "$d")
    [[ -e $HOME/.dsh/skills/$n ]] || ln -s "${d%/}" "$HOME/.dsh/skills/$n"
  done
  echo "Linked skills into ~/.dsh/skills for DeepSeek Harness."
fi

echo
if (( ${#failed[@]} )); then
  echo "Finished, but these failed (re-run, or install them by hand): ${failed[*]}" >&2
  exit 1
fi
echo "Done. Restart your harness to load the skills."
(( mine_only )) || echo "Optional: GSD has its own installer, see README (npx @opengsd/gsd-core@latest)."
