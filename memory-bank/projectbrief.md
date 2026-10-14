# Project Brief: RobinRunner

## Executive Summary
RobinRunner is a fast-paced, stylized 3D endless runner game developed with the Godot Engine (v4.x). Players take control of an archer traversing an infinite, procedurally generated forest filled with natural hazards, obstacles, and interactive targets. Beyond standard dodging and jumping, RobinRunner features an active ability mechanic allowing the player to charge an ability gauge and shoot arrows to destroy obstacles and hit targets on the run.

## Core Goals
1. **Fluid Runner Gameplay**: Responsive lane movement, smooth jumping, and tight controls.
2. **Combat & Abilities**: Ability gauge mechanics enabling tactical arrow shooting to clear paths and targets.
3. **Infinite World Generation**: High-performance, pooled modular track generation using low-poly 3D assets.
4. **Lightweight & Cross-Platform**: Initial release targeted at Desktop and Web via Godot's GL Compatibility renderer, structured for future Android support.
5. **Clean & Maintainable Architecture**: Strict adherence to Clean Code principles, decoupled systems, modular phases, and automated testing.

## Scope & Target Platforms
- **Engine**: Godot Engine 4.x
- **Renderer**: GL Compatibility (`gl_compatibility`)
- **Primary Platforms**: Desktop (Windows/Linux/macOS) and Web (HTML5/WebAssembly)
- **Secondary / Future Platform**: Android
- **Art Style**: Stylized low-poly 3D using Kenney Mini-Forest assets
- **Blender Integration**: Only used via Blender MCP when existing assets are insufficient, and strictly requiring prior user approval.

## Constraints & Workflow Standards
- **Language Policy**: 100% English across all repository files, code, documentation, comments, and commit messages. User communication in chat is conducted in Turkish.
- **Git Strategy**: Dedicated branch per development feature using concise naming without redundant "phase" prefixes (e.g., `feature/core-architecture`). Commits after every completed step or bug fix. Merges to `main` only upon explicit user command.
- **Kanban Execution**: Strict single-phase focus. Multiple steps within the same phase can be executed together, but phases must never be mixed.
- **Testing Standard**: Autonomous automated verification for logic/syntax, explicit delegation to user for visual/manual testing.

## Strict Rule Enforcement (projectRules.md)
- **Mandatory Compliance**: Full and strict adherence to `memory-bank/projectRules.md` is mandatory at all times.
- **Zero Deviation**: No rules may be altered, bypassed, or arbitrarily created without explicit user command.
- **Binding Contract**: Every development step, commit, branch, test, architectural design, and file edit must strictly comply with the guidelines defined in `projectRules.md`.

