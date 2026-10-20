# Progress & Kanban Roadmap: RobinRunner

## Project Status Overview
- **Current Phase**: Phase 7: Combat & Ability System (Steps 7.1-7.6, plus the 7.6b/7.6c pickups and bow/HUD passes, the 7.6d hand-bone bow attachment, the 7.6e ladder topple pass and the 7.6f archery target sticking pass, implemented; Step 7.7 manual test pending; Step 6.3 pulled in per user decision)
- **Active Branch**: `feature/combat-abilities` (merged `main` in at `b747e41`; ladder, flame-arrow and archery-target passes on top)
- **Next Phase**: Merge `feature/combat-abilities` on user approval; Phase 7 Step 7.7 manual test; Phase 6 leftovers (6.5-6.7) and Phase 8 remain open
- **Overall Health**: Green (All six automated suites pass: core, player, camera, world 5/5, obstacles 9/9, combat 9/9)

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
- [x] Step 4.7: Randomized, fair chunk hazard layouts (`feature/chunk-variation`). Chunk selection was already random across the three variants, but every variant carried one authored layout, so recycled chunks looked identical. Each chunk scene now holds a `ChunkHazards` node running `scripts/world/chunk_hazard_generator.gd` (`ChunkHazardGenerator`) with a flavored palette (`straight`: fence/stones, `forest`: tree/tall tree/target/arch, `rocky`: rocks/ladder/tree/log). The generator binds to `TrackChunk.activated` and rebuilds the layout on every reuse: it picks 2-4 rows from the fixed offsets (-8, -14, -20, -26), rolls 1-2 blocked lanes per row (35% dense rows), and spawns a distinct scene per blocked lane on the matching lane X. Fairness is enforced structurally: a dense row leaves exactly one free lane, and when the previous row was dense the new free lane may only be that lane +/-1, so the runner is never forced into a two-lane jump. A single-hazard row resets that constraint and blocks the least-used lane instead. Lane selection is balanced per chunk: the generator keeps a per-lane block counter, single rows always take the least-used lane, and dense rows choose the free lane that blocks the two least-used lanes (random tie-break), so as soon as a layout has three or more hazards every lane carries at least one and one lane can no longer stay visibly empty. Removed the authored obstacle nodes from the three chunk scenes (including the rocky pickup that was seated on the authored rocks, since the rocks are no longer guaranteed) and updated the tests: the obstacle suite now activates every chunk 30 times and validates row count (2-4), one clear lane per row, and the no-two-lane-jump rule on each generated layout, and the combat chunk-reuse test forces a ladder-only palette and asserts the toppled ladder is discarded and replaced by an upright, blocking one. `TopplingBarrier` no longer binds itself to the chunk signal, because generated chunks always create fresh upright ladders.

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
- **Branch**: `feature/animation-system` (merged into `main`, no longer active)
- **Status**: Steps 6.1, 6.2, 6.4 and 6.8 implemented and merged into `main`; Steps 6.3, 6.5-6.7 remain open
- **Objective**: Integrate comprehensive character, mesh, and environment animations across gameplay entities.
- [x] Step 6.1: Set up player `AnimationPlayer` and state transitions. `PlayerController` drives the archer's `AnimationPlayer` at `Model/ArcherModel/AnimationPlayer` through a state-driven mapping: `idle` in READY, `sprint` while running (playback speed scaled to forward speed), `jump`/`fall` in the air, `duck` (fallback `crouch`) while ducking, `trip` (fallback `hit`) on a ground stagger, and `die` on death. Clips crossfade over 0.15s and idle/sprint loop. Two custom clips were authored in Blender on the rig: `duck`, a deep crouch that halves the head height, and `trip`, a foot-catch that throws the runner into a hop over the obstacle before recovering. The arch head bump reads as a deeper 0.6 rad backward recoil. Visually approved by the user.
- [x] Step 6.2: Lateral lane-change tilt/roll/lean is covered by the existing procedural visual banking in `PlayerController._apply_lane_movement`.
- [x] Step 6.3: Combat action animations (bow draw, aim hold, arrow release recoil). Pulled into Phase 7 at the user's request and implemented there: `PlayerController` drives the archer's baked `holding-both` (aim) and `holding-both-shoot` (release) clips through a short draw/release window (`GameConfig.SHOOT_DRAW_TIME`, `SHOOT_RELEASE_TIME`), with `holding-right` / `holding-right-shoot` fallbacks. The bow mesh attachment was intentionally deferred pending the Step 7.7 visual pass.
- [x] Step 6.4: Implement environmental and foliage animations (wind sway). Added `shaders/foliage_wind.gdshader`, a shared world-space wind field that bends the upper part of each plant toward one common direction with a world-position phase offset, plus `scripts/world/wind_foliage.gd` (`WindFoliage`), which reuses each mesh's original albedo texture and measured height before applying the material. Wrapped onto the tree and tall-tree obstacles and the arch flag. User review asked for stronger amplitude and smoother randomized motion; that pass raised the sway ratio to 0.18 and layered incommensurate sines with per-plant phase/speed jitter, a slow gust envelope, and gentle direction wander. The user re-verified the result.
- [ ] Step 6.5: Implement interactive object animations (obstacle impact wobble/shatter, collectible spin and hover bobbing).
- [ ] Step 6.6: Automated unit tests verifying animation state machines, blend parameters, and signal triggers.
- [ ] Step 6.7: Animation fluidity, blending, and visual inspection (User Manual Test).
- [x] Step 6.8: Player damage & death feedback animation. `DamageOverlay` (`scripts/ui/damage_overlay.gd` + `scenes/ui/damage_overlay.tscn`) pulses a full-screen red tint across the damage window and, on death, leaves the pulse and runs a one-shot fade that deepens the impact red all the way to solid black over `death_fade_time` (1.2s); it resets on `game_restarted`. The gameplay rule behind it lives in Step 5.7. Visual result confirmed.

