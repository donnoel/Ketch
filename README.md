# **Ketch**
### *A beginner-friendly SpriteKit catch game for learning Apple game development one small mechanic at a time.*

<p align="center">
  <img src="https://img.shields.io/badge/Swift-SpriteKit-orange?logo=swift">
  <img src="https://img.shields.io/badge/Platform-iOS%20%2B%20iPadOS-blue">
  <img src="https://img.shields.io/badge/Game%20Loop-Catch%20Arcade-purple">
  <img src="https://img.shields.io/badge/Status-Learning%20Prototype-green">
</p>

---

## What is Ketch?

**Ketch** is a small SpriteKit arcade game built as a hands-on learning project.

The player moves a basket along the bottom of the screen and catches falling objects. Catches increase the score, missed objects reduce lives, and the game gradually speeds up as the player levels up.

The goal of the project is not to overbuild a giant game. The goal is to learn game development fundamentals in a simple, visible, playable loop.

---

## Core Features

| Feature | Description |
|--------|-------------|
| **SpriteKit Game Scene** | A focused `GameScene` drives gameplay, physics, spawning, scoring, and restart behavior. |
| **Basket Player** | The player controls a basket at the bottom of the screen. |
| **Tap-to-Move Controls** | Tap anywhere horizontally and the basket moves smoothly to that position. |
| **Falling Objects** | Stars and apples spawn from the top of the screen and fall using SpriteKit physics. |
| **Catch Detection** | SpriteKit contact handling detects when falling objects reach the basket. |
| **Miss Detection** | A ground contact zone detects missed objects and removes lives. |
| **Score HUD** | Successful catches increase the score. |
| **Heart Lives HUD** | Three heart icons show remaining lives. Lost lives fade visually instead of using plain text. |
| **Level Progression** | Every five catches increases the level. Higher levels spawn objects faster and increase gravity. |
| **Catch Feedback** | Catching an object creates a quick sparkle effect and a small basket bounce. |
| **Game Over State** | When lives reach zero, spawning stops and the player can tap to restart. |
| **Asset Catalog Art** | Game art is stored in `Assets.xcassets`, including basket, falling objects, hearts, background, and sparkle. |

---

## Controls

- **Move Basket**: Tap anywhere on the screen.
- **Catch Objects**: Move the basket under falling apples and stars.
- **Avoid Misses**: Each missed object costs one heart.
- **Restart**: Tap the screen after Game Over.

---

## How it works

Ketch follows a simple SpriteKit gameplay pipeline:

1. `GameViewController` creates and presents `GameScene`.
2. `GameScene` sets up the background, physics world, player, HUD, and spawn loop.
3. Falling objects are spawned at random horizontal positions.
4. SpriteKit physics applies gravity to falling objects.
5. Contact detection determines whether an object was caught by the basket or missed at the ground zone.
6. Catches increment the score, show sparkle feedback, bounce the basket, and may increase the level.
7. Misses remove a heart.
8. When lives reach zero, spawning stops and the Game Over label appears.
9. A tap after Game Over resets score, lives, level, scene nodes, and spawning.

---

## Architecture Overview

### **GameViewController**
- Hosts the SpriteKit view.
- Creates `GameScene` using the current view size.
- Presents the scene in portrait orientation.
- Keeps SpriteKit debug overlays disabled for normal gameplay.

### **GameScene**
- Owns the full game loop.
- Manages player movement, falling object spawning, score, lives, level, collision handling, and restart state.
- Uses small helper methods for setup, feedback animation, level updates, and physics contact routing.

### **Physics Categories**
- `player`: the basket controlled by the user.
- `fallingObject`: apples and stars that fall from the top of the screen.
- `ground`: the invisible miss detector near the bottom of the scene.

### **Assets**
Current asset catalog entries include:

```text
Assets.xcassets/
├── AppIcon.appiconset
├── AccentColor.colorset
├── player-basket.imageset
├── falling-star.imageset
├── falling-apple.imageset
├── life-heart.imageset
├── game-background.imageset
└── sparkle.imageset
```

---

## Project Structure

```text
Ketch/
├── Ketch/
│   ├── Assets.xcassets/
│   ├── GameScene.swift
│   ├── GameViewController.swift
│   └── Info.plist
├── Ketch.xcodeproj
└── README.md
```

---

## Getting Started

### Requirements
- Xcode 26+
- iOS Simulator runtime or physical iPhone/iPad device
- Swift
- SpriteKit

### Setup
1. Open `/Users/donnoel/Development/Ketch/Ketch.xcodeproj`.
2. Select the `Ketch` scheme.
3. Choose an iPhone or iPad simulator.
4. Build and run.

### Build

```bash
xcodebuild -project Ketch.xcodeproj -scheme Ketch -destination 'generic/platform=iOS Simulator' clean build
```

### Run from Xcode

```text
Command-R
```

### Clean Build Folder

```text
Shift-Command-K
```

---

## Development Notes

- This is intentionally a small learning project.
- Prefer small, understandable changes over large rewrites.
- Keep gameplay mechanics visible and easy to reason about.
- SpriteKit debug overlays should remain off during normal gameplay.
- Add new mechanics one at a time so each change can be tested directly.

---

## Troubleshooting

### Bottom-right `fps` / `nodes` text appears

That text comes from SpriteKit debug overlay settings in `GameViewController.swift`.

Confirm these are disabled:

```swift
skView.showsFPS = false
skView.showsNodeCount = false
skView.showsPhysics = false
skView.showsDrawCount = false
skView.showsQuadCount = false
```

Then clean and run again:

```text
Shift-Command-K
Command-R
```

### Build error: `Invalid redeclaration of GameViewController`

`GameViewController` was likely pasted into the wrong file.

- `GameScene.swift` should contain `final class GameScene`.
- `GameViewController.swift` should contain `final class GameViewController`.

### Build error: `Cannot find GameScene in scope`

Confirm `GameScene.swift` still contains:

```swift
final class GameScene: SKScene, SKPhysicsContactDelegate
```

---

## Roadmap

- [ ] Add start screen before gameplay begins.
- [ ] Add sound effects for catch, miss, level up, and game over.
- [ ] Add miss feedback animation.
- [ ] Tune iPad layout and basket placement.
- [ ] Add high score tracking.
- [ ] Add multiple falling object types with different point values.
- [ ] Add a simple settings/pause screen.
- [ ] Add basic automated build/test workflow.

---

## Credits

Built with care by **Don Noel** and Codex collaboration.

---

> *Ketch is designed to make game development visible, playful, and learnable through one clean catch loop.*
