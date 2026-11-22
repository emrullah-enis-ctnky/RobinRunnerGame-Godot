# Active Context: RobinRunner

## Current Work Focus
Phase 8 (Pickups, Collectibles & Scoring) is complete on `feature/collectibles-scoring` (Steps 8.1–8.6 verified by user). Awaiting explicit user approval to merge `feature/collectibles-scoring` into `main`.

## Recent Changes
- Created custom stylized golden star coin model `assets/models/coin-star.glb` in Blender (`1680` verts, `1644` polys, double-sided plump 5-point star, beveled rim with stylized nicks).
- Added `GameConfig` collectible & scoring constants (`COIN_MODEL_DIAMETER = 0.42`, `COIN_HOVER_HEIGHT = 0.75`, spin/bob/combo parameters) and `EventBus.coins_updated` / `combo_updated` signals.
- Implemented `ScoreManager` (`scripts/managers/score_manager.gd`, registered as autoload) tracking distance score, coin counts, and combo multipliers (up to `2.5x`, reset on hazard damage or restart).
- Implemented `CoinPickup` (`scripts/collectibles/coin_pickup.gd` + `scenes/collectibles/coin.tscn`) with `MeshFit` normalization (`0.42 m`), idle spin/bobbing, pop-and-vanish tween, and golden `PickupBurst` sparks.
- Added `ChunkCollectibleSpawner` (`scripts/world/chunk_collectible_spawner.gd`) on `track_chunk_base.tscn` to spawn coin lines on clear lanes and 3-coin jump arcs over low obstacles.
- Enabled ring-based scoring (`100` bullseye / `60` / `40` / `20`) on `ArcheryTarget` when arrows embed.
- Added a minimal top-left `CoinCounterHUD` (`scenes/ui/coin_counter_hud.tscn` + `scripts/ui/coin_counter_hud.gd`) in `world.tscn` bound to `EventBus.coins_updated`.
- Added `tests/unit/test_collectibles_scoring.gd` + `.tscn` (5 suites).

## Next Steps
1. On explicit user approval, merge `feature/collectibles-scoring` into `main`.
2. Proceed to Phase 9 (UI & HUD) or finish Phase 6 leftovers (Steps 6.5–6.7).
