# Audio Assets Drop-In Guide

Place `.ogg`, `.wav`, or `.mp3` files into `music/` and `sfx/` using these exact base filenames. `AudioManager` loads them automatically on startup (missing files are silently skipped):

## `assets/audio/music/`
- `menu_theme` — Background music for Main Menu
- `gameplay_theme` — Looping background music while running (auto-ducks on Pause)

## `assets/audio/sfx/`
- `jump` — Player jump
- `land` — Player landing
- `lane_switch` — Lateral lane change
- `duck` — Duck / slide
- `footstep` — Footstep tick
- `bow_draw` — Bow draw
- `bow_shoot` — Arrow release
- `arrow_hit` — Arrow hitting archery target / ladder / tree
- `coin_pickup` — Star coin collected (auto pitch-scales with combo)
- `arrow_pickup` — Ground arrow collected
- `stumble` — Non-fatal obstacle stumble / damage
- `death` — Fatal impact / game over
- `ui_click` — Menu button press
- `countdown_tick` — 3-2-1 countdown beep
- `countdown_go` — Countdown launch cue
