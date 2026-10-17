# Progress & Kanban Roadmap: RobinRunner

## Project Status Overview
- **Current Phase**: Phase 6: Animation System (Steps 6.1, 6.2 and 6.4 implemented and merged into `main`; Steps 6.3, 6.5-6.7 still open)
- **Active Branch**: `main` (`feature/animation-system` merged)
- **Next Phase**: Phase 6 remaining steps (6.3, 6.5-6.7); lane-change turn clips deferred by the user
- **Overall Health**: Green (All five automated suites pass: core, player, camera, world 5/5, obstacles 9/9)

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

### [x] Phase 3: Camera System & Viewport
- **Branch**: `feature/camera-system`
- **Objective**: Build an engaging third-person runner camera with dynamic feedback.
- [x] Step 3.1: Create Follow Camera controller tracking player position with smooth damping.
- [x] Step 3.2: Implement lateral camera look-ahead aligned with active lane transitions.
- [x] Step 3.3: Implement screen shake utility and speed-based dynamic field-of-view (FOV).
- [x] Step 3.4: Camera framing and visual stability inspection (User Manual Test).

---

### [x] Phase 4: World & Modular Track Generation
- **Branch**: `feature/world-generation`
- **Objective**: Develop an infinite, high-performance modular track generation pipeline using object pooling.
- **Status**: Merged into `main` (`91f5f88` feature commit, `bc04139` merge commit). The memory bank lagged behind this merge and was reconciled during Phase 5.
- [x] Step 4.1: Create base Track Chunk scene (`scenes/world/track_chunk_base.tscn`) with standardized snap anchors.
- [x] Step 4.2: Assemble modular environment chunk variants (Straight Path, Forest Clearing, Rocky Corridor) using Kenney assets.
- [x] Step 4.3: Implement generic `ObjectPool` utility script for efficient node recycling.
- [x] Step 4.4: Implement `TrackSpawner` managing continuous spawning ahead and recycling behind the player.
- [x] Step 4.5: Automated stress tests verifying track memory stability and zero chunk overlap.
- [x] Step 4.6: Chunk stitching, 3-lane alignment, obstacle scaling, and duck barrier visual inspection.

---

### [x] Phase 5: Obstacles & Environmental Hazards
- **Branch**: `feature/obstacles` (merged into `main`)
- **Objective**: Add hazards, barriers, and destructible targets across running lanes.
- [x] Step 5.1: Create static obstacle scenes (Rocks, Fallen Logs, Fences).
- [x] Step 5.2: Create destructible target scenes (Wooden Archery Targets, Fragile Barriers).
- [x] Step 5.3: Integrate obstacle placement patterns into Track Chunks with guaranteed clearable routes.
- [x] Step 5.4: Implement collision resolution (Player hazard collision triggering stumble or game over). Refined into a graded hit rule: `obstacle_tree`, `obstacle_tree_tall` and `barrier_fragile` are lethal (first contact ends the run, bypassing stagger immunity), while `obstacle_log`, `obstacle_rocks`, `obstacle_stones` and `obstacle_fence` stagger once then kill. The `overhead_barrier` applies a backward head-bump posture so the arch reads as a head hit the runner ducks under. (Superseded by Step 5.7, which replaced the "stagger once then kill" allowance with the timed damage window.)
- [x] Step 5.5: Automated tests verifying obstacle collision layers and route passability.
- [x] Step 5.6: Obstacle silhouette clarity and fairness inspection (User Manual Test).
- [x] Step 5.7: Hazard damage window & full-screen red feedback. Replaced the old per-run stumble allowance with a timed vulnerability model. The first forgiving contact (log, rocks, stones, fence, arch) still staggers the archer for 0.6s, but now also opens a 5s damage window (`GameConfig.DAMAGE_WINDOW_DURATION`) announced through the new `EventBus.player_damaged(window_duration)` signal. A second forgiving contact inside that window is fatal, while surviving the window heals the archer and lets a later contact open a fresh window, so a run is no longer limited to one free stumble. The window is drawn by the project's first UI element, `scenes/ui/damage_overlay.tscn` (`DamageOverlay`, a `CanvasLayer` holding a full-rect `ColorRect` tint), which pulses a full-screen red overlay via a `_process`-driven sine and fades out as the window closes; no health bar is shown. On death the overlay switches to a one-shot fade that deepens the impact red all the way to solid black across `DamageOverlay.death_fade_time` (1.2s), so both a lethal hit and a fatal follow-up inside the window end on a black screen. Lethal trees and fragile barriers remain instantly fatal. Both gameplay suites were updated to the new rule.

