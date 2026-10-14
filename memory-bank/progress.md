# Progress & Kanban Roadmap: RobinRunner

## Project Status Overview
- **Current Phase**: Phase 3: Camera System & Viewport (In Progress - Logic Complete, Awaiting Visual Check)
- **Active Branch**: `feature/camera-system`
- **Next Phase**: Phase 4: World & Modular Track Generation
- **Overall Health**: Green (Baseline clean, guidelines and configurations locked)

---

## Detailed Kanban Phase Roadmap

### [x] Phase 0: Project Initialization & Standards Setup
- [x] Step 0.1: Configure comprehensive `.gitignore` for Godot 4, Android, Blender, and OS artifacts.
- [x] Step 0.2: Formalize project rules, constraints, language policy, and workflow in `projectRules.md`.
- [x] Step 0.3: Commit initial project baseline, configurations, and Kenney Mini-Forest assets (`e516034`).
- [x] Step 0.4: Establish complete, persistent Memory Bank structure.

---

### [x] Phase 1: Project Architecture & Core Infrastructure
- **Branch**: `feature/core-architecture`
- **Objective**: Build foundational directory layouts, global singletons, state controllers, and testing scaffolds.
- [x] Step 1.1: Organize project directory structure (`scenes/`, `scripts/`, `assets/`, `tests/`).
- [x] Step 1.2: Implement `EventBus.gd` autoload singleton for global decoupled signals.
- [x] Step 1.3: Implement `GameConfig.gd` containing lane coordinates, base speeds, and gameplay constants.
- [x] Step 1.4: Implement `GameManager.gd` state machine (`Ready`, `Playing`, `Paused`, `GameOver`).
- [x] Step 1.5: Automated unit tests for EventBus signal dispatch and GameManager state transitions.

---

### [x] Phase 2: Player Controller & Movement Mechanics
- **Branch**: `feature/player-controller`
- **Objective**: Implement responsive 3-lane movement, jumping physics, and player state handling.
- [x] Step 2.1: Create Player scene (`scenes/player/player.tscn`) using Kenney archer mesh with collision shape.
- [x] Step 2.2: Implement Lane Switcher Controller with smooth lateral interpolation (Left, Center, Right).
- [x] Step 2.3: Implement Jump & Gravity Controller with snappy arc and ground detection.
- [x] Step 2.4: Implement forward speed controller and acceleration curves.
- [x] Step 2.5: Automated unit tests verifying lane bounds, jump height, and state consistency.
- [x] Step 2.6: Visual and movement feel inspection (User Manual Test).

---

### [ ] Phase 3: Camera System & Viewport
- **Branch**: `feature/camera-system`
- **Objective**: Build an engaging third-person runner camera with dynamic feedback.
- [x] Step 3.1: Create Follow Camera controller tracking player position with smooth damping.
- [x] Step 3.2: Implement lateral camera look-ahead aligned with active lane transitions.
- [x] Step 3.3: Implement screen shake utility and speed-based dynamic field-of-view (FOV).
- [ ] Step 3.4: Camera framing and visual stability inspection (User Manual Test).

---

### [ ] Phase 4: World & Modular Track Generation
- **Branch**: `feature/world-generation`
- **Objective**: Develop an infinite, high-performance modular track generation pipeline using object pooling.
- [ ] Step 4.1: Create base Track Chunk scene (`scenes/world/track_chunk_base.tscn`) with standardized snap anchors.
- [ ] Step 4.2: Assemble modular environment chunk variants (Straight Path, Forest Clearing, Rocky Corridor) using Kenney assets.
- [ ] Step 4.3: Implement generic `ObjectPool` utility script for efficient node recycling.
- [ ] Step 4.4: Implement `TrackSpawner` managing continuous spawning ahead and recycling behind the player.
- [ ] Step 4.5: Automated stress tests verifying track memory stability and zero chunk overlap.
- [ ] Step 4.6: Chunk stitching and visual seam alignment inspection (User Manual Test).

---

