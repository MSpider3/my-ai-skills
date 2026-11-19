---
name: prompt_improvement
description: >-
  Transforms raw, informal, or ambiguous user prompts into high-leverage, well-structured
  instructions. Automatically selects and embeds the optimal skills from the Antigravity/Claude
  skills vault using skill_select. Strictly enforces a mandatory confirmation gate: always asks
  the user to review and confirm the improved prompt before executing or moving on.
  Triggers on: "improve prompt", "refine prompt", "optimize prompt", "make this prompt better",
  "prompt_improvement", "promt_imporvemt", or whenever a user request lacks clarity, scope,
  constraints, or skill alignment.
---

# Prompt Improvement (`prompt_improvement`)

`prompt_improvement` takes raw, conversational, or underspecified user prompts and refines them into crisp, actionable, senior-level instructions. It directly leverages **`skill_select`** to identify and embed the ideal specialized skills from the vault (350+ skills), while enforcing a **mandatory confirmation gate** before any execution begins.

---

## 🚨 The Golden Rule: Mandatory Confirmation Gate

> **CRITICAL REQUIREMENT**:
> You must **NEVER** begin executing the task (writing code, editing files, running destructive commands) immediately after improving the prompt.
> You must **ALWAYS** present the improved prompt to the user and obtain explicit confirmation before proceeding.

---

## The 4-Phase Prompt Improvement Workflow

### Phase 1: Ingestion & Deconstruction
Analyze the user's request and identify:
1. **Core Intent**: What is the user ultimately trying to achieve?
2. **Implicit Assumptions**: What details is the model likely to guess? (e.g., framework, architecture, error handling). Surface them!
3. **Missing Constraints**: Are there performance budgets, style conventions, or files that must NOT be touched?
4. **Task Archetype**: Is this a bug fix, greenfield feature, refactor, security audit, UI polish, or scraping task?

### Phase 2: Skill Selection via `skill_select`
Consult the **`skill_select`** taxonomy and catalog:
1. Identify the **Primary Recommended Skill** (e.g., `systematic-debugging` for bugs, `spec-driven-development` for features, `ponytail` for minimal fixes, `popular-web-designs` for UIs).
2. Identify **Supporting / Chained Skills** (e.g., `test-driven-development`, `karpathy-guidelines`, `code-simplification`).
3. Extract the critical procedural rules from those skills and embed them directly into the improved prompt.

### Phase 3: Construct the "Proper" Prompt
Format the improved prompt following this high-leverage template:

```markdown
### 🎯 Objective
[1-2 clear, unambiguous sentences defining the desired end state]

### 🛠️ Selected Skills (via `skill_select`)
- **[Skill Name]** ([link]): [Why selected and specific runbook rules to enforce]

### 📋 Context & Constraints
- **Target Scope**: [Explicit files, crates, or modules to inspect/edit]
- **Negative Constraints**: [What NOT to touch, what libraries NOT to add, style rules]
- **Architectural Invariants**: [Key rules to preserve]

### 🔄 Step-by-Step Execution Plan
1. **Phase 1 (Investigation/Verification)**: [Reproduce issue or analyze existing code]
2. **Phase 2 (Implementation)**: [Surgical, minimal changes matching selected skills]
3. **Phase 3 (Validation)**: [Run test suites, linters, or smoke tests]

### ✅ Success & Verification Criteria
- [Exact command or observable proof of completion]
```

### Phase 4: Confirmation Gate Execution
Present the improved prompt to the user and request confirmation:

- **In Antigravity IDE**: Call the `ask_question` tool:
  - Option 1: `(Recommended) Proceed with the improved prompt`
  - Option 2: `Make adjustments to the prompt`
  - Option 3: `Execute original prompt without changes`
- **In Claude Code / CLI**: Print the improved prompt block, summarize the selected skills, and ask:
  > *"Shall I proceed with this improved prompt? (Reply 'yes' to proceed, provide changes to adjust, or type 'original' to run your original request)"*
  **Then STOP your turn and wait for the user's response.**

---

## Helper Script

Run the automated prompt helper script to match keywords and scaffold the prompt:
```bash
python3 <this skill folder>/scripts/improve_prompt.py "<user prompt>"
```

---

## Supporting References & Examples
- **Before & After Transformations**: [examples/prompt_transformations.md](./examples/prompt_transformations.md)
- **Detailed Confirmation Protocol**: [references/confirmation_protocol.md](./references/confirmation_protocol.md)
- **Skill Selector & Catalog**: [../skill_select/SKILL.md](../skill_select/SKILL.md)
