# Tech Context: RobinRunner

## Core Technologies
- **Game Engine**: Godot Engine 4.x
- **Renderer**: GL Compatibility (`gl_compatibility`)
  - Ensures robust compatibility with WebGL (HTML5 exports) and lower-end GPUs without Vulkan overhead.
- **Physics Engine**: 3D Physics (Godot Physics / Jolt 3D)
- **Primary Language**: GDScript (Strictly Typed)
- **Asset Formats**: Strictly GLB (glTF 2.0 Binary) for all 3D models (FBX and OBJ are prohibited), PNG for textures, OGG/WAV for audio.

## Development Environment & Setup
- **Operating System**: Linux
- **Workspace Path**: `/home/enis27/YAZILIM/RobinRunnerGame-Godot`
- **CLI Proxy**: `rtk` (Rust Token Killer) used for token-optimized terminal operations.
- **VCS**: Git (Main branch with feature branch isolation per development phase).

## Integrated Tooling & MCP Servers
- **godot-mcp-toolkit**:
  - Exclusively utilized for all Godot engine operations (node trees, scene creation, property modification, script inspection, runtime checks). Direct shell execution or opening Godot as a local desktop app by the agent is prohibited.
- **blender MCP**:
  - Exclusively utilized for Blender operations only when assets are insufficient and strictly upon explicit user approval. Direct local application launch is prohibited.
- **Web Search**:
  - Leveraged proactively to look up official Godot 4.x and Blender documentation for syntax, API signatures, and version nuances.

## Technical Constraints
1. **Performance Budget**: Target constant 60 FPS on desktop and web targets. Minimize dynamic allocations during active gameplay via object pooling.
2. **Asset Constraints**: Kenney Mini-Forest GLB models are hosted in and referenced exclusively from `res://assets/models/`. Scenes and scripts must never reference `addons/` for 3D assets. Preserve modular grid alignment for seamless track chunk stitching.
3. **Collision Matrix**: Layers are stored as true bitmasks in `GameConfig` (`LAYER_* = 1 << (layer - 1)`) and assigned directly to `collision_layer` / `collision_mask`:
   - Layer 1 (`1`): Player Body
   - Layer 2 (`2`): Environment / Ground
   - Layer 3 (`4`): Obstacles (Indestructible)
   - Layer 4 (`8`): Destructibles / Targets
   - Layer 5 (`16`): Projectiles (Arrows)
   - Layer 6 (`32`): Pickups / Collectibles
   - The player body collides with the environment layer only, so hazards can never trap the runner. Hazard contact is resolved by the `HazardDetector` `Area3D` on the player, whose mask is `LAYER_OBSTACLE | LAYER_TARGET`.
4. **Jolt Shape Scaling Limit**: Jolt Physics supports uniform collision shape scaling only. A non-uniform `CollisionShape3D.scale` is silently replaced by roughly the average scale on every axis, so stance or size changes must swap `Shape3D` resources instead of scaling the node.
5. **Platform Compatibility**: Avoid engine features incompatible with WebGL/Compatibility mode (e.g., complex compute shaders, SSR, volumetric fog). Keep visual effects performant using mesh particles and stylized unlit/vertex-lit materials where applicable.