---

### [ ] Phase 6: Animation System (Character & World Animations)
- **Branch**: `feature/animation-system`
- **Status**: Steps 6.1, 6.2 and 6.4 implemented and merged into `main`; Steps 6.3, 6.5-6.7 remain open
- **Objective**: Integrate comprehensive character, mesh, and environment animations across gameplay entities.
- [x] Step 6.1: Set up player `AnimationPlayer` and state transitions. `PlayerController` drives the archer's `AnimationPlayer` at `Model/ArcherModel/AnimationPlayer` through a state-driven mapping: `idle` in READY, `sprint` while running (playback speed scaled to forward speed), `jump`/`fall` in the air, `duck` (fallback `crouch`) while ducking, `trip` (fallback `hit`) on a ground stagger, and `die` on death. Clips crossfade over 0.15s and idle/sprint loop. Two custom clips were authored in Blender on the rig: `duck`, a deep crouch that halves the head height, and `trip`, a foot-catch that throws the runner into a hop over the obstacle before recovering. The arch head bump reads as a deeper 0.6 rad backward recoil. Visually approved by the user.
- [x] Step 6.2: Lateral lane-change tilt/roll/lean is covered by the existing procedural visual banking in `PlayerController._apply_lane_movement`.
- [ ] Step 6.3: Implement combat action animations (Bow draw, aim hold, arrow release recoil).
- [x] Step 6.4: Implement environmental and foliage animations (wind sway). Added `shaders/foliage_wind.gdshader`, a shared world-space wind field that bends the upper part of each plant toward one common direction with a world-position phase offset, plus `scripts/world/wind_foliage.gd` (`WindFoliage`), which reuses each mesh's original albedo texture and measured height before applying the material. Wrapped onto the tree and tall-tree obstacles and the arch flag. User review asked for stronger amplitude and smoother randomized motion; that pass raised the sway ratio to 0.18 and layered incommensurate sines with per-plant phase/speed jitter, a slow gust envelope, and gentle direction wander. The user re-verified the result.
- [ ] Step 6.5: Implement interactive object animations (obstacle impact wobble/shatter, collectible spin and hover bobbing).
- [ ] Step 6.6: Automated unit tests verifying animation state machines, blend parameters, and signal triggers.
- [ ] Step 6.7: Animation fluidity, blending, and visual inspection (User Manual Test).

---

### [ ] Phase 7: Combat & Ability System (Arrow Shooting)
- **Branch**: `feature/combat-abilities`
- **Objective**: Implement ability gauge charging and active arrow shooting mechanics to destroy obstacles.
- [ ] Step 7.1: Create Arrow projectile scene (`scenes/combat/arrow.tscn`) with forward ballistic trajectory.
- [ ] Step 7.2: Implement Projectile Object Pool for rapid arrow reuse.
- [ ] Step 7.3: Implement Ability Gauge system (meter charges through distance traveled and collected items).
- [ ] Step 7.4: Implement Shoot Input action triggering arrow release when ability gauge is sufficient.
- [ ] Step 7.5: Implement Arrow hit-detection destroying destructible targets and clearing obstacles.
- [ ] Step 7.6: Automated unit tests for ability gauge charging, spending, and projectile lifecycle.
- [ ] Step 7.7: Arrow shooting responsiveness and impact feel inspection (User Manual Test).

---

### [ ] Phase 8: Pickups, Collectibles & Scoring
- **Branch**: `feature/collectibles-scoring`
- **Objective**: Create rewarding collectible loops, score calculation, and ability boosters.
- [ ] Step 8.1: Implement `ScoreManager` calculating distance score and collectible multipliers.
- [ ] Step 8.2: Create Collectible Coin/Essence scene with gentle idle bobbing and rotation.
- [ ] Step 8.3: Implement Collectible Spawner populating lane patterns along track chunks.
- [ ] Step 8.4: Implement Pickup collection triggers granting immediate score and ability gauge bonuses.
- [ ] Step 8.5: Automated unit tests for score accumulation and pickup triggers.
- [ ] Step 8.6: Collectible pickup cadence and readability inspection (User Manual Test).

---

### [ ] Phase 9: User Interface & HUD
- **Branch**: `feature/ui-hud`
- **Objective**: Deliver a clean, stylized user interface covering gameplay HUD, menus, and game-over loops.
- [ ] Step 9.1: Build In-Game HUD (Real-time Score, Distance Counter, Ability Gauge Bar).
- [ ] Step 9.2: Build Main Menu screen (Game Title, Play Button, Controls Guide).
- [ ] Step 9.3: Build Pause Menu overlay (Resume, Restart, Quit/Menu).
- [ ] Step 9.4: Build Game Over screen (Final Score, High Score display, Instant Retry button).
- [ ] Step 9.5: Bind all UI events to `EventBus` and `GameManager` signals.
- [ ] Step 9.6: UI responsiveness, readability, and visual inspection (User Manual Test).

