# Active Context: RobinRunner

## Current Work Focus
Phase 3 (Camera System & Viewport) implementation and visual verification are complete on `feature/camera-system`. All automated unit tests pass. Awaiting user merge command to merge into `main` and advance to Phase 4.

## Recent Changes
- Created and formalized `projectRules.md` documenting:
  - Game premise, engine configuration, and asset policies.
  - Strict English documentation/code standards and Turkish chat interaction.
  - Git branching workflow (branch per phase, commit per step/fix, merge only on user command).
  - Clean Code, folder organization, and concise function comment rules.
  - Autonomous testing workflow and manual visual inspection policy.
  - Web search usage for official documentation.
- Configured a comprehensive `.gitignore` for Godot 4.x, Android, Blender autosaves, and OS artifacts.
- Implemented Phase 3 (`feature/camera-system`):
  - Created `RunnerCamera` (`scripts/camera/camera_controller.gd`) supporting target tracking with decoupled axis damping, dynamic FOV scaling with player speed, and trauma-based screen shake.
  - Created `RunnerCamera` scene (`scenes/camera/runner_camera.tscn`) configured with 3rd-person runner angle.
  - Built and verified automated unit tests (`tests/unit/test_camera_controller.tscn`).
  - Tested and visually verified camera tracking, parallax, and follow dynamics with user. Removed temporary stage cleanly.

## Active Decisions & Architectural Considerations
1. **Camera Damping**:
   - Forward Z-axis tracks directly with offset to maintain tight framing during high-speed runs.
   - Lateral X-axis and vertical Y-axis smoothly damp transitions and jumps.
2. **Screen Shake Model**:
   - Uses quadratic trauma falloff with pseudo-random multi-frequency sine oscillation, automatically listening to `EventBus.player_hit_hazard`.
3. **Branching Model**:
   - Dedicated branch per feature (`feature/<feature-name>`). Merged to `main` only on explicit user approval.
4. **Strict projectRules.md Adherence**:
   - Uncompromising compliance with all rules codified in `projectRules.md` is strictly enforced across all operations, commit scopes, tests, and language boundaries.

## Next Steps
1. Merge `feature/camera-system` into `main` upon user command.
2. Create feature branch `feature/world-generation` for Phase 4.
3. Implement modular track chunks, object pooling, and dynamic track spawner.

