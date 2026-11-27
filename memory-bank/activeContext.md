# Active Context: RobinRunner

## Current Work Focus
Phase 11 Step 11.3 (Performance Optimization & 60 FPS / WebGL2 Export Pass) has been merged into `main`, and `export_presets.cfg` is now ignored in `.gitignore`.

## Recent Changes
- **`scripts/world/chunk_biome_decorator.gd`**: Built chunk biome scenery once per pooled chunk (`_built` guard) to eliminate main-thread GLB instantiation stutter on chunk recycle; disabled shadow casting on all flanking biome props; halved flanking prop density on Web builds (`OS.has_feature("web")`).
- **`scripts/world/world_scenery.gd`**: Disabled shadow casting (`SHADOW_CASTING_SETTING_OFF`) on distant valley floor and mountain cone meshes.
- **`scenes/world/world.gd`**: On Web builds (`OS.has_feature("web")`), disabled `SunLight.shadow_enabled` and reduced `track_spawner.initial_chunk_count` from `6` to `4`.
- **`shaders/stylized_sky.gdshader`** & **`shaders/forest_trail.gdshader`**: Reduced sky cloud FBM from 4 to 2 octaves and removed the 3rd trail pebble noise tap for smoother WebGL2 frame pacing.
- **`.gitignore`**: Added `export_presets.cfg` alongside `export.cfg` and `export_credentials.cfg`.

## Next Steps
1. Continue Phase 11 remaining items as requested (Desktop/Web export presets validation, Step 11.4 touch/swipe input abstraction for future Android export, Step 11.5 final release verification).