### [ ] Phase 5: Obstacles & Environmental Hazards
- **Branch**: `feature/obstacles`
- **Objective**: Add hazards, barriers, and destructible targets across running lanes.
- [ ] Step 5.1: Create static obstacle scenes (Rocks, Fallen Logs, Fences).
- [ ] Step 5.2: Create destructible target scenes (Wooden Archery Targets, Fragile Barriers).
- [ ] Step 5.3: Integrate obstacle placement patterns into Track Chunks with guaranteed clearable routes.
- [ ] Step 5.4: Implement collision resolution (Player hazard collision triggering stumble or game over).
- [ ] Step 5.5: Automated tests verifying obstacle collision layers and route passability.
- [ ] Step 5.6: Obstacle silhouette clarity and fairness inspection (User Manual Test).

---

### [ ] Phase 6: Combat & Ability System (Arrow Shooting)
- **Branch**: `feature/combat-abilities`
- **Objective**: Implement ability gauge charging and active arrow shooting mechanics to destroy obstacles.
- [ ] Step 6.1: Create Arrow projectile scene (`scenes/combat/arrow.tscn`) with forward ballistic trajectory.
- [ ] Step 6.2: Implement Projectile Object Pool for rapid arrow reuse.
- [ ] Step 6.3: Implement Ability Gauge system (meter charges through distance traveled and collected items).
- [ ] Step 6.4: Implement Shoot Input action triggering arrow release when ability gauge is sufficient.
- [ ] Step 6.5: Implement Arrow hit-detection destroying destructible targets and clearing obstacles.
- [ ] Step 6.6: Automated unit tests for ability gauge charging, spending, and projectile lifecycle.
- [ ] Step 6.7: Arrow shooting responsiveness and impact feel inspection (User Manual Test).

---

### [ ] Phase 7: Pickups, Collectibles & Scoring
- **Branch**: `feature/collectibles-scoring`
- **Objective**: Create rewarding collectible loops, score calculation, and ability boosters.
- [ ] Step 7.1: Implement `ScoreManager` calculating distance score and collectible multipliers.
- [ ] Step 7.2: Create Collectible Coin/Essence scene with gentle idle bobbing and rotation.
- [ ] Step 7.3: Implement Collectible Spawner populating lane patterns along track chunks.
- [ ] Step 7.4: Implement Pickup collection triggers granting immediate score and ability gauge bonuses.
- [ ] Step 7.5: Automated unit tests for score accumulation and pickup triggers.

---

### [ ] Phase 8: User Interface & HUD
- **Branch**: `feature/ui-hud`
- **Objective**: Deliver a clean, stylized user interface covering gameplay HUD, menus, and game-over loops.
- [ ] Step 8.1: Build In-Game HUD (Real-time Score, Distance Counter, Ability Gauge Bar).
- [ ] Step 8.2: Build Main Menu screen (Game Title, Play Button, Controls Guide).
- [ ] Step 8.3: Build Pause Menu overlay (Resume, Restart, Quit/Menu).
- [ ] Step 8.4: Build Game Over screen (Final Score, High Score display, Instant Retry button).
- [ ] Step 8.5: Bind all UI events to `EventBus` and `GameManager` signals.
- [ ] Step 8.6: UI responsiveness, readability, and visual inspection (User Manual Test).

---

### [ ] Phase 9: Audio & Visual Polish
- **Branch**: `feature/audio-visual-polish`
- **Objective**: Elevate game feel with sound effects, ambient music, and stylized particle systems.
- [ ] Step 9.1: Implement `AudioManager` and integrate sound effects (Footsteps, Jump, Bow Fire, Target Shatter, Collect).
- [ ] Step 9.2: Integrate adaptive background music loop with smooth pause ducking.
- [ ] Step 9.3: Add stylized particle systems (Player run dust puffs, target splinter explosion, ability-ready shimmer).
- [ ] Step 9.4: End-to-end game feel and audio balance inspection (User Manual Test).

---

### [ ] Phase 10: Performance Optimization & Multi-Platform Export Preparation
- **Branch**: `feature/optimization-export`
- **Objective**: Optimize draw calls, configure export presets for Desktop and Web, and prepare mobile foundation.
- [ ] Step 10.1: Configure Desktop export presets (Linux, Windows, macOS).
- [ ] Step 10.2: Configure Web export preset and optimize asset compression for rapid HTML5 loading.
- [ ] Step 10.3: Profile draw calls, frame pacing, and memory utilization to ensure solid 60 FPS.
- [ ] Step 10.4: Implement touch/swipe input abstraction layer ready for future Android export.
- [ ] Step 10.5: Final release validation and package verification.

---

## Known Issues & Notes
- None currently logged. All initial setup steps completed cleanly.
