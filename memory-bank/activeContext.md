# Active Context: RobinRunner

## Current Work Focus
The project has completed its initial repository foundation (comprehensive `.gitignore`, `projectRules.md`, initial baseline commit). We are now completing the Memory Bank setup to establish a persistent architectural and roadmap baseline.

## Recent Changes
- Created and formalized `projectRules.md` documenting:
  - Game premise, engine configuration, and asset policies.
  - Strict English documentation/code standards and Turkish chat interaction.
  - Git branching workflow (branch per phase, commit per step/fix, merge only on user command).
  - Clean Code, folder organization, and concise function comment rules.
  - Autonomous testing workflow and manual visual inspection policy.
  - Web search usage for official documentation.
- Configured a comprehensive `.gitignore` for Godot 4.x, Android, Blender autosaves, and OS artifacts.
- Created baseline repository commit (`chore: initialize project configuration, rules, and base assets`).
- Built core Memory Bank documents: `projectbrief.md`, `productContext.md`, `systemPatterns.md`, and `techContext.md`.

## Active Decisions & Architectural Considerations
1. **Kenney Asset Utilization**:
   - The Kenney Mini-Forest pack (`addons/kenney_mini-forest_1.0/`) contains ready-to-use archer models, weapons (bow, arrow), terrain patches (grass, dirt, platform, rocks), trees, fences, and target props.
   - These assets provide complete baseline coverage for our runner without needing external asset creation.
2. **Phase 1 Strategy**:
   - Before building visual scenes, establish the directory structure, base manager scripts (`EventBus.gd`, `GameManager.gd`), and common constants to prevent architectural debt.
3. **Branching Model**:
   - Each phase will start by branching off `main` using concise naming without redundant "phase" prefixes (e.g., `git checkout -b feature/core-architecture`).
   - Work will proceed step-by-step with clean, granular commits.
4. **Strict projectRules.md Adherence**:
   - Uncompromising compliance with all rules codified in `projectRules.md` is strictly enforced across all operations, commit scopes, tests, and language boundaries.

## Next Steps
1. Commit updated branch conventions.
2. Await user command to initiate Phase 1 (`feature/core-architecture`).