---

### [ ] Phase 7: Combat & Ability System (Arrows, Quiver & Arrow Types)
- **Branch**: `feature/combat-abilities` (merged into `main` at `fc74152`); Step 7.7 manual pass still open
- **Objective**: Deliver active archery combat — a quiver of collectible arrows, a pooled straight-line projectile, automatic arrow-type selection, shootable hazards, and the bow draw/aim/release animation.
- **Design decisions (confirmed with the user)**: ammo is a **quiver** of collected arrows (the distance-charged ability gauge was dropped); two arrow types (`normal`, `flame`) chosen **automatically** at fire time; the flame arrow is **procedural** (`weapon-arrow.glb` + emissive head + `GPUParticles3D`, no Blender); arrow pickups live in Phase 7; arrows fly in a **straight line** (no gravity); Step 6.3 was pulled into this phase.
- [x] Step 7.1: Arrow projectile scene (`scenes/combat/arrow.tscn` + `scripts/combat/arrow.gd`). A straight-line `Arrow` (`Node3D`) advances each physics frame and resolves hits with a ray query (mask `LAYER_OBSTACLE | LAYER_TARGET`) instead of a moving `Area3D`, so a 40 m/s projectile cannot tunnel. `activate()`/`deactivate()` make it `ObjectPool`-compatible; the flame variant toggles a shared emissive head and fire emitter built by `scripts/combat/flame_visual.gd` (`FlameVisual`).
- [x] Step 7.2: Projectile pool. `scripts/combat/arrow_pool.gd` (`ArrowPool`) wraps the Phase 4 `ObjectPool` (prewarm 8, max 32) and, listening to `EventBus.arrow_fired`, spawns an arrow per shot and recycles it on `finished`. Attached to `world.tscn` as an `ArrowPool` node (a sibling of `TrackSpawner`, never under it because chunks recycle).
- [x] Step 7.3: Quiver/ammo system replacing the ability gauge. `scripts/managers/ability_manager.gd` (`AbilityManager` autoload) tracks per-type counts (`START_AMMO_NORMAL` 3, `START_AMMO_FLAME` 1), tops up on `EventBus.collectible_picked("arrow_*")`, resets on `game_restarted`, and broadcasts `arrow_ammo_updated` / `arrow_type_changed`. `GameConfig` lost the gauge constants and gained arrow-type ids, start ammo, scan range, muzzle height, shoot timings, and pickup motion constants; `EventBus` dropped the gauge signals and extended `arrow_fired` with an `arrow_type` argument.
- [x] Step 7.4: Shoot input and automatic type selection. `PlayerController` reads the `shoot` action (F / left mouse), ray-scans the lane ahead, and asks `AbilityManager.try_fire(origin, direction, preferred)` for the best type (a burnable tree selects flame, anything else normal; no usable ammo blocks the shot and the animation). A successful shot starts the Step 6.3 draw/release animation.
- [x] Step 7.5: Arrow hit-detection. Any node exposing `receive_arrow(type)` / `required_arrow_types()` is shootable. `Destructible` gained `destroyed_by` (archery target and ladder barrier: `["normal"]`), and the new `scripts/obstacles/burnable_tree.gd` (`BurnableTree extends Obstacle`, `destroyed_by = ["flame"]`) makes `obstacle_tree` / `obstacle_tree_tall` burnable while staying lethal and on `LAYER_OBSTACLE`. `GameManager` now banks `target_destroyed` rewards into the score.
- [x] Step 7.6: Automated tests. `tests/unit/test_combat.gd` + `.tscn` (mirroring the obstacle suite: quiver spend/collect/block, arrow flight and expiry, pool spawn/recycle, typed hit resolution with a tree-lethality regression guard, pickup collection, and smart type selection) — 6/6 passing; added to the README run list.
- [x] Step 7.6b: Collectible arrow pickups. `scripts/combat/arrow_pickup.gd` (`ArrowPickup`) plus `scenes/combat/arrow_pickup_normal.tscn` and `arrow_pickup_flame.tscn` (flame glows and emits fire). Pickups sit on `LAYER_PICKUP`, bob/spin, grant ammo on player contact, and reset when their chunk re-activates (`track_chunk_base.tscn` gained a `Pickups` node; `TrackChunk.activate()` restores its pickup descendants) so ammo stays renewable on the looping track. Authored into the straight, rocky, and forest chunks (one resting on the rocky stones).
- [x] Step 7.6c: Held bow, animated quiver HUD, normalized prop sizes, and pickup effect. `PlayerController` attaches `weapon-bow.glb` to the archer's arm bone through a `BoneAttachment3D` so the bow is carried at all times and swings with the arm, and a shot now releases at the end of the draw window (`holding-both` then `holding-both-shoot`). Arrows and the bow are normalized to a consistent size with the new `scripts/common/mesh_fit.gd` (`MeshFit`). A new top-right `scenes/ui/arrow_counter_hud.tscn` (`ArrowCounterHUD` + `scenes/ui/arrow_counter_entry.tscn` / `ArrowCounterEntry`) draws each held arrow type with its count: rows slide in from above on gain, exit upward/downward when emptied, pulse green on gain and red on spend, and hide entirely at zero. `ArrowPickup` now lifts the collected arrow into the player's quiver and shrinks it away. See the Open Notes for the still-unresolved visual issues.
- [x] Step 7.6d: Dedicated hand bones for precise bow placement. The archer rig previously exposed a single rigid bone per arm (`arm-left`/`arm-right`), so the bow could only be attached to the whole arm through a hand-tuned offset that read wrong in motion and left the hand position approximate. A `hand-left`/`hand-right` bone was authored in Blender for each arm (children of the arm bones, spanning the wrist centre to the hand tip) and the outer hand vertices were re-weighted to them, then the model was exported back into `character-archer.glb` (7 bones -> 9 bones; all 35 animation clips preserved, since the existing clips keep driving the arm bones and the new hand bones simply follow). `PlayerController` now attaches the bow to `hand-left` through a `BoneAttachment3D` named `HandAnchor`, which exposes the hand's exact position and orientation in Godot. The bow is now held precisely in the hand. Its hold rotation and size were tuned on user visual review to `bow_rotation_degrees` (`Vector3(-90.0, 0.0, 0.0)`) and `bow_scale` (`0.7`), which the user confirmed reads correctly.
- [x] Step 7.6e: Ladder topple physics and embedded arrows. Both normal and flame arrows now knock the ladder down (`destroyed_by = ["normal", "flame"]`); flame arrows only topple it for now, and the burning pass is deferred (see Deferred / Future Work). `barrier_fragile.tscn` now runs `scripts/obstacles/toppling_barrier.gd` (`TopplingBarrier extends Destructible`) instead of hiding on destruction. The barrier's model origin sits at the ladder's bottom centre (verified against the GLB/OBJ bounds: 0.5 x 1.0 x 0.14, base at y=0), so the node basis rotates around that base pivot and the whole ladder tips as one rigid body toward the runner's travel direction (-Z). The fall follows a rod pivoting at its base (`angular_accel = 3.5 * GameConfig.GRAVITY / fall_height * sin(angle)`), so it leans from a 3-degree start tilt and accelerates until it lies flat at 90 degrees; the simulation stops once flat. The raised gravity factor keeps the whole fall under half a second so the barrier reads as being knocked down instead of slowly sagging. The former instant collision clear on destroy was replaced by the `Destructible._apply_destroyed_state()` hook: the ladder keeps its `LAYER_TARGET` collision while it is still steep, and only clears it once the lean passes `COLLISION_CLEAR_ANGLE` (60 degrees from upright, i.e. 30 degrees above the ground), so a runner arriving during the topple still hits the falling ladder and dies on it. `Destructible` gained the `_apply_destroyed_state()` / `_reset_visual_state()` hooks so subclasses can replace the default hide-on-destroy presentation without duplicating the scoring path (`restore()` returns the ladder upright, re-enables collision and frees embedded arrows). The arrow now embeds at the exact ray hit point: `Arrow.embed_at()` aligns the arrow tip with the impact position, stops flight, extinguishes the flame, emits the new `stuck` signal and the barrier reparents it (keeping the global transform) so it rides the topple in place. `ArrowPool` drops embedded arrows from pool management via the new `ObjectPool.forget()`, leaving the struck barrier as their owner. The combat suite gained a ladder topple/stuck-arrow case and now passes 8/8; the obstacle (9/9) and world (5/5) suites also stayed green. Pooled chunks initially presented the ladder still toppled when they came back around, because destructibles only reset on `game_restarted`. `TrackChunk` now emits an `activated` signal after `activate()` restores pickups; Step 4.7 later made every chunk rebuild its hazards from scratch on that signal, so a recycled chunk always presents a fresh, upright, blocking ladder with no stuck arrows. (The earlier per-barrier `activated` binding was removed once generation took over.) Other destructibles intentionally keep their existing run-long destroyed state.
- [x] Step 7.6f: Archery target arrow sticking. `target_archery.tscn` now runs `scripts/obstacles/archery_target.gd` (`ArcheryTarget extends Destructible`): `receive_arrow()` accepts both arrow types and reports a hit without ever destroying the target, so the projectile embeds and the board stays in place. The impact point is rolled on the board face from the shot distance (`Arrow.travel_distance_to()`, measured from the launch point): very close shots (<= `NEAR_DISTANCE`, 4 m) land the exact bullseye, and spread grows linearly to `MAX_SPREAD` (1.4 board radii of Gaussian scatter) at `FAR_DISTANCE` (35 m), so long shots mostly land the middle/outer rings while closing the distance pushes hits inward. The board model is a ring of `BOARD_RADIUS` 0.5 m centred at `BOARD_CENTER` (0, 0.64, 0); any number of arrows can embed, each at a random angle and radius on the face. Arrows that land within `STACK_RADIUS` of an embedded one trigger the stacking rule: both arrows rotate around their tips by `STACK_TILT_DEGREES` in opposite directions along the line between their impact points, so two arrows on the same spot visibly push each other apart instead of intersecting. Stuck arrows are reparented to the target (riding any future target motion) and freed when the target restores. `Arrow` gained `travel_distance_to()` by remembering its launch origin. The combat suite gained an archery sticking case covering real flight embedding, the guaranteed near bullseye, the far outer-ring bias, multi-arrow retention and the stacking tilt, and now passes 9/9; the obstacle suite stays 9/9.
- [ ] Step 7.7: Arrow shooting responsiveness, flame/impact feel, and animation inspection (User Manual Test).

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