---

### [ ] Phase 10: Audio & Visual Polish
- **Branch**: `feature/audio-visual-polish`
- **Objective**: Elevate game feel with sound effects, ambient music, and stylized particle systems.
- [ ] Step 10.1: Implement `AudioManager` and integrate sound effects (Footsteps, Jump, Bow Fire, Target Shatter, Collect).
- [ ] Step 10.2: Integrate adaptive background music loop with smooth pause ducking.
- [ ] Step 10.3: Add stylized particle systems (Player run dust puffs, target splinter explosion, ability-ready shimmer).
- [ ] Step 10.4: End-to-end game feel and audio balance inspection (User Manual Test).

---

### [ ] Phase 11: Performance Optimization & Multi-Platform Export Preparation
- **Branch**: `feature/optimization-export`
- **Objective**: Optimize draw calls, configure export presets for Desktop and Web, and prepare mobile foundation.
- [ ] Step 11.1: Configure Desktop export presets (Linux, Windows, macOS).
- [ ] Step 11.2: Configure Web export preset and optimize asset compression for rapid HTML5 loading.
- [ ] Step 11.3: Profile draw calls, frame pacing, and memory utilization to ensure solid 60 FPS.
- [ ] Step 11.4: Implement touch/swipe input abstraction layer ready for future Android export.
- [ ] Step 11.5: Final release validation and package verification.

---

## Known Issues & Notes

### Resolved During Phase 5
- **Stale camera FOV assertion**: `tests/unit/test_camera_runner.gd` still expected the pre-Phase 4 default camera FOV of `68.0`, while `scenes/camera/runner_camera.tscn` was calibrated to `64.0` during the Phase 4 framing pass. The camera suite therefore reported `FAIL: Default camera FOV should be 68.0, got: 64.0` and exited with code `1`. The assertion was updated to compare the instantiated camera against its own configured `base_fov`, so future framing calibration can no longer break it.
- **Jolt rejects non-uniform shape scaling**: the previous `duck()` implementation scaled the player capsule to `(1.0, 0.45, 1.0)`. Jolt Physics silently substituted a uniform `0.816667` scale and logged `Failed to correctly scale shape ... is not supported by Jolt Physics for this shape/body`, which shrank the capsule on every axis instead of flattening it. Ducking now swaps between two pre-built `CapsuleShape3D` resources, so the duck silhouette is exact and the engine warning is gone.
- **Log collider one lane off the visible trunk**: `obstacle_log`'s instanced mesh was translated `+0.842` on X, so the visible fallen trunk sat in the right lane while its `CollisionShape3D` stayed centred in the middle lane. Runners visibly passed through the trunk in the right lane and died on an invisible collider in the centre lane, which read as inconsistent "sometimes it kills, sometimes it does not". The mesh offset was flipped to `-0.842` and a `Hazard Visual & Collider Alignment` suite now guards the mesh/collider centre alignment for every hazard.
- **Global class registration lag**: the newly added `scripts/obstacles/destructible.gd` failed to parse with `Could not find base class "Obstacle"` until a filesystem rescan re-registered the new `class_name`. A rescan is required after adding a script that extends a brand new global class.

### Open Notes
- `feature/animation-system` was merged into `main` with Phase 6 partially complete (Steps 6.1, 6.2 and 6.4). The same merge carried Step 5.7 (the hazard damage window and its death fade-to-black overlay) into `main`; the remaining animation steps (6.3, 6.5-6.7) continue on a follow-up branch.
- The old per-run stumble allowance (`GameConfig.MAX_STUMBLES_PER_RUN` and `PlayerController.stumbles_remaining`) was removed in Step 5.7; the damage window now governs fatal follow-up contacts.
- `tests/unit/test_core_architecture.tscn` was re-run after the graded hit rule change and is green (GameConfig, EventBus, GameManager suites all pass). The obstacle suite reports 9/9, and the player and world generation suites are also green.
- Step 5.6 completed: the user performed the human visual pass and confirmed obstacle silhouettes, collider fairness, and duck-barrier clearance, so Phase 5 is now closed.
- Custom animation model swap: the authored `duck` and `trip` clips are now merged into `assets/models/character-archer.glb` (35 clips) and the temporary review copy was removed; `player.tscn` points back at the original model path.
