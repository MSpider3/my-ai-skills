# Prompt Transformation Examples

This reference documents real before-and-after prompt transformations demonstrating how `prompt_improvement` and `skill_select` enhance user queries.

---

### Example 1: Bug Fixing
**Raw Prompt**:
> "fix the bug where video playback stutters when scrubbing fast"

**Improved Prompt**:
```markdown
## Objective
Diagnose and resolve the video playback stutter occurring during high-speed timeline scrubbing.

## Recommended Skills (via `skill_select`)
- **`systematic-debugging`**: Use the 4-phase root-cause runbook (reproduce -> isolate -> hypothesize -> verify) before modifying code.
- **`test-driven-development`**: Write an automated test reproducing the scrubbing latency regression before fixing.
- **`karpathy-guidelines`**: Make surgical edits; do not refactor unaffected playback pipelines.

## Constraints & Scope
- Scope: `tempo-media` decoder loop and `tempo-ui` playhead scrub listener.
- PipeWire real-time callback must NEVER allocate memory or block on mutexes.
- Keep RAM usage strictly under 2 GB; avoid eager full-clip caching.

## Verification
- Run `cargo test -p tempo-media` and `./scripts/run_all_tests.sh`.
- Validate smooth playhead scrubbing at 60 FPS without frame drops.
```

---

### Example 2: Frontend UI Development
**Raw Prompt**:
> "make the settings dialog look modern"

**Improved Prompt**:
```markdown
## Objective
Redesign the settings modal dialog to achieve a state-of-the-art, polished dark-theme interface consistent with professional NLE applications.

## Recommended Skills (via `skill_select`)
- **`popular-web-designs`**: Extract layout, typography, and styling tokens from modern design systems (e.g. Linear, Resolve).
- **`frontend-ui-engineering`**: Build accessible, keyboard-navigable dialogs with clean CSS and micro-animations.
- **`browser-testing-with-devtools`**: Verify visual hierarchy, contrast ratios, and responsive reflow.

## Constraints & Scope
- Touch only `assets/style/tempo.css` and the settings dialog widget in `crates/tempo-ui/src/dialogs/`.
- Preserve all existing keybind settings, Resolve keybind mappings, and toggle persistence.
- Do NOT add unconnected or placeholder UI controls.

## Verification
- Launch application via `cargo run --bin tempo` and open settings modal.
- Inspect keyboard navigation (Tab/Shift-Tab, Escape to close).
```

---

### Example 3: Security & Code Auditing
**Raw Prompt**:
> "check if our auth endpoints are safe"

**Improved Prompt**:
```markdown
## Objective
Perform a comprehensive security audit of authentication and authorization handlers to detect vulnerabilities against the OWASP Top Ten.

## Recommended Skills (via `skill_select`)
- **`security-scan`**: Execute a systematic audit of session management, token validation, and password hashing paths.
- **`finding-discovery`**: Identify all candidate vulnerabilities from untrusted request inputs to auth sinks.
- **`threat-model`**: Evaluate privilege escalation and credential leakage vectors.

## Scope & Constraints
- Focus on `/api/auth/*` routes and token validation middlewares.
- Read-only audit; do not modify auth logic until findings are prioritized.

## Verification
- Produce a prioritized vulnerability report with proof-of-concept vectors and remediation recommendations.
```