## Deferred / Future Work

- **Flame arrow destruction pass (not current scope)**: flame arrows must both knock the ladder down AND burn it away, leaving it destroyed rather than merely toppled. Flame arrows must also burn trees to ash (the current `BurnableTree` hides the tree immediately; the eventual pass should replace that with a burning/ash effect). Both behaviours are intentionally deferred; for now a flame arrow topples the ladder exactly like a normal arrow.

## Known Issues & Notes

### Resolved During Phase 5
- **Stale camera FOV assertion**: `tests/unit/test_camera_runner.gd` still expected the pre-Phase 4 default camera FOV of `68.0`, while `scenes/camera/runner_camera.tscn` was calibrated to `64.0` during the Phase 4 framing pass. The camera suite therefore reported `FAIL: Default camera FOV should be 68.0, got: 64.0` and exited with code `1`. The assertion was updated to compare the instantiated camera against its own configured `base_fov`, so future framing calibration can no longer break it.
- **Jolt rejects non-uniform shape scaling**: the previous `duck()` implementation scaled the player capsule to `(1.0, 0.45, 1.0)`. Jolt Physics silently substituted a uniform `0.816667` scale and logged `Failed to correctly scale shape ... is not supported by Jolt Physics for this shape/body`, which shrank the capsule on every axis instead of flattening it. Ducking now swaps between two pre-built `CapsuleShape3D` resources, so the duck silhouette is exact and the engine warning is gone.
- **Log collider one lane off the visible trunk**: `obstacle_log`'s instanced mesh was translated `+0.842` on X, so the visible fallen trunk sat in the right lane while its `CollisionShape3D` stayed centred in the middle lane. Runners visibly passed through the trunk in the right lane and died on an invisible collider in the centre lane, which read as inconsistent "sometimes it kills, sometimes it does not". The mesh offset was flipped to `-0.842` and a `Hazard Visual & Collider Alignment` suite now guards the mesh/collider centre alignment for every hazard.
- **Global class registration lag**: the newly added `scripts/obstacles/destructible.gd` failed to parse with `Could not find base class "Obstacle"` until a filesystem rescan re-registered the new `class_name`. A rescan is required after adding a script that extends a brand new global class.

