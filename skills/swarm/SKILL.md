---
name: swarm
description: Antigravity-style /swarm for Claude Code. A coordinator splits a task, runs parallel worker subagents in isolated git worktrees, coordinates them on a shared append-only message board, merges their branches, and runs adversarial verifiers. Use when the user types /swarm, asks for a swarm, or wants a task split across parallel agents with verification. "/swarm board" shows the board.
---

# Swarm

You are the **coordinator**. Workers are subagents you spawn with your harness's subagent tool (see Setup). Each works in its own git worktree, talks through a shared board file, and never merges. You plan, hand off, merge, and run verifiers.

## Setup for your harness

- `<SKILL_DIR>` is the folder this SKILL.md is in; `<SWARM>` is `<SKILL_DIR>/swarm.sh`. Resolve it to an **absolute** path once and use that in every command and every member prompt (members run from other folders). Usual locations: Claude Code `~/.claude/skills/swarm`, Codex `~/.agents/skills/swarm`, Antigravity `~/.gemini/config/skills/swarm`, Hermes `~/.hermes/skills/swarm`, DeepSeek Harness `~/.dsh/skills/swarm`.
- Needs `git`, `bash` and `flock` (Linux has it; macOS: `brew install flock`; Windows: use WSL). Run `<SWARM>` from inside the target repo or any of its worktrees. Self-check: `bash <SKILL_DIR>/test_swarm.sh`.
- **Spawning, resuming and model pinning** use your harness's subagent tool: Claude Code `Agent` (resume with `SendMessage`, `model: haiku | sonnet | opus`); Hermes `delegate_task`; other harnesses: their subagent or background-agent feature. **No subagents?** Run each member yourself, one at a time, inside its worktree. The board, worktrees, merges and verifier steps all still apply.

Commands below are written `swarm.sh <cmd>`; run them as `<SWARM> <cmd>`.

| Command | Does |
|---|---|
| `swarm.sh init` | creates `.swarm/board.md` (git-ignored via `.git/info/exclude`), prints its path |
| `swarm.sh post <from> <to\|all> <msg>` | appends one numbered line, locked, safe from parallel agents |
| `swarm.sh show [n]` / `watch` | last n lines / live tail |
| `swarm.sh status` | Members roster: member, merged?, uncommitted file count, last post |
| `swarm.sh inbox <member>` | messages addressed to that member or `all` |
| `swarm.sh wt <member>` | new worktree + branch `swarm/<member>` from HEAD, prints its path |
| `swarm.sh merge <member>` | merges `swarm/<member>` into the current branch (`--no-ff`) |
| `swarm.sh clean` | removes merged worktrees/branches; keeps anything unmerged or uncommitted |

## `/swarm board`

Run `swarm.sh status` (Members roster) and `swarm.sh show` (Board feed) and print both. For a live view, tell the user to run `<SWARM> watch` in a terminal inside the repo. Worktrees are listed by `git worktree list`; they live in `.swarm/wt/<member>` on branch `swarm/<member>`.

## Roster and model pinning

