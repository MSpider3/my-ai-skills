# Mandatory User Confirmation Protocol

The core requirement of `prompt_improvement` is that **under no circumstances may an agent execute the task with the improved prompt without explicit user confirmation**.

---

## 1. Antigravity IDE Confirmation Protocol

In the Antigravity IDE, use the interactive `ask_question` tool:

```json
{
  "questions": [
    {
      "question": "I have improved your prompt with recommended skills and execution constraints. How would you like to proceed?",
      "options": [
        "(Recommended) Proceed with the improved prompt",
        "Make adjustments to the prompt",
        "Execute my original prompt without changes"
      ],
      "is_multi_select": false
    }
  ],
  "toolAction": "Requesting confirmation on improved prompt",
  "toolSummary": "Prompt confirmation"
}
```

- If the user selects **Option 1 ("Proceed")**, load the selected skills using `view_file` and begin execution.
- If the user selects **Option 2 ("Make adjustments")**, prompt the user for their desired changes and refine.
- If the user selects **Option 3 ("Execute original")**, run the original user request without applying the improvements.

---

## 2. Claude Code CLI Confirmation Protocol

In the Claude Code CLI (or headless terminal environment):

1. Print the improved prompt clearly inside a markdown block.
2. Present a concise bullet list of the selected skills from `skill_select`.
3. Ask the user directly at the end of the response:
   > **"Shall I proceed with this improved prompt? (Reply 'yes' to proceed, provide changes to adjust, or type 'original' to run your original request)"**
4. **STOP EXECUTION IMMEDIATELY**. Do not run commands, do not edit files, do not spawn subagents.
5. Wait for the user's next turn. Only proceed once the user provides confirmation.