### Open Notes
- Phase 7 is merged into `main` (`fc74152`). Steps 7.1-7.6 (plus the 7.6b pickups, 7.6c bow/HUD/size/effect pass, the 7.6d hand-bone bow attachment and the 7.6e ladder topple pass) are implemented and all six automated suites are green; Step 7.7 (manual shooting/flame/animation feel pass) is still pending a user test.
- Ladder topple notes: the topple runs in `_physics_process` on the barrier itself (a `StaticBody3D`), so it keeps working while the chunk moves. A knocked-down ladder still emits its normal `target_destroyed` reward, but it no longer opens the lane immediately: it stays on `LAYER_TARGET` until it has fallen to 30 degrees above the ground, so a runner who reaches it during the topple still collides and dies; the collision clears at that angle and the lane opens for the rest of the fall. Embedded arrows are owned by the ladder and are freed when the barrier restores; they are removed from the `ArrowPool` active list on embedding, so a stick does not permanently occupy a pool slot beyond its lifetime under the ladder. The ladder is regenerated with the rest of the chunk layout on re-activation (Step 4.7), so chunk reuse never presents a toppled one.
- Archery targets no longer emit `target_destroyed` on an arrow hit (they are not destroyed any more), so shooting them currently grants no score. Scoring for embedded arrows is deferred to Phase 8's score pass.
- The new global class `ArcheryTarget` may need a filesystem rescan before the editor resolves it (same "global class registration lag" note as earlier phases).
- The ability gauge was replaced by the collectible-arrow quiver per the user's decision: `GameConfig.MAX_ABILITY_GAUGE`, `ABILITY_CHARGE_PER_METER`, `ABILITY_CHARGE_PER_COIN`, and the `ability_gauge_updated` / `ability_ready` signals were removed, and `arrow_fired` now carries an `arrow_type`.
- Arrow pickups reset each time their chunk re-activates so ammo stays renewable through the looping track; destructible targets still only restore on `game_restarted` (unchanged existing behaviour).
- Arrow and flame visual pass (Step 7.7 preparation): the Kenney `weapon-arrow` mesh is authored along Z with the pointed head on +Z and the shaft toward -Z, so the old rotations tilted the projectile and planted it head-up. `Arrow` now applies a half-turn so the head leads the flight and flies exactly parallel to the ground. `ArrowPickup` shifts the geometry so the pointed tip sits exactly on the pivot, then randomises the lean around X (`PICKUP_TILT_DEGREES` +/- `PICKUP_TILT_RANGE_DEGREES`) with a small Y jitter (`PICKUP_YAW_RANGE_DEGREES`) so every planted arrow keeps a distinct pose while staying above ground, and buries the tip by `PICKUP_BURY_DEPTH` (0.06) into the surface, with the previous bob/spin motion removed so the arrows stay planted and the tip stays fixed while the angle is tuned. `MeshFit.fit_longest_axis` gained an optional cross-section scale (and now handles the GLB root `Node3D` correctly), and both arrows use `GameConfig.ARROW_CROSS_SECTION_SCALE` (0.4) to read thin and long. `FlameVisual` was rebuilt as an additive, billboarded particle flame with a procedural radial gradient texture, rising/shrinking fast-burning particles (0.32s lifetime, 28 particles, angular flicker), a hot color ramp, and a small emissive ember; flight arrows keep the flame anchored to the tip (`local_coords` on, so it no longer trails behind the moving arrow) while planted pickups burn at the buried tip, with the fire rising from the ground around the entry point. Pickups now roll `GameConfig.PICKUP_SPAWN_CHANCE` (0.35) each time their chunk re-activates (`ArrowPickup.respawn()`), so arrows appear sparsely instead of in every chunk, and the rocky-chunk pickup that rests on the stones is seated at the rock collider top (`y = 0.82`) instead of floating above it. The combat suite gained arrow-orientation, planted-pickup, and tip-pivot assertions and remains 6/6; all other suites are green.
- The bow attachment from Step 7.6d remains unchanged: it sits precisely in the archer's hand and its hold rotation/size were tuned on user visual review to `PlayerController.bow_rotation_degrees` (`Vector3(-90.0, 0.0, 0.0)`) and `bow_scale` (`0.7`); `bow_offset` remains `Vector3(0.006, 0.012, 0.006)`.
- Bow pivot corrected for the Step 7.7 pass: the `weapon-bow` mesh in `assets/models/weapon-bow.glb` was translated so the model origin now sits on the white grip (mesh-space grip centroid `(-0.03844, 0.24722, 0.14939)`) instead of the lower limb tip. The `weapon-bow` MeshInstance3D now carries a translation of `(0.03844, -0.24722, -0.14939)`, so positioning and rotating the bow pivots around the grip. The hand attachment rotation was retuned against this new pivot to `Vector3(-90.0, 0.0, 0.0)` on user visual review, with the offset `Vector3(0.006, 0.012, 0.006)` kept.
- Adding the new global classes `Arrow`, `ArrowPool`, `ArrowPickup`, `BurnableTree`, `FlameVisual`, `MeshFit`, `ArrowCounterHUD`, and `ArrowCounterEntry` may require a filesystem rescan before the editor resolves them (same "global class registration lag" note as earlier phases).
- The arrow counter HUD pre-empts part of Phase 9's UI work: it is the first consumer of `arrow_ammo_updated`. Score and distance still have no on-screen HUD.
- `feature/animation-system` was merged into `main` with Phase 6 partially complete (Steps 6.1, 6.2 and 6.4). The same merge carried Step 5.7 (the hazard damage window and its death fade-to-black overlay) into `main`; the remaining animation steps (6.3, 6.5-6.7) continue on a follow-up branch.
- The old per-run stumble allowance (`GameConfig.MAX_STUMBLES_PER_RUN` and `PlayerController.stumbles_remaining`) was removed in Step 5.7; the damage window now governs fatal follow-up contacts.
- `tests/unit/test_core_architecture.tscn` was re-run after the graded hit rule change and is green (GameConfig, EventBus, GameManager suites all pass). The obstacle suite reports 9/9, and the player and world generation suites are also green.
- Step 5.6 completed: the user performed the human visual pass and confirmed obstacle silhouettes, collider fairness, and duck-barrier clearance, so Phase 5 is now closed.
- Custom animation model swap: the authored `duck` and `trip` clips are now merged into `assets/models/character-archer.glb` (35 clips) and the temporary review copy was removed; `player.tscn` points back at the original model path.
