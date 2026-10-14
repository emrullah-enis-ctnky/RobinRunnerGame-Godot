# System Patterns: RobinRunner

## System Architecture

RobinRunner follows a modular, decoupled node-based architecture in Godot 4. Communication between major systems relies on signal emissions and global event dispatchers, avoiding tight coupling or monolithic singletons.

```
+-------------------------------------------------------------------+
|                           GameManager                             |
|        (Game State, Game Over, Pause, Speed Progression)          |
+-------------------------------------------------------------------+
       |                                              |
       v                                              v
+------------------------+                 +------------------------+
|      EventBus          |                 |      ScoreManager      |
|  (Global Signal Hub)   |                 | (Distance, Collectibles|
+------------------------+                 +------------------------+
       |                  \                /          |
       |                   \              /           |
       v                    v            v            v
+--------------------+   +--------------------+   +--------------------+
|  PlayerController  |   | TrackChunkManager  |   |    UIManager       |
| (Movement, Physics,|   |  (Chunk Spawner,   |   |   (HUD, Menus,     |
| Abilities, Combat) |   |  Object Pooling)   |   |   Ability Meter)   |
+--------------------+   +--------------------+   +--------------------+
```

## Key Technical Decisions
1. **GL Compatibility Renderer**: Guarantees optimal performance across WebGL, integrated GPUs, and low-end mobile devices without shader compilation stutters.
2. **Object Pooling for World & Entities**: Track chunks, obstacles, projectiles, and collectibles are pre-instantiated and recycled through object pools rather than constantly created and freed at runtime.
3. **Signal-Driven Decoupling**: Components emit signals on key events (e.g., `player_hit_obstacle`, `ability_gauge_filled`, `score_increased`) captured by relevant listeners without direct script dependencies.
4. **Typed GDScript**: Strict static typing (`var speed: float = 10.0`) is enforced throughout the codebase for type safety, performance, and clear autocompletion.
5. **Separation of Logic & Presentation**: Visual nodes (meshes, particles, animations) are kept distinct from physics/collision bodies and game state controllers.

## Design Patterns in Use
- **State Machine Pattern**: Manages distinct player character states:
  - `RunningState`: Standard forward velocity with lane-switching capabilities.
  - `JumpingState`: Vertical velocity handling, gravity application, and air control.
  - `ShootingState`: Aiming/firing animation and arrow release while maintaining forward momentum.
  - `DeadState`: Ragdoll or death animation, stopping input, triggering game over sequence.
- **Event Bus Pattern**: Centralized `EventBus` autoload for decoupled cross-system communication.
- **Object Pool Pattern**: `ObjectPool` utility managing reuse of Track Chunks, Projectiles, and Collectibles.
- **Observer Pattern**: UI widgets observe gameplay metrics (score, gauge, health) via signals.

## Directory Structure Pattern
```
res://
├── assets/
│   ├── audio/              # SFX and music
│   ├── fonts/              # Typography and HUD fonts
│   └── models/             # Extracted/custom meshes, materials, and textures
├── scenes/
│   ├── player/             # Player scene and character rigs
│   ├── world/              # Track chunks, environments, and spawners
│   ├── obstacles/          # Static and destructible hazard scenes
│   ├── pickups/            # Coins, powerups, ability boosters
│   ├── combat/             # Projectiles (arrows) and target props
│   └── ui/                 # Menus, HUD, pause, game-over screens
├── scripts/
│   ├── player/             # Player movement, state machine, and input
│   ├── world/              # Track generation, chunk management, pooling
│   ├── obstacles/          # Obstacle behavior and destructible logic
│   ├── combat/             # Arrow projectile logic and targeting
│   ├── managers/           # GameManager, ScoreManager, EventBus
│   └── ui/                 # UI controllers and HUD binders
├── addons/                 # Vendor addons (Kenney assets, Godot MCP)
├── memory-bank/            # Project memory bank documentation
└── tests/                  # Automated verification and test scripts
```

## Critical Implementation Paths
1. **Lane Movement**: Discrete lane coordinates (e.g., Left: -2.0, Center: 0.0, Right: +2.0) with smooth lerping/tweens for transition polish.
2. **Infinite Track Scrolling**: Player moves along the Z-axis, with track chunks dynamically spawned ahead and culled behind.
3. **Collision Detection**: Layer-based collision matrices separating Player, Obstacles, Projectiles, and Collectibles to ensure clean detection.
