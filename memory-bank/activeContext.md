# Active Context: RobinRunner

## Current Work Focus
Phase 11 Step 11.3 (Performance Optimization & 60 FPS / WebGL2 Export Pass) is implemented on `feature/optimization-export` (branched from `main` at `318f6d4`). Awaiting user HTML5 re-export and FPS verification before merging into `main`.

## Recent Changes
- **`scripts/world/chunk_biome_decorator.gd`**: Built chunk biome scenery once per pooled chunk (`_built` guard) to eliminate main-thread GLB instantiation stutter on chunk recycle; disabled shadow casting on all flanking biome props (`_disable_shadows_recursive`); halved flanking prop density when `OS.has_feature("web")` is true.
- **`scripts/world/world_scenery.gd`**: Disabled shadow casting (`SHADOW_CASTING_SETTING_OFF`) on distant valley floor and mountain cone meshes.
- **`scenes/world/world.gd`**: On Web builds (`OS.has_feature("web")`), disabled `SunLight.shadow_enabled` and reduced `track_spawner.initial_chunk_count` from `6` to `4` to cut WebGL2 draw calls and shadow-pass overhead.
- **`shaders/stylized_sky.gdshader`**: Reduced `cloud_fbm` from 4 octaves to 2 octaves for lighter per-pixel WebGL2 cost.
- **`shaders/forest_trail.gdshader`**: Removed the 3rd pebble noise tap per pixel on the trail shader.

## Next Steps
1. User re-exports the HTML5 build in Godot and verifies 60 FPS smoothness via a local HTTP server (`python3 -m http.server 8000 --directory export/HTML`).
2. On user approval, merge `feature/optimization-export` into `main` and decide whether to commit or `.gitignore` `export_presets.cfg`.
