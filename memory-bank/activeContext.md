# Active Context: RobinRunner

## Current Work Focus
Phase 10 Step 10.3 (Stylized Particle Systems) is implemented on `feature/visual-particles` (branched from `main`). Awaiting user visual inspection (Step 10.4) before merging into `main`.

## Recent Changes
- Created `shaders/curved_particle.gdshader` (curved alpha-blended billboard particle shader) and `scripts/vfx/vfx_spawner.gd` (`VFXSpawner`).
- Attached ground-only `RunDust` puff emitter and landing dust ring (`spawn_landing_dust`) to `PlayerController`.
- Wired dramatic rising flame + billowing charcoal ash/smoke burst (`spawn_tree_burn`) into `BurnableTree.destroy()`.
- Wired wood splinter spray (`spawn_wood_splinters`) into `ArcheryTarget.stick_arrow()` and `Destructible.destroy()`.
- Added `tests/unit/test_vfx_particles.gd` + `.tscn` (2 suites).

## Next Steps
1. User visual inspection of Step 10.4 (run dust, landing puff, tree burn fire/ash, wood splinters, and overall audio-visual feel).
2. On user approval, merge `feature/visual-particles` into `main` and proceed to Phase 11 (Optimization & Multi-Platform Export).
