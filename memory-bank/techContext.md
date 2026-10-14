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
  - Used for inspecting node hierarchies, reading/writing scripts, modifying properties, checking scene trees, and runtime debugging.
- **blender MCP**:
  - Available for advanced 3D asset modifications or model repairs.
  - **Rule of Engagement**: **Must never be used without explicit, prior user approval.** Always check whether existing Kenney assets in `addons/` suffice before proposing Blender usage.
- **Web Search**:
  - Leveraged proactively to look up official Godot 4.x and Blender documentation for syntax, API signatures, and version nuances.

## Technical Constraints
1. **Performance Budget**: Target constant 60 FPS on desktop and web targets. Minimize dynamic allocations during active gameplay via object pooling.
2. **Asset Constraints**: Leverage pre-made Kenney Mini-Forest assets exclusively in GLB format (`addons/kenney_mini-forest_1.0/Models/GLB format/`). Preserve modular grid alignment for seamless track chunk stitching.
3. **Collision Matrix**: Strict collision layer assignment to avoid unnecessary broad-phase checks:
   - Layer 1: Player Body
   - Layer 2: Environment / Ground
   - Layer 3: Obstacles (Indestructible)
   - Layer 4: Destructibles / Targets
   - Layer 5: Projectiles (Arrows)
   - Layer 6: Pickups / Collectibles
4. **Platform Compatibility**: Avoid engine features incompatible with WebGL/Compatibility mode (e.g., complex compute shaders, SSR, volumetric fog). Keep visual effects performant using mesh particles and stylized unlit/vertex-lit materials where applicable.
