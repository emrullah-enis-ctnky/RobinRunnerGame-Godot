# Active Context: RobinRunner

## Current Work Focus
Phase 1 (Core Architecture) has been completed, verified via automated tests, and committed on `feature/core-architecture`. Awaiting user order to merge into `main` and begin Phase 2 (`feature/player-controller`).

## Recent Changes
- Created and formalized `projectRules.md` documenting:
  - Game premise, engine configuration, and asset policies.
  - Strict English documentation/code standards and Turkish chat interaction.
  - Git branching workflow (branch per phase, commit per step/fix, merge only on user command).
  - Clean Code, folder organization, and concise function comment rules.
  - Autonomous testing workflow and manual visual inspection policy.
  - Web search usage for official documentation.
- Configured a comprehensive `.gitignore` for Godot 4.x, Android, Blender autosaves, and OS artifacts.
- Implemented Phase 1 (`feature/core-architecture`):
  - Organized project directory structure (`scenes/`, `scripts/`, `assets/`, `tests/`).
  - Created `EventBus.gd` global signal hub and registered in `project.godot` autoloads.
  - Created `GameConfig.gd` defining lane coordinates, speed variables, and collision masks.
  - Created `GameManager.gd` state machine (`READY`, `PLAYING`, `PAUSED`, `GAME_OVER`), speed acceleration, and scoring.
  - Implemented headless unit test suite (`tests/unit/test_runner.gd` & `test_core_architecture.tscn`) verifying all core architecture mechanics.

## Active Decisions & Architectural Considerations
1. **Kenney Asset Utilization**:
   - The Kenney Mini-Forest pack (`addons/kenney_mini-forest_1.0/Models/GLB format/`) contains ready-to-use archer models, weapons (bow, arrow), terrain patches (grass, dirt, platform, rocks), trees, fences, and target props in GLB format.
2. **Autoload Decoupling**:
   - Systems communicate strictly via `EventBus` signals and `GameConfig` static constants, ensuring zero circular dependencies.
3. **Branching Model**:
   - Dedicated branch per feature (`feature/<feature-name>`). Merged to `main` only on explicit user approval.
4. **Strict projectRules.md Adherence**:
   - Uncompromising compliance with all rules codified in `projectRules.md` is strictly enforced across all operations, commit scopes, tests, and language boundaries.

## Next Steps
1. Commit updated Memory Bank progress.
2. Await user command to merge `feature/core-architecture` into `main`.
3. Open `feature/player-controller` for Phase 2.

