# Active Context: RobinRunner

## Current Work Focus
Phase 2 (Player Controller & Movement Mechanics) has been completed and verified visually by the user. Awaiting user command to merge `feature/player-controller` into `main`.

## Recent Changes
- Created and formalized `projectRules.md` documenting:
  - Game premise, engine configuration, and asset policies.
  - Strict English documentation/code standards and Turkish chat interaction.
  - Git branching workflow (branch per phase, commit per step/fix, merge only on user command).
  - Clean Code, folder organization, and concise function comment rules.
  - Autonomous testing workflow and manual visual inspection policy.
  - Web search usage for official documentation.
- Configured a comprehensive `.gitignore` for Godot 4.x, Android, Blender autosaves, and OS artifacts.
- Implemented Phase 2 (`feature/player-controller`):
  - Added input mappings to `project.godot` (`move_left`, `move_right`, `jump`, `shoot`, `pause`).
  - Created `PlayerController` (`scripts/player/player_controller.gd`) supporting 3-lane switching, smooth lateral lerping, jump physics, visual lean, and hazard collision triggers.
  - Created `Player` scene (`scenes/player/player.tscn`) integrating Kenney archer GLB mesh and CapsuleShape3D.
  - Built and verified automated unit tests (`tests/unit/test_player_controller.tscn`).

## Active Decisions & Architectural Considerations
1. **Kenney Asset Utilization**:
   - The Kenney Mini-Forest pack (`assets/models/`) contains ready-to-use archer models, weapons (bow, arrow), terrain patches (grass, dirt, platform, rocks), trees, fences, and target props in GLB format.
2. **Autoload Decoupling**:
   - Systems communicate strictly via `EventBus` signals and `GameConfig` static constants, ensuring zero circular dependencies.
3. **Branching Model**:
   - Dedicated branch per feature (`feature/<feature-name>`). Merged to `main` only on explicit user approval.
4. **Strict projectRules.md Adherence**:
   - Uncompromising compliance with all rules codified in `projectRules.md` is strictly enforced across all operations, commit scopes, tests, and language boundaries.

## Next Steps
1. Await user command to merge `feature/player-controller` into `main`.
2. Open `feature/camera-system` for Phase 3 (dynamic runner follow camera).

