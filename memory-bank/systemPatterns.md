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
  - `StaggeredState`: Post-collision stumble window with reduced forward speed and temporary hazard immunity.
  - `DeadState`: Ragdoll or death animation, stopping input, triggering game over sequence.
- **Event Bus Pattern**: Centralized `EventBus` autoload for decoupled cross-system communication.
- **Object Pool Pattern**: `ObjectPool` utility managing reuse of Track Chunks, Projectiles, and Collectibles.
- **Observer Pattern**: UI widgets observe gameplay metrics (score, gauge, health) via signals.

## Hazard & Obstacle Patterns
- **Obstacle Contract**: Every hazard is a `StaticBody3D` scene in `scenes/obstacles/` driven by `scripts/obstacles/obstacle.gd`. It declares `collision_mask = 0`, joins the `obstacle` group, and exposes `get_hazard_type()` plus `is_lethal_hazard()` so the player can report a readable hazard label and resolve lethality without holding a hard reference to the scene.
- **Destructible Contract**: `scripts/obstacles/destructible.gd` extends the obstacle contract with `score_reward`, `destroy()` (clears the collision layer deferred, hides the mesh, emits `EventBus.target_destroyed`) and `restore()` (re-armed on `EventBus.game_restarted` so recycled chunks present live targets again).
- **Duck Barrier Variant**: The overhead arch keeps its decorative root and adds a `HazardBody` child on the obstacle layer inside the `overhead_barrier` group. Its collider covers only the hanging beam, so the lane stays passable by ducking.
- **Player-Side Hazard Detection**: Hazards never physically block the runner. The player body collides with the environment layer only, while a `HazardDetector` `Area3D` (`collision_mask = LAYER_OBSTACLE | LAYER_TARGET`) reports `body_entered` and forwards it to `PlayerController.take_hit()`. This centralises detection and stops a staggered player from being trapped inside geometry.
- **Stance Swapping**: Ducking swaps the detector between two pre-built `CapsuleShape3D` resources and re-centres it, because Jolt Physics only supports uniform shape scaling.
- **Graded Hit Rule**: `take_hit()` resolves lethality per hazard. Lethal hazards (`is_lethal`, e.g. trees and the ladder barrier) end the run on the first contact and bypass the stagger immunity window; forgiving hazards (`obstacle_log`, rocks, stones, fences) stagger on the first contact and only end the run once `MAX_STUMBLES_PER_RUN` is exhausted, which keeps dense hazard rows fair at high speed.
- **Visual-Collider Alignment Invariant**: every hazard's visual mesh must be centred on its `CollisionShape3D`. `tests/unit/test_obstacles.gd` asserts this so a shifted mesh can never let the runner pass through visible geometry while an invisible collider blocks the lane elsewhere.
- **Reaction Posture**: A non-fatal contact imprints a posture on the player model. Ground hazards tip the runner forward (`STUMBLE_TILT_FORWARD`), while an `overhead_barrier` hit recoils the head backward (`HEAD_BUMP_TILT_BACK`) so an arch reads as a head bump the runner passes beneath.
- **Fairness Invariant**: Every chunk must leave at least one clear lane per depth row of ground hazards. `tests/unit/test_obstacles.gd` asserts this invariant for all chunk variants.

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
