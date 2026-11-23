# RobinRunner

[![Engine](https://img.shields.io/badge/Engine-Godot%204.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Renderer](https://img.shields.io/badge/Renderer-GL%20Compatibility-green)](https://docs.godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Web-orange)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**RobinRunner** is an action-packed, stylized 3D endless runner developed in **Godot Engine 4**. Sprint as a forest archer down a winding woodland trail through dense woods, rocky canyons, archer camps, and stream-bridge crossings under a dynamic 24-hour sky. Unlike passive runners where you only dodge, RobinRunner blends high-speed 3-lane platforming with active archery combat: gather normal and flame arrows into your quiver, fire on the sprint to burn trees, topple ladder barricades, and land bullseyes on archery targets while chaining star-coin combos for bonus score multipliers.

---

## Key Features

- **Responsive 3-Lane Movement**: Snappy lateral lane transitions (Left, Center, Right), responsive jump arcs, mid-air fast-fall, and ducking/sliding under overhead arches.
- **Active Archery Combat**: Collect normal and flame arrows into a quiver and fire straight-line shots on the run. Arrows embed into archery targets with distance-based ring accuracy (`100` bullseye down to `20` outer ring, with stacking tilt separation), knock ladder barricades over with a base-pivot topple, stick into tall structures, and burn down lethal trees when fired as flame arrows.
- **Layered Environmental Hazards & Graded Hit Rule**: Trees and ladder barriers are lethal on a single contact, while fallen logs and low hazards (rocks, stones, fences, and overhead arches) stagger the archer on the first hit, open a 5-second red-pulse damage window, and apply a temporary `-20%` score penalty. Surviving the window restores the archer to full; a second forgiving hit inside the window ends the run with a fade to black.
- **Star Coins, Combos & Live Scoring**: Custom low-poly spinning star coins spawn in clear-lane lines and jump arcs over low obstacles. Chaining consecutive coins builds a visible combo streak that boosts all score gains by `+10%` every 10 coins (`%10`, `%20`, ...), accompanied by floating `+score` popups for coins and archery hits.
- **Living Curved World & 24-Hour Day/Night Cycle**: Every run begins at a random hour of day under a custom stylized sky with drifting clouds, glowing sun and moon discs, twinkling night stars, dynamic directional lighting, and atmospheric horizon fog. Pooled track chunks feature a seamless woodland dirt trail shader, biome-matched flanking scenery (dense forest, rocky canyon, archer camp clearing, and shimmering stream-bridge crossings), high timber framing gateways, and a gentle curved-horizon shader.
- **Unified Forest-Explorer Notebook UI & Settings**: Cohesive wooden-backed parchment menus and in-game HUD counters, a 3-2-1 launch countdown, Pause overlay, slide-up Game Over summary, and instant-saving Settings featuring Music/SFX sliders & mute buttons, Display resolution/fullscreen options, multi-key rebindable Controls with Reset Defaults, and live **English / Türkçe / Deutsch** flag-based language switching.
- **Adaptive Audio & Spatial Feedback**: Dual-channel crossfaded menu and gameplay music with smooth pause ducking and brief death-dip recovery, plus an 8-voice pooled SFX engine covering ground-only speed-paced footsteps, jump/land, duck, bow release, distance-attenuated arrow sticking and tree burning, combo-pitched coin pickups, and UI clicks.
- **Lightweight & Cross-Platform**: Powered by Godot 4's **GL Compatibility** renderer with native `.glb` low-poly assets for instant load times and consistent frame rates across Desktop (Linux, Windows, macOS) and Web (HTML5/WebAssembly), with future Android support in mind.
- **Clean Architecture**: Decoupled, signal-driven architecture with dedicated autoload managers (`EventBus`, `GameManager`, `AbilityManager`, `ScoreManager`, `SettingsManager`, `AudioManager`) and comprehensive automated headless test suites.

---

## Default Controls

*(All controls support multiple simultaneous key/mouse bindings and can be customized or reset to defaults in **Settings → Controls**).*

| Action | Primary Key | Secondary Key |
| :--- | :--- | :--- |
| **Move Left** | `A` | `Left Arrow` |
| **Move Right** | `D` | `Right Arrow` |
| **Jump** | `Space` / `W` | `Up Arrow` |
| **Duck / Slide** | `S` | `Down Arrow` |
| **Shoot Arrow** | `F` | `Left Mouse Click` |
| **Pause / Resume** | `Escape` | `P` |

*(Touch and swipe controls will be introduced for mobile targets).*

---

## Getting Started

### Prerequisites

- [Godot Engine 4.x](https://godotengine.org/download) (Standard build, 4.7+ recommended)
- Git

### Running the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/emrullah-enis-ctnky/RobinRunnerGame-Godot.git
   cd RobinRunnerGame-Godot
   ```
2. Open Godot Engine, click **Import**, and select the `project.godot` file in the project root.
3. Run the project from within the editor or press `F5`.

---

## Tech Stack & Engine Configuration

- **Game Engine**: Godot Engine 4.7+
- **Rendering Method**: `gl_compatibility` (GL Compatibility mode for desktop, web, and mobile)
- **Physics Engine**: 3D Physics (Jolt Physics)
- **Programming Language**: GDScript (Strictly Typed)
- **3D Asset Format**: Exclusively **GLB** (glTF 2.0 Binary) located in `res://assets/models/`
- **Shaders**: Custom `gdshader` sky, woodland trail, wind foliage, curved world, and curved flame particle shaders
- **Testing**: Automated headless test suites running directly in the SceneTree

---

## System Architecture

RobinRunner is designed around modular, decoupled components to maintain clean code and avoid circular dependencies:

```
                      +-------------------+
                      |    GameManager    |
                      |   (State & Loop)  |
                      +-------------------+
                                |
                                v
+------------------+     +--------------+     +--------------------+
| PlayerController | <-> |   EventBus   | <-> |    TrackSpawner    |
|  (Input & Move)  |     | (Global Hub) |     |  (Object Pooling)  |
+------------------+     +--------------+     +--------------------+
                                |
          +---------------------+---------------------+
          v                     v                     v
+-------------------+ +-------------------+ +-------------------+
|   ScoreManager    | |     UIManager     | |   AudioManager    |
| (Score & Combos)  | |  (HUD & Menus)    | |  (Music & SFX)    |
+-------------------+ +-------------------+ +-------------------+
```

- **`EventBus`** (`scripts/managers/event_bus.gd`): Central signal dispatcher connecting player actions, combat events, scoring, audio, and UI without tight coupling.
- **`GameManager`** (`scripts/managers/game_manager.gd`): State machine controller managing `READY`, `PLAYING`, `PAUSED`, and `GAME_OVER` states, forward speed scaling, and high score calculation.
- **`AbilityManager`** (`scripts/managers/ability_manager.gd`): Quiver ammo tracker for normal and flame arrows with smart type selection.
- **`ScoreManager`** (`scripts/managers/score_manager.gd`): Distance scoring, 10-coin `+10%` combo multipliers, and `-20%` stumble penalty handling.
- **`SettingsManager`** (`scripts/managers/settings_manager.gd`): Persistent audio, display, EN/TR/DE localization, and multi-key `InputMap` configuration (`user://settings.cfg`).
- **`AudioManager`** (`scripts/managers/audio_manager.gd`): Dual-channel crossfaded music with pause ducking and 8-voice pooled SFX with distance attenuation.
- **`GameConfig`** (`scripts/common/game_config.gd`): Single source of truth for lane coordinates, physics constants, speed progression, and collision layers.

---

## Directory Structure

```
res://
├── assets/
│   ├── audio/              # Music tracks (music/) and sound effects (sfx/)
│   └── models/             # Pure GLB 3D models and textures (Kenney Mini-Forest + custom star coin)
├── memory-bank/            # Project memory bank, guidelines, and roadmap
│   ├── projectbrief.md     # Core project requirements and goals
│   ├── productContext.md   # Product vision and UX objectives
│   ├── systemPatterns.md   # Architectural patterns and component graphs
│   ├── techContext.md      # Engine details, collision matrix, and constraints
│   ├── activeContext.md    # Active phase focus and recent decisions
│   ├── progress.md         # 11-Phase Kanban roadmap and step trackers
│   └── projectRules.md     # Mandatory project guidelines and workflow rules
├── scenes/
│   ├── camera/             # Dynamic follow camera scene
│   ├── collectibles/       # Spinning star coin pickup scene
│   ├── combat/             # Projectiles (arrows) and arrow pickup scenes
│   ├── obstacles/          # Static, destructible, toppling, and burnable hazard scenes
│   ├── player/             # Player character scene
│   ├── ui/                 # In-game HUD, menus, settings, and damage overlay scenes
│   └── world/              # Track chunks, props, and main world scene
├── scripts/
│   ├── camera/             # Camera tracking, FOV, and shake controller
│   ├── collectibles/       # Coin pickup spin/bob/burst behavior
│   ├── combat/             # Arrow trajectory, pool, pickups, and flame visuals
│   ├── common/             # GameConfig constants, MeshFit, and ObjectPool utilities
│   ├── managers/           # EventBus, GameManager, AbilityManager, ScoreManager, SettingsManager, AudioManager
│   ├── obstacles/          # Obstacle, Destructible, BurnableTree, TopplingBarrier, ArcheryTarget
│   ├── player/             # Player movement, animations, footsteps, and input controller
│   ├── ui/                 # NotebookUITheme, NotebookCard, UIManager, SettingsPanels, HUDs
│   └── world/              # Chunk pooling, hazard/collectible/biome generators, sky & curved world
├── shaders/                # Stylized sky, forest trail, curved world, curved flame, and foliage wind
├── tests/
│   └── unit/               # Automated headless unit test suites
└── addons/                 # Editor plugins (Godot MCP Toolkit)
```

---

## Running Automated Tests

RobinRunner includes automated test suites that can be executed headlessly. Each suite prints its own pass/fail summary and exits with code `0` on success and `1` on failure:

```bash
godot --headless res://tests/unit/test_core_architecture.tscn
godot --headless res://tests/unit/test_player_controller.tscn
godot --headless res://tests/unit/test_camera_controller.tscn
godot --headless res://tests/unit/test_world_generation.tscn
godot --headless res://tests/unit/test_obstacles.tscn
godot --headless res://tests/unit/test_combat.tscn
godot --headless res://tests/unit/test_collectibles_scoring.tscn
godot --headless res://tests/unit/test_ui_hud.tscn
godot --headless res://tests/unit/test_world_atmosphere.tscn
godot --headless res://tests/unit/test_audio_manager.tscn
```

---

## Development Roadmap (Kanban)

The project is developed in phased, modular Kanban increments:

- [x] **Phase 0**: Project Initialization, Standards Setup & Memory Bank
- [x] **Phase 1**: Project Architecture & Core Infrastructure (`EventBus`, `GameConfig`, `GameManager`)
- [x] **Phase 2**: Player Controller & Movement Mechanics
- [x] **Phase 3**: Camera System & Viewport
- [x] **Phase 4**: World & Modular Track Generation
- [x] **Phase 5**: Obstacles & Environmental Hazards
- [ ] **Phase 6**: Animation System (Character & World Animations) *(Steps 6.1–6.4, 6.8 complete; 6.5–6.7 open)*
- [ ] **Phase 7**: Combat & Ability System (Arrows, Quiver & Arrow Types) *(Steps 7.1–7.6f implemented; Step 7.7 manual test pending)*
- [x] **Phase 8**: Pickups, Collectibles & Scoring
- [x] **Phase 9**: User Interface & HUD
- [ ] **Phase 10**: Audio & Visual Polish *(Steps 10.0–10.2 complete; 10.3–10.4 open)*
- [ ] **Phase 11**: Performance Optimization & Multi-Platform Export (Desktop, Web, Android)

Detailed breakdown and active progress tracking are maintained in [`memory-bank/progress.md`](memory-bank/progress.md).

---

## Credits & Asset Attribution

- **3D Assets**: [Kenney Mini-Forest Pack](https://kenney.nl/assets/mini-forest) by Kenney ([CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)), plus custom Blender-authored star coin (`coin-star.glb`)
- **Engine Tooling**: `godot-mcp-toolkit`

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## AI Agent & Developer Orientation (Token Economy Protocol)

> [!IMPORTANT]
> **Minimal Context Loading Protocol**:
> When an AI agent or contributor is instructed to read the project, read this README, or onboard:
> 1. Read **ONLY** this `README.md`, [`memory-bank/projectRules.md`](memory-bank/projectRules.md), and [`memory-bank/progress.md`](memory-bank/progress.md).
> 2. Do **NOT** read other Memory Bank files (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`) or project source files unless explicitly requested or strictly required for a task.
> 3. Read specific source code or scene files **only when strictly necessary** for active implementation.
> 4. Use lightweight terminal commands (e.g. `rtk ls`, `rtk find`) to explore the directory structure instead of reading file contents.
> 5. **Meticulous Logging**: Always document completed work and decisions thoroughly in `memory-bank/progress.md` and commit messages to prevent context loss and confusion.
