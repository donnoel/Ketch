# AGENTS.md

This repo is an Apple-platform game codebase. You are an engineering agent (Codex) collaborating with the human. Your job is to make small, correct, testable changes with a clean build at every step.

## Hard requirements (do not violate)
- **No build warnings.** Treat warnings as errors in practice.
- **No large rewrites.** Prefer small, surgical diffs.
- **Apple-native only.** No third-party libraries unless explicitly requested.
- **SpriteKit-first architecture.** Keep gameplay logic in `GameScene`; keep view-controller code focused on scene hosting.
- **Preserve core behavior contracts.** Do not regress existing user-visible gameplay loops without explicitly calling it out.
- **Keep gameplay deterministic enough to debug.** Avoid hidden side effects that make collisions/spawn timing harder to reason about.
- **Accessibility is first-class.** Treat accessibility as a foundation requirement for user-facing overlays and labels, not a later polish pass.

## Workflow
1. Read existing code and architecture before editing.
2. Read `AGENTS.project.md` before making project-specific decisions.
3. Propose a minimal plan in 2-5 bullets.
4. Implement the smallest viable patch; solve the specific problem first before generalizing.
5. Ensure build passes with **zero warnings**.
6. If tests exist or are touched, run them. Add tests for non-trivial logic where practical.
7. If behavior changed, update docs (`README.md` / `AGENTS.project.md`) in the same patch.
8. Keep changes easy to validate locally.
9. For user-facing UI/HUD work, perform an accessibility pass before considering the task done.

## Accessibility baseline (required)
For every user-facing overlay, label, control, or interaction path, evaluate and implement relevant accessibility support.

Always scan for and handle, where applicable:
- VoiceOver support for UIKit-hosted controls and overlays outside SpriteKit rendering
- Clear score/lives/state communication for users who cannot rely on visual-only feedback
- Sufficient contrast and legibility in light/dark conditions
- Hit target size for tappable controls and restart affordances
- Reduce Motion accommodations for shake, bounce, or particle-heavy effects when feasible
- State communication for game over, restart readiness, and progression states

Rules:
- Do not claim accessibility support exists unless there is concrete code evidence.
- Prefer Apple-native accessibility APIs and semantics over custom workarounds.
- If a visual treatment weakens accessibility, fix it or call out the gap explicitly.

## Code style
- Keep types small and focused.
- Keep scene setup, spawn logic, collision routing, and HUD updates in clearly separated helpers.
- Avoid invasive refactors unless the current structure is blocking progress.
- Keep physics categories, node lifecycle, and restart flow explicit and easy to trace.
- Avoid duplicate mutation paths for score/lives/level/game-over state.
- Keep action keys stable and intentional to avoid animation/action conflicts.
- Document non-obvious gameplay invariants when needed.

## Deliverables for each change
- Mention which files were modified and why.
- Provide a short commit message suggestion.
- Mention any user-visible behavior changes explicitly.
- Mention accessibility impact for user-facing changes: what was improved, verified, still missing, or not applicable.

## What not to do
- Don't introduce new dependencies.
- Don't hide behavior changes in unrelated refactors.
- Don't spread gameplay state across unrelated files without need.
- Don't leave debug overlays on for normal gameplay unless explicitly requested.
- Don't mark an accessibility feature as supported unless the implementation is actually present and appropriate.

If something is ambiguous, default to the simplest solution that preserves correctness and forward progress.

## Quota Discipline / Quota-Smart Codex Mode

Use the smallest amount of work necessary to complete the task correctly.

### Before editing

- Read only the files needed for the requested change.
- Do not scan the whole repository unless the task truly requires it.
- Do not run broad audits unless explicitly asked.
- Prefer targeted searches by filename, symbol name, failing build output, or known gameplay area.
- Ask for clarification only if the requested change is unsafe or ambiguous enough to risk breaking behavior.

### While editing

- Make the smallest safe diff.
- Avoid opportunistic refactors.
- Do not rewrite working code to improve style alone.
- Do not touch unrelated files.
- Do not expand scope beyond the requested task.

### Validation

Use the narrowest useful validation first.

Preferred validation ladder:

1. Build check for the touched target.
2. Targeted test if logic changed.
3. Full suite only for broad architecture or release-affecting changes.

Do not run broad validation when a targeted check is enough.

### Output

Keep responses short and concrete.

Report only:

- what changed
- files touched
- validation performed
- anything skipped and why
