#!/usr/bin/env python3
import sys, os, json, re

def find_skills_for_prompt(prompt_text, catalog_path):
    if not os.path.exists(catalog_path):
        return []
    with open(catalog_path, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
    
    prompt_lower = prompt_text.lower()
    matches = []
    tokens = [t for t in re.split(r'\W+', prompt_lower) if len(t) > 2]
    
    # Archetype detection
    archetype_hints = {
        'bug': ['systematic-debugging', 'test-driven-development', 'python-debugpy'],
        'fix': ['systematic-debugging', 'ponytail', 'karpathy-guidelines'],
        'leak': ['systematic-debugging', 'performance-optimization', 'karpathy-guidelines'],
        'memory': ['performance-optimization', 'systematic-debugging'],
        'perf': ['performance-optimization', 'code-simplification'],
        'slow': ['performance-optimization', 'systematic-debugging'],
        'crash': ['systematic-debugging', 'debugging-and-error-recovery'],
        'feature': ['spec-driven-development', 'test-driven-development', 'incremental-implementation'],
        'ui': ['popular-web-designs', 'frontend-ui-engineering', 'browser-testing-with-devtools'],
        'css': ['popular-web-designs', 'frontend-ui-engineering'],
        'design': ['popular-web-designs', 'frontend-ui-engineering', 'sketch'],
        'security': ['security-scan', 'finding-discovery', 'threat-model', 'validation'],
        'vulnerability': ['security-diff-scan', 'fix-finding', 'verify-fix'],
        'scrape': ['scrapling', 'blocked-page-recovery', 'parallel-cli'],
        'llm': ['axolotl', 'serving-llms-vllm', 'unsloth', 'dspy'],
        'train': ['axolotl', 'torchtitan', 'weights-and-biases', 'peft'],
        'clean': ['code-simplification', 'simplify-code', 'karpathy-guidelines'],
        'refactor': ['code-simplification', 'ast-grep', 'test-driven-development'],
        'diagram': ['architecture-diagram', 'excalidraw', 'archify'],
        'doc': ['docx', 'pdf', 'documentation-and-adrs'],
        'excel': ['excel-author', 'dcf-model', '3-statement-model']
    }
    
    suggested_names = set()
    for word, skills in archetype_hints.items():
        if word in prompt_lower:
            suggested_names.update(skills)
            
    for skill in catalog:
        name = skill['name']
        summary = skill.get('summary', '').lower()
        use_case = skill.get('use_case', '').lower()
        score = 0
        
        if name in suggested_names:
            score += 15
        if name in prompt_lower:
            score += 20
            
        for t in tokens:
            if t in name:
                score += 4
            if t in summary:
                score += 2
            if t in use_case:
                score += 1
                
        if score > 0:
            matches.append((score, skill))
            
    matches.sort(key=lambda x: x[0], reverse=True)
    return [m[1] for m in matches[:4]]

def generate_improved_prompt(prompt_text, catalog_path):
    skills = find_skills_for_prompt(prompt_text, catalog_path)
    
    skill_bullets = []
    for s in skills:
        skill_bullets.append(f"- **`{s['name']}`**: {s['summary']}")
        
    skills_text = "\n".join(skill_bullets) if skill_bullets else "- *(Consult `skill_select` for specific domain skills)*"
    
    template = f"""# IMPROVED PROMPT PROPOSAL

## 🎯 Primary Objective
{prompt_text.strip()}

## 🛠️ Recommended Skills & Tools (via `skill_select`)
{skills_text}

## 📋 Context & Constraints
- **Scope**: Identify target files, modules, and directories before writing code.
- **Negative Constraints**:
  - Do NOT modify unrelated files or formatting.
  - Do NOT add unnecessary abstractions or speculative features (YAGNI).
  - Preserve all existing public APIs and conventions.
- **Assumptions**: Surface all implicit decisions rather than making silent guesses.

## 🔄 Execution Plan
1. **Investigation / RED**: Inspect relevant source files, reproduce symptoms, or write failing tests.
2. **Implementation / GREEN**: Apply surgical changes adhering strictly to selected skill guidelines.
3. **Verification / REFACTOR**: Run project test suites, linters, and verification checks.

## ✅ Verification Criteria
- All tests pass without warnings.
- Changes are verified against the original objective.
"""
    return template

if __name__ == '__main__':
    raw = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Fix the broken audio sync in timeline"
    # skill_select is installed next to this skill in every harness; fall back to known locations.
    here = os.path.dirname(os.path.abspath(__file__))
    rel = os.path.join('skill_select', 'references', 'all_skills_catalog.json')
    candidates = [os.path.join(here, '..', '..', rel)] + [
        os.path.expanduser(os.path.join(d, rel)) for d in
        ('~/.claude/skills', '~/.agents/skills', '~/.gemini/config/skills', '~/.hermes/skills', '~/.dsh/skills')]
    cat_path = next((p for p in candidates if os.path.exists(p)), candidates[0])
    print(generate_improved_prompt(raw, cat_path))
