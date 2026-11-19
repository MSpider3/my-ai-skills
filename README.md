# My AI Skills

My personal compilation of AI agent skills: the collections I use every day, plus three skills of my own.
One command installs all of it into the AI coding harness you use.

It works in **Claude Code, Codex, Antigravity, Hermes Agent, DeepSeek Harness, Gemini CLI** and 70+ other harnesses,
because they all read the same open `SKILL.md` skill format.

> **This is a compilation.** Apart from the three skills in [My skills](#my-skills), every skill here is the
> work of its original authors. Nothing of theirs is copied into this repo: the installer downloads each
> collection directly from its author's repository. See [Credits](#credits).

## My skills

| Skill | What it does |
|---|---|
| [`swarm`](skills/swarm/SKILL.md) | Antigravity-style swarm for any harness. A coordinator splits a task, runs parallel workers in isolated git worktrees, keeps them in sync on a shared append-only message board, merges their work, and runs adversarial verifiers before calling it done. Includes a members roster (`swarm.sh status`) and a self-test. |
| [`skill_select`](skills/skill_select/SKILL.md) | A router for large skill libraries: a 4-step method plus a categorized catalog of 767 skills, so the agent picks the right skill (or chain of skills) for a task. |
| [`prompt_improvement`](skills/prompt_improvement/SKILL.md) | Turns a rough prompt into a precise one, picks the skills to use via `skill_select`, and always asks you to confirm before it acts. |

## Install

You need **Node.js 18+**, **git** and **bash** (Linux, macOS, or Windows via WSL).

```bash
git clone https://github.com/MSpider3/my-ai-skills.git
cd my-ai-skills

./install.sh                                          # everything, into Claude Code
./install.sh codex antigravity hermes-agent deepseek  # everything, into several harnesses at once
./install.sh --mine claude-code                       # only my three skills
```

Only want my three skills and don't want to clone? This works too:

```bash
npx skills add MSpider3/my-ai-skills -g -a claude-code   # or -a codex, -a hermes-agent, ...
```

Restart your harness afterwards so it loads the new skills.

| Harness | Name to pass | Where the skills go |
|---|---|---|
| Claude Code | `claude-code` | `~/.claude/skills` |
| Codex | `codex` | `~/.agents/skills` |
| Antigravity | `antigravity` / `antigravity-cli` | `~/.gemini/config/skills` |
| Hermes Agent | `hermes-agent` | `~/.hermes/skills` |
| DeepSeek Harness | `deepseek` | `~/.dsh/skills` (linked from `~/.agents/skills`) |
| Gemini CLI | `gemini-cli` | `~/.gemini/skills` |
| Others | any agent id that [`npx skills`](https://github.com/vercel-labs/skills) supports | that harness's skill folder |

### Good to know

- **It's big.** The full install is about 600 skills (around 45 MB). Use `--mine` if you only want my three.
- **Skills run with your agent's permissions.** Some of them install software or run setup scripts when you use them. Read a skill before you rely on it.
- **No telemetry.** The installer turns off the `npx skills` install telemetry.
- **Update everything:** `npx skills update -g`. **Remove a skill:** `npx skills remove <name> -g`.
- **`swarm` needs** `git`, `bash` and `flock` (built into Linux; on macOS run `brew install flock`).
- **`skill_select`'s catalog** links to where Claude Code keeps each skill. Other harnesses still work, because the agent picks skills by name.

## Credits

Everything below belongs to its authors, under its own license. `install.sh` downloads it straight from them.

| Collection | Author / source | Skills | License |
|---|---|---|---|
| Hermes Agent skills | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | ~186 | MIT |
| Everything Claude Code (ECC) | [affaan-m/ECC](https://github.com/affaan-m/ECC) | ~330 | MIT |
| Agent Skills | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | ~26 | MIT |
| Ponytail | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | 6 | MIT |
| Ralph | [snarktank/ralph](https://github.com/snarktank/ralph) | 2 | MIT |
| Skills CLI skills (find-skills, …) | [vercel-labs/skills](https://github.com/vercel-labs/skills) | 3 | MIT |
| HyperFrames | [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) | ~16 | see repo |
| OpenAI skills (skill-creator, skill-installer, openai-docs, imagegen, …) | [openai/skills](https://github.com/openai/skills) | ~43 | see repo |

These are part of my setup too, but they have their own installers or come with a harness, so `install.sh` doesn't install them:

| Collection | Source | How to get it |
|---|---|---|
| GSD (get-shit-done), ~71 skills | [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core) | `npx @opengsd/gsd-core@latest`. It asks which harness: Claude Code, Codex, Gemini, Antigravity or OpenCode. |
| Codex Security, 15 skills (threat-model, deep-security-scan, …) | OpenAI, [Codex Security](https://developers.openai.com/codex/security) | Install the `codex-security` plugin inside Codex. |
| Antigravity built-ins (agy-customizations, antigravity-guide, …) | Google Antigravity | Included with Antigravity. |
| reverse-engineer-anything | [morluto/rea](https://github.com/morluto/rea) | Comes with REA. |

`skill_select`'s catalog also lists a few skills I picked up whose original source I haven't confirmed
(graphify, karpathy-guidelines, review-agent, technical-project-management). If one is yours, open an
issue and I'll credit you and link it.

## License

My three skills (`skills/swarm`, `skills/skill_select`, `skills/prompt_improvement`) and `install.sh` are
MIT-licensed, see [LICENSE](LICENSE). Everything the installer downloads stays under its authors' licenses.
