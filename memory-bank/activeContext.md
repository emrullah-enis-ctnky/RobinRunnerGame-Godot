# Active Context: RobinRunner

## Current Work Focus
Phase 7 (Combat & Ability System) is implemented on `feature/combat-abilities` (8 commits ahead of `main` after merging `main` at `b747e41`). Steps 7.1–7.6f and the Step 7.7 visual, pickup-burst, tip-precision, and arrow-sticking passes are complete (`test_combat.gd` covers 13 test cases). Step 7.7 (manual shooting feel, flame/impact, and animation inspection) is awaiting user verification before merging `feature/combat-abilities` into `main`.

Phase 6 (Animation System) is partially complete on `main` (Steps 6.1, 6.2, 6.3, 6.4, and 6.8 done; Steps 6.5–6.7 remain open). Phases 8–11 remain open.

## Recent Changes (Since `main`)
- Merged `main` (`b747e41`, including `feature/chunk-variation` / Step 4.7 randomized fair chunk hazard layouts) into `feature/combat-abilities`.
- **Step 7.6e (`TopplingBarrier`)**: Knocking down `barrier_fragile.tscn` with either normal or flame arrows tips the ladder around its base pivot toward `-Z`, keeps `LAYER_TARGET` collision active until it passes 60 degrees from upright, and embeds the striking arrow so it rides the topple. Recycled chunks rebuild fresh upright ladders via `ChunkHazardGenerator`.
- **Step 7.6f (`ArcheryTarget`)**: `target_archery.tscn` embeds both normal and flame arrows on the visible board face (`BOARD_FACE_Z = 0.41`) with distance-based ring accuracy and stacking tilt separation, without destroying the target.
- **Step 7.7 Preparation Passes**:
  - `ArrowPickup` spawns a one-shot `PickupBurst` spark effect on collection and extinguishes flame visuals when collected.
  - `Arrow` casts from its tip (`get_tip_position()`) with a `0.07 m` sphere sweep fallback to prevent mesh-leading pierce issues.
  - `Obstacle` generalizes arrow sticking for any tall structure (`STICK_MIN_TOP_HEIGHT = 1.2 m`, including trees and overhead arch beams) with distance-scaled Gaussian scatter, while short hazards consume arrows.
  - `tests/unit/test_combat.gd` expanded to 13 test cases covering tip-leading hits, long-range shots, tree/tall-structure sticking, ladder topple, and chunk reuse.

## Next Steps
1. Run user manual verification for Step 7.7 (shooting responsiveness, flame/impact feel, bow/arrow alignment, and animations).
2. On explicit user approval, merge `feature/combat-abilities` into `main`.
3. Decide whether to finish Phase 6 leftovers (Steps 6.5–6.7) or start Phase 8 (Pickups, Collectibles & Scoring).
