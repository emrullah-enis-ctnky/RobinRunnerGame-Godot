# Active Context: RobinRunner

## Current Work Focus
Phase 5 (Obstacles & Environmental Hazards) is implemented on `feature/obstacles`. Steps 5.1-5.5 are complete and the obstacle suite reports 9/9 passing. Step 5.6 (obstacle silhouette clarity and fairness inspection) is awaiting user visual verification on `scenes/world/world.tscn`.

## Recent Changes
- Converted the `GameConfig` collision constants into true bitmasks (`LAYER_OBSTACLE = 1 << 2`, `LAYER_TARGET = 1 << 3`, `LAYER_PROJECTILE = 1 << 4`, `LAYER_PICKUP = 1 << 5`). Layers 1 and 2 keep their previous numeric values, so existing scenes stay valid, and the player mask `14` now genuinely means layers 2, 3 and 4.
- Added hazard constants to `GameConfig`: `MAX_STUMBLES_PER_RUN` (1), `STUMBLE_DURATION` (0.6 s) and `STUMBLE_SPEED_FACTOR` (0.45).
- Created six static hazard scenes in `scenes/obstacles/`, each with an explicit `BoxShape3D` collider sized from the measured GLB bounding boxes: `obstacle_stones` and `obstacle_rocks` (low, jumpable), `obstacle_fence` (low, jumpable), `obstacle_log` (a `tree.glb` trunk rotated onto the X axis), `obstacle_tree` and `obstacle_tree_tall` (lane blockers that must be dodged).
- Created two destructions scenes in `scenes/obstacles/`: `target_archery` (`target.glb`, 100 points) and `barrier_fragile` (`ladder.glb`, 50 points), both driven by `scripts/obstacles/destructible.gd` and sitting on `LAYER_TARGET`.
- Added a `HazardBody` collider to the hanging beam of `scenes/world/props/overhead_arch.tscn`, turning the arch into a real duck barrier whose beam bottom sits at `Y = 1.09 m`.
- Reworked all three track chunks so lane decoration was replaced by hazard scenes with verified clearable routes: every depth row leaves at least one lane free, and the straight chunk (used for the safe launch zone) only places two isolated hazards.
- `scenes/player/player.tscn` now carries a `HazardDetector` `Area3D` (mask `12` = obstacle | target) and the body mask was narrowed to the environment layer (`2`) so hazards never physically trap the runner.
- Player stumble rule: the first hazard contact staggers the player for `STUMBLE_DURATION` at `STUMBLE_SPEED_FACTOR` speed and grants immunity; once the stagger expires the next contact ends the run.
- Graded hit rule: the `Obstacle` base class now exposes `is_lethal` / `is_lethal_hazard()`. `obstacle_tree`, `obstacle_tree_tall` and `barrier_fragile` are flagged lethal and end the run on the first contact; `obstacle_log`, `obstacle_rocks`, `obstacle_stones` and `obstacle_fence` stay forgiving (one stagger, then fatal). `PlayerController.take_hit(hazard_name, lethal)` kills immediately for lethal hazards, bypassing the stagger immunity window.
- Fixed a log lane-alignment bug: `obstacle_log`'s instanced mesh was translated `+0.842` on X, so the visible fallen trunk sat in the right lane while its `CollisionShape3D` stayed centred in the middle lane. Runners passed through the visible trunk and died on an invisible collider. The mesh offset was flipped to `-0.842` and a `Hazard Visual & Collider Alignment` suite now asserts every hazard's mesh centre matches its collider centre.
- Arch reaction posture: a non-fatal `overhead_barrier` contact recoils the model backward (`HEAD_BUMP_TILT_BACK`) instead of the forward ground stumble, so the arch reads as a head bump the runner passes beneath. Full character animation remains Phase 6.
- Extended `tests/unit/test_obstacles.gd` with four suites (hazard lethality profiles, hazard visual & collider alignment, lethal hit resolution and immunity bypass, arch head-bump feedback); the obstacle suite now reports 9/9.
- Ducking now swaps between two pre-built `CapsuleShape3D` resources instead of scaling the collision shape, because Jolt Physics rejects non-uniform shape scaling.
- Added `tests/unit/test_obstacles.gd` / `test_obstacles.tscn` with five suites covering hazard layers, destructible targets, the duck barrier, the player detector and chunk route passability. Updated the player hazard test for the stumble rule.

## Next Steps
1. Request user confirmation of obstacle silhouettes, collider fairness and duck-barrier clearance (Step 5.6).
2. On user approval ("birleştir"), merge `feature/obstacles` into `main` and branch `feature/animation-system` for Phase 6.