Defaults, in Claude Code model names (use your harness's small / mid / strong equivalents). The user can override: "pin verifier to opus", "all workers haiku".

| Role | Model | Count |
|---|---|---|
| coordinator | you | 1 |
| worker | `sonnet`; `haiku` for small, mechanical tasks | 2–5 |
| verifier | `opus` for logic/security-heavy work, else `sonnet` (pick a different model from the workers where possible) | 1–2 |

Keep the whole swarm under ~8 agents unless the user asks for more.

## Procedure

### 1. Preflight
- Must be inside a git repo with at least one commit. If not, stop and tell the user; do not `git init` their project without asking.
- `swarm.sh init`. If it warns about uncommitted changes, **ask** the user to commit or stash. Never commit or stash for them; workers branch from HEAD and would miss those changes.

### 2. Plan
- Read enough of the code to split the task into 2–5 pieces. Prefer pieces with **disjoint files**; that is what makes the merge clean.
- Order pieces into **waves**: a piece that needs another's output goes in a later wave. You drive every handoff. Never make a worker wait for another worker (chained worker-to-worker handoffs are where swarms stall).
- Show the user the roster as a table: member name (`a-z0-9-`), model, task, files it owns, wave. Then post the plan: `swarm.sh post coordinator all "plan: ..."`. Start without waiting unless the user asked to approve plans first.

### 3. Run a wave
For each member in the wave: `swarm.sh wt <member>`, then spawn all of that wave's workers **in one message** (parallel) with the worker prompt below, each with its `model` set. Wait for completion notifications. Do not poll and do not do their work.

### 4. Merge
As each worker finishes: read `swarm.sh inbox coordinator`, then `swarm.sh merge <member>` from the main worktree.
- Conflict: if trivial, resolve it yourself and commit; otherwise `git merge --abort` and resume that worker to rebase onto the current branch and fix it.
- Worker reported `blocked:` → answer it, or re-plan, then resume it.
Start the next wave only after its dependencies are merged. A new wave's worktrees branch from the merged HEAD, so they see earlier work.

### 5. Verify
Spawn the verifier(s) on the merged main worktree, read-only, with the verifier prompt below. Two verifiers? Split by angle (correctness vs. tests/spec), not by file.
- `FAIL` → send each finding to the worker who owns that file (resuming keeps its full context; finished agents cost nothing while parked). It fixes in its worktree, commits, posts `done`; you merge again and re-verify. Max 2 fix rounds, then report what is still failing.

### 6. Finish
`swarm.sh clean`. If it keeps a worktree, run `git -C <worktree> status --porcelain`: when the branch is merged (`status` shows `yes`) and the only leftovers are untracked build caches (`__pycache__/`, `.pytest_cache/`, `node_modules/.cache`), `git worktree remove --force <worktree>` and `git branch -d swarm/<member>` are safe. Anything else (real files, unmerged branch): leave it and tell the user. Then report: roster (member, model, outcome), verifier verdicts and any unfixed finding, the merge commits, and the board path. Do not push or open a PR unless asked.

## Worker prompt (fill the <...>)

```
You are swarm member "<member>" (model-pinned). Coordinator: "coordinator".
Your worktree: <absolute worktree path>. Work ONLY there; cd into it for every command. Never touch the main checkout or other worktrees, and never merge or push.
Task: <task>
Files you own: <files>. Do not edit files outside this list; if you must, post first and explain.
Do not leave build artifacts in the worktree (for Python, prefix commands with PYTHONDONTWRITEBYTECODE=1).
Context from earlier waves: <short summary or "none">

Board (run from your worktree): <SWARM absolute path>
- At start:  swarm.sh post <member> coordinator "started: <one line>"
- Read:      swarm.sh inbox <member>
- If stuck:  swarm.sh post <member> coordinator "blocked: <what you need>"  then stop and report.
- When done: run the relevant tests, `git add` + `git commit -m "<member>: <summary>"` in your worktree, then
             swarm.sh post <member> coordinator "done: <summary>; tests: <command> -> <result>"

Final report: files changed, commit hash, test command and exit code, anything you skipped.
```

## Verifier prompt

```
You are swarm member "<verifier>", an adversarial verifier. Your job is to prove the work wrong.
Repo: <main worktree path>. Merged commits to check: <git log range>. Spec: <original task>.
Do NOT edit, create or commit files in the repo. Use read-only commands, test runs, and throwaway checks (python3 -c, a temp dir).
Check: tests pass; the spec is met literally (not just "looks done"); edge cases; whether the tests would catch a plausible wrong implementation; anything that changed outside the planned files.
Post each finding: <SWARM absolute path> post <verifier> coordinator "FAIL <file>:<line> <claim> | evidence: <cmd -> output>"
End with:            swarm.sh post <verifier> coordinator "verdict: PASS|FAIL (<n> findings)"
Final report: verdict, each finding with its evidence, what you did not check.
```

## How this maps to Antigravity /swarm

| Antigravity | Here |
|---|---|
| coordinator | you (main session) |
| parallel workers in isolated git worktrees | subagents, one `swarm.sh wt` each |
| adversarial verifiers | verifier subagents, read-only |
| shared append-only message board | `.swarm/board.md` via `swarm.sh post` |
| idle agents park at zero cost | finished subagents cost nothing; resume them when needed |
| pin members to models | the model option of your subagent tool |
| Board feed / `/swarm board` | `swarm.sh show` / `watch` |
| Members roster | `swarm.sh status` |
