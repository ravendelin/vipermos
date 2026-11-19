# VOID LANTERN

Original offline horizontal shoot ’em up for Linux/Windows, Godot 4.5+ and GDScript.
Source specification: [GDD](docs/VOID_LANTERN_GDD_v1.0.md).

Current delivery: **VL-003 weapons foundation**. The title, menu and weapon range run; campaign,
combat, final pixel art and music are scheduled in the [milestone backlog](docs/IMPLEMENTATION_STATUS.md).
This is not a finished game or the vertical slice.

## Open in the Godot editor

Import `project.godot`, then double-click `scenes/boot.tscn` in FileSystem.
The title screen is stored in the scene and is visible in the 2D editor.
Press **F5** to run the project. In the running window choose
**START CAMPAIGN → LAUNCH WEAPON RANGE** to control the ship.
The editor canvas itself does not run gameplay. `weapon_range.tscn` still draws its
development ship/HUD/targets at runtime; use F6 on that scene for a direct range test.

## Run and test

From this directory, with Godot installed (tested editor: `4.7.1.stable.fedora.a13da4feb`):

```bash
godot --headless --path . --editor --import --quit
python3 tools/validate_content.py
godot --headless --path . --script tests/run_all.gd
godot --path .
```

No Python packages, network, API keys or plugins are required. Python is only a development tool.
Tests do not write player saves. Expected test summary: `291 assertions, 0 failures`.
To check that the runner really fails, run the same test command with
`-- --self-test-failure`; expected exit code is 1 with one intentional failure.

Menu: arrows/WASD or D-pad/left stick to select; Enter/A to confirm; Esc/B to return.
Quit opens a confirmation with Cancel focused. Campaign/practice/options/score
screens explicitly identify their pending milestone; they do not start fake gameplay.

To fly: **START CAMPAIGN → LAUNCH WEAPON RANGE**. After the two-second intro,
move with WASD/arrows or controller, change speed with Shift/LB, pause with Esc/Start.
F3 toggles diagnostics and the hitbox in debug builds. Loss of application focus or
controller disconnection pauses; returning focus never resumes automatically.
Hold **Z/Space** (pad A) for Pulse. Hold **X** (pad X) and release for Charge:
12–44 ticks weak, 45–95 medium, 96+ full. **R** resets range targets and projectiles.
Six aligned targets have 56 HP each; full Charge penetrates five distinct targets.
The upper target has front armor; the lower striped panel blocks projectiles.
These are isolated collision fixtures, not campaign enemies or player-contact walls.
Enemies, stage terrain and final art/audio are implemented in later milestones.
This explicit development weapon range is not the finished campaign.

Gameplay bindings (Pulse/Charge active; AEGIS and additional weapons follow in VL-004):

| Action | Keyboard | Xbox controller |
|---|---|---|
| Move | WASD / arrows | D-pad / left stick |
| Fire | Z / Space | A |
| Charge | X | X |
| AEGIS toggle / side | C / V | B / Y |
| Speed | Shift | LB |
| Bomb | F | RB |
| Pause | Esc | Start |

Viewport 640×360, default window 1280×720, minimum 640×360, integer scaling,
letterbox, nearest textures, Compatibility renderer, fixed physics 60 Hz.
Hardware requirements and full-game performance are not yet benchmarked.

## Build

See [BUILD.md](docs/BUILD.md) for release commands, the template-version blocker,
and a verified local Linux smoke bundle. Build outputs are ignored by Git.
See [TEST_REPORT.md](docs/TEST_REPORT.md) for actual results and verification limits.
Reference screenshots in `docs/images` are excluded from runtime imports/exports.
Art/audio generators and regeneration instructions arrive with VL-008; no final
art or audio is claimed in this milestone.
