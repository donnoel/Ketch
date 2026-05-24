# AGENTS.project.md

# Ketch Project Guide for Agents

## Product intent
Ketch is a beginner-friendly SpriteKit catch game built to teach Apple game-development fundamentals through a small, playable loop.

Success for the current phase means gameplay stays clear and stable: move basket, catch falling objects, lose lives on misses, progress levels, and restart cleanly after game over.

## Current product phase
Ketch is in learning-prototype / MVP gameplay phase.

Current scope:
- SpriteKit scene hosted by `GameViewController`
- Tap-to-move basket control
- Random falling apples/stars with physics contacts
- Score, level, and three-heart HUD
- Catch feedback (sparkle + basket bounce)
- Miss feedback (label + scene shake + heart pulse)
- Progressive difficulty via spawn-delay and gravity scaling
- Game-over label and tap-to-restart full reset

Out of scope for this phase:
- monetization, accounts, backend sync, multiplayer, achievements, ads, and analytics pipelines
- heavy menu systems, inventory/meta progression, or content authoring tools
- third-party game engines/libraries

## Architecture snapshot
App and scene hosting:
- `GameViewController` presents `GameScene` and keeps SpriteKit debug overlays off for normal gameplay.

Gameplay scene:
- `GameScene` owns setup, spawning, physics contacts, scoring, lives, level progression, game-over handling, and restart behavior.

Core runtime state:
- `score`, `lives`, `level`, `isGameOver`
- player node (`player`)
- HUD nodes (`scoreLabel`, `levelLabel`, `gameOverLabel`, `heartNodes`)

Physics categories:
- `player`
- `fallingObject`
- `ground`

Assets and visuals:
- Asset catalog-backed sprites for basket, falling objects, hearts, background, and sparkle.

## Behavior invariants (do not regress)
- Basket movement must clamp to visible horizontal bounds.
- Catching a falling object increments score exactly once and removes that node.
- Missing a falling object decrements lives exactly once and removes that node.
- Level equals `(score / 5) + 1` with gravity and spawn delay recalculated on level-up.
- Lives start at 3 and game ends when lives reach 0.
- When game is over, spawning stops and the game-over label is shown.
- Tapping while game-over is visible resets scene state to a clean run (score/lives/level/actions/nodes).
- Debug overlays remain off in normal gameplay.

## Concurrency and state rules
- Keep gameplay state mutations inside `GameScene` methods.
- Keep contact routing explicit via `didBegin(_:)` and helper handlers.
- Avoid duplicate restart/reset paths that can diverge.
- Keep physics/action keys deterministic so repeated actions can be replaced safely.

## UX rules
- Keep the loop simple and readable for learning.
- Add mechanics one at a time, with visible feedback.
- Preserve the current tap-to-move interaction unless the task explicitly changes controls.
- Keep HUD text plain and immediately understandable.

## Accessibility requirements
Accessibility applies to user-facing overlays and any UIKit-hosted controls.

Current known baseline:
- score, level, lives, and game-over state are visually represented.

Still verify or improve when touching UI/HUD:
- VoiceOver-readable equivalents for critical game state where feasible
- readability/contrast for labels over background art
- motion-heavy feedback behavior for users sensitive to animation

## Build/run notes
- Project: `Ketch.xcodeproj`
- Scheme: `Ketch`
- Target platform: iOS Simulator
- Build command:
  - `xcodebuild -project Ketch.xcodeproj -scheme Ketch -destination 'generic/platform=iOS Simulator' clean build`
- Warning policy: treat warnings as failures.

## Near-term priorities
- Add a start screen and clearer onboarding for first run.
- Add sound effects with opt-out/volume-friendly behavior.
- Tune iPad layout and safe-area-sensitive HUD placement.
- Add high score persistence and basic test coverage around gameplay-state helpers.

## Output expectations per patch
Provide:
- Summary of change
- Files modified
- Any migration considerations
- Commit message suggestion
- Accessibility notes for user-facing work: added, verified, missing, or not applicable
