# RobinRunner - Project Rules and Guidelines

> **Temporary Project Rules & Workflow Specification**

---

## 1. Project Overview

- **Project Name**: RobinRunner
- **Game Genre**: Endless Runner
- **Engine**: Godot Engine (v4.x)
- **Rendering Mode**: Compatibility (`gl_compatibility`)
- **Target Platforms**:
  - Primary: Desktop & Web
  - Future: Android support (planned)
- **Key Gameplay Features**:
  - Core endless runner mechanics.
  - Character abilities (e.g., firing arrows when ability gauge is full, plus upcoming special skills).
- **Assets**:
  - Primary assets: Pre-made Kenney assets located in the `addons/` directory.
  - Blender Usage: Blender MCP can be utilized if available assets are insufficient.
  - **Blender Rule**: **Always ask for user permission before using Blender.** No unnecessary or unapproved Blender usage.

---

## 2. Communication & Language

- **User Chat**: Turkish is used exclusively when speaking directly to the user in chat.
- **All Files & Code**: 100% English. All project files, documentation, rules, memory bank files, code, comments, commit messages, and task trackers must strictly be written in simple, clear, and concise English. No Turkish phrases or words are allowed inside any project files.

---

## 3. Git Workflow & Branching Strategy

- **Branch Structure**:
  - Direct pushing or committing everything to `main` is strictly prohibited.
  - Dedicated branches must be created for each Phase/Feature (e.g., `feature/phase-name`).
  - Merging into `main` is only performed upon explicit command and approval from the user.
- **Commit Frequency & Timing**:
  - Commit after completing an operation, step, or bug fix.
  - Do not hoard, accumulate, or delay commits until the end.
- **Commit Messages**:
  - Written in English.
  - Concise, descriptive, and clearly explain what was accomplished.

---

## 4. Phase & Step Structure (Kanban Logic)

- **Phases & Steps**:
  - The development process is broken down into structured **Phases**.
  - Each Phase contains single-purpose **Steps** (e.g., Main Menu UI, Main Menu Background).
- **Phase Purity & Scoping**:
  - Phases must remain strictly scoped and modular.
  - Cross-domain contamination is not allowed (e.g., logging logic must never be mixed into a UI phase).
- **Execution Rules**:
  - **Single Phase Rule**: Multiple steps within the same phase can be executed in one go, but working across multiple phases simultaneously is **strictly prohibited**.
  - **Commit Scope**: Multiple steps of the *same phase* may be included in a single commit if appropriate, but changes from multiple phases must **never** be mixed in one commit.
  - **Completion Tracking**: When a step or phase is considered complete, notify the user and update the checklist upon user confirmation.

---

## 5. Code Quality & Project Organization

- **Clean Code Principles**:
  - Code must strictly adhere to Clean Code practices: readable, maintainable, modular, and simple.
  - Avoid overly complex structures, duplicated logic, or cluttered scripts.
- **Directory & Folder Structure**:
  - The project tree must remain neat, clear, and logically organized.
  - Scenes, scripts, assets, and resources must be stored in well-categorized folders.
- **Function Comments**:
  - Code comments must be concise, purposeful, and to the point.
  - Every function must include brief, meaningful comments explaining what it does without unnecessary fluff or excessive verbosity.

---

## 6. Decision-Making & Recommendations

- **User Authority**:
  - All operations proceed strictly under user commands and instructions.
  - Do not exceed given orders or invent arbitrary rules without user instruction.
- **Advice & Suggestions**:
  - Recommendations and improvements can be suggested to the user.
  - Suggestions must always be presented as questions (e.g., "Should we do this like...?") and require user approval before implementation.

---

## 7. Documentation & Tool References

- **Web Search for Official Documentation**:
  - Web search may be utilized to retrieve up-to-date, accurate documentation and references (such as Godot docs, Blender docs, etc.).
  - Always verify API signatures, syntax, and engine-specific behaviors against the relevant official docs to ensure compatibility.

---

## 8. Testing Workflow & Verification

- **Automated & Self-Executable Tests**:
  - Once a system or feature step is implemented and committed, immediately proceed to testing.
  - All tests within the agent's capability (such as script syntax checks, unit/logic tests, runtime error logs, headless checks) must be run autonomously without asking the user for permission.
  - When the tests pass, commit the test stage accordingly.
- **Visual & Manual Testing Nuance**:
  - When a test requires visual verification or human assessment (such as UI appearance, aesthetic details, animations, or subjective gameplay feel), explicitly inform the user that it requires manual inspection and ask them to test it visually.


