# RobinRunner

[![Engine](https://img.shields.io/badge/Engine-Godot%204.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Renderer](https://img.shields.io/badge/Renderer-GL%20Compatibility-green)](https://docs.godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Web-orange)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**RobinRunner** is an action-packed, stylized 3D endless runner game developed in **Godot Engine 4**. Players guide an archer through a procedurally generated, obstacle-filled forest. Unlike passive runners where the player only dodges, RobinRunner introduces an active combat element: charge your ability gauge through running and collecting energy, and unleash powerful arrow shots to destroy obstacles and strike archery targets on the sprint.

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

---

## Key Features

- **Responsive 3-Lane Movement**: Snappy and fluid lateral lane transitions (Left, Center, Right) and responsive jump arcs.
- **Layered Environmental Hazards**: Rock piles, fallen logs, fences and solid trees block the lanes, while hanging arches demand a duck or a lane switch. Every hazard carries an explicit collider sized from the asset's real bounding box.
- **Graded Hit Rule**: Trees and the ladder barriers are lethal and end the run on a single contact, while fallen logs and low hazards (rocks, stones and fences) stagger the archer on the first hit (reduced speed plus a short immunity window) and only end the run on the follow-up. Overhead arches read as a head bump as the runner passes beneath.
- **Combat & Ability Mechanics**: Charge an ability gauge during runs; fire arrows to destroy wooden targets and clear barricades in your path.
- **Infinite World Generation**: High-performance modular track chunk spawning with an object pooling system to ensure zero stutter.
- **Lightweight & Cross-Platform**: Powered by Godot 4's **GL Compatibility** renderer for instant load times, consistent frame rates, and seamless compatibility across Desktop (Linux, Windows, macOS) and Web (HTML5/WebAssembly), with future Android deployment in mind.
- **Modular Low-Poly Aesthetics**: Built using curated 3D assets in native GLB format from Kenney's Mini-Forest collection.
- **Clean Architecture**: Decoupled, signal-driven architecture with dedicated managers (`EventBus`, `GameManager`, `GameConfig`) and comprehensive automated test coverage.

---

## Tech Stack & Engine Configuration

- **Game Engine**: Godot Engine 4.7+
- **Rendering Method**: `gl_compatibility` (GL Compatibility mode for desktop, web, and mobile)
- **Physics Engine**: 3D Physics (Godot Physics / Jolt 3D)
- **Programming Language**: GDScript (Strictly Typed)
- **3D Asset Format**: Exclusively **GLB** (glTF 2.0 Binary) located in `res://assets/models/`
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
| PlayerController | <-> |   EventBus   | <-> | TrackChunkManager  |
|  (Input & Move)  |     | (Global Hub) |     |  (Object Pooling)  |
+------------------+     +--------------+     +--------------------+
                                |
                                v
                      +-------------------+
                      |     UIManager     |
                      |   (HUD & Menus)   |
                      +-------------------+
```

- **`EventBus`** (`scripts/managers/event_bus.gd`): Central signal dispatcher connecting player actions, combat events, scoring, and UI without tight coupling.
- **`GameManager`** (`scripts/managers/game_manager.gd`): State machine controller managing `READY`, `PLAYING`, `PAUSED`, and `GAME_OVER` states, forward speed scaling, and high score calculation.
- **`GameConfig`** (`scripts/common/game_config.gd`): Single source of truth for lane coordinates, physics constants, speed progression, and collision layers.

---

## Directory Structure

```
res://
├── assets/
│   ├── audio/              # Sound effects and music tracks
│   └── models/             # Pure GLB 3D models and textures (Kenney Mini-Forest)
├── memory-bank/            # Project memory bank, guidelines, and roadmap
│   ├── projectbrief.md     # Core project requirements and goals
│   ├── productContext.md   # Product vision and UX objectives
│   ├── systemPatterns.md   # Architectural patterns and component graphs
│   ├── techContext.md      # Engine details, collision matrix, and constraints
│   ├── activeContext.md    # Active phase focus and recent decisions
│   ├── progress.md         # 11-Phase Kanban roadmap and step trackers
│   └── projectRules.md     # Mandatory project guidelines and workflow rules
├── scenes/
│   ├── combat/             # Projectiles (arrows) and combat props
│   ├── obstacles/          # Static and destructible hazard scenes
│   ├── player/             # Player character scenes
│   ├── ui/                 # In-game HUD, menus, and game-over screens
│   └── world/              # Track chunks and environment spawners
├── scripts/
│   ├── combat/             # Arrow trajectory and combat handlers
│   ├── common/             # GameConfig constants and helper utilities
│   ├── managers/           # EventBus and GameManager autoloads
│   ├── obstacles/          # Obstacle behavior and destructible logic
│   ├── player/             # Player movement and input controllers
│   ├── ui/                 # UI binders and HUD controllers
│   └── world/              # Chunk pooling and spawner logic
├── tests/
│   └── unit/               # Automated headless unit test suites
└── addons/                 # Editor plugins (Godot MCP Toolkit)
```

---

## Default Controls

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

- [Godot Engine 4.x](https://godotengine.org/download) (Standard build, 4.3 or higher recommended)
- Git

### Running the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/emrullah-enis-ctnky/RobinRunnerGame-Godot.git
   cd RobinRunnerGame-Godot
   ```
2. Open Godot Engine, click **Import**, and select the `project.godot` file in the project root.
3. Run the project from within the editor or press `F5`.

### Running Automated Tests

RobinRunner includes automated test suites that can be executed headlessly. Each suite prints its own pass/fail summary and exits with code `0` on success and `1` on failure:

```bash
godot --headless res://tests/unit/test_core_architecture.tscn
godot --headless res://tests/unit/test_player_controller.tscn
godot --headless res://tests/unit/test_camera_controller.tscn
godot --headless res://tests/unit/test_world_generation.tscn
godot --headless res://tests/unit/test_obstacles.tscn
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
- [ ] **Phase 6**: Animation System (Character & World Animations)
- [ ] **Phase 7**: Combat & Ability System (Arrow Shooting)
- [ ] **Phase 8**: Pickups, Collectibles & Scoring
- [ ] **Phase 9**: User Interface & HUD
- [ ] **Phase 10**: Audio & Visual Polish
- [ ] **Phase 11**: Performance Optimization & Multi-Platform Export (Desktop, Web, Android)

Detailed breakdown and active progress tracking are maintained in [`memory-bank/progress.md`](memory-bank/progress.md).

---

## Credits & Asset Attribution

- **3D Assets**: [Kenney Mini-Forest Pack](https://kenney.nl/assets/mini-forest) by Kenney ([CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/))
- **Engine Tooling**: `godot-mcp-toolkit`

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
