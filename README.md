# VOID LANTERN

Original offline horizontal shoot ’em up for Linux/Windows, Godot 4.5+ and GDScript.
Source specification: [GDD](docs/VOID_LANTERN_GDD_v1.0.md).

Current delivery: **VL-005 stage geometry, timelines and checkpoint recovery**.
Eight authored stage datasets are present. The preview renders their terrain,
moving solids and stage beams, and dispatches the full event schedule. Enemy
actors arrive in VL-006 and bosses in VL-007 onward: these datasets are not a
finished campaign. Final pixel art/audio remain VL-008 and later milestones.
See the [milestone backlog](docs/IMPLEMENTATION_STATUS.md).

## Open in the Godot editor

Import `project.godot`, then double-click `scenes/boot.tscn` in FileSystem.
The title screen is stored in the scene and is visible in the 2D editor.
Press **F5** to run the project. In the running window choose
**START CAMPAIGN → LAUNCH STAGE PREVIEW** for scrolling terrain.
The **LAUNCH AEGIS RANGE** option remains available for weapon testing.
The editor canvas itself does not run gameplay. `stage_preview.tscn` and
`aegis_range.tscn` draw development visuals at runtime; F6 runs the selected scene.

## Run and test

From this directory, with Godot installed (tested editor: `4.7.1.stable.fedora.a13da4feb`):

```bash
godot --headless --path . --editor --import --quit
python3 tools/validate_content.py
godot --headless --path . --script tests/run_all.gd
godot --path .
```

No Python packages, network, API keys or plugins are required. Python is only a development tool.
Tests do not write player saves. Expected test summary: `593 assertions, 0 failures`.
To check that the runner really fails, run the same test command with
`-- --self-test-failure`; expected exit code is 1 with one intentional failure.

Menu: arrows/WASD or D-pad/left stick to select; Enter/A to confirm; Esc/B to return.
Quit opens a confirmation with Cancel focused. Campaign/practice/options/score
screens explicitly identify their pending milestone; they do not start fake gameplay.

Stage preview controls: **1 / 2 / 3 / 4** inspect checkpoints 0/40/80/120 seconds;
**N** loads the next stage's geometry; **R** restarts this preview with a fresh run.
These are development inspection controls, not campaign progression. Scrolling
lasts 7200 ticks, then a three-second warning reaches the boss handoff (no boss
actor yet). The HUD's event count records requested enemies, not live actors.

A lethal hit costs one life, freezes the stage for 39 ticks, then reconstructs the
last checkpoint. Movement resumes after 18 appearance ticks; shooting is available
during appearance. Score rolls back; lives/bombs do not. Weapon rank, bits and
missiles each lose one tier (weapon minimum 1). Zero lives stops at GAME OVER.
The full continue/results flow follows in VL-007. Geometry and beams remain lethal
under the specified invulnerability rules; walls always bypass protection.

To fly in the weapon fixture: **START CAMPAIGN → LAUNCH AEGIS RANGE**. After the two-second intro,
move with WASD/arrows or controller, change speed with Shift/LB, pause with Esc/Start.
F3 toggles diagnostics and the hitbox in debug builds. Loss of application focus or
controller disconnection pauses; returning focus never resumes automatically.
Hold **Z/Space** (pad A) for Pulse. Hold **X** (pad X) and release for Charge:
12–44 ticks weak, 45–95 medium, 96+ full. **R** resets range targets and projectiles.
Six aligned targets have 56 HP each; full Charge penetrates five distinct targets.
AEGIS starts attached at the front: **C / pad B** launches or recalls it;
**V / pad Y** swaps sides (or selects the return side while detached).
**F / RB** activates the bomb. Hold fire for module, bit and missile weapons;
holding charge suppresses their fire.

Additional keyboard-only development fixture controls:

| Key | Range action |
|---|---|
| 1 / 2 / 3 | Spawn ARC / PRISM / EMBER pickup ahead of ship |
| 4 / 5 / 6 / 7 | Spawn bit / missile / bomb / life pickup |
| T | Toggle two fixed, visibly telegraphed bullet emitters |
| H | Emit one heavy unblockable orb from the right |
| R | Restore targets and recover the range after a fatal hit |

Collect spawned pickups with the ship. Repeated matching weapon pickups increase
rank, switching type preserves rank. Upgrades persist when resetting this range;
new launch starts the default loadout. If you hit a wall/orb, `SHIP LOST` appears;
R restores this development fixture. The stage preview implements checkpoint recovery separately; full campaign flow is VL-007.
The upper target has front armor. The lower striped wall blocks projectiles and is
lethal to the ship, including during bomb protection. These are development fixtures;
complete campaign enemies and terrain follow in later milestones.
Enemy actors and final art/audio are implemented in later milestones.
This explicit development weapon range is not the finished campaign.

Gameplay bindings (all listed actions now active in the development range):

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

## Stage data

`data/stages/s01.json` through `s08.json` contain all section-10 GDD profiles,
wave rows, solid hazards and stage beams. Runtime reads committed JSON offline.
To re-transcribe the unchanged source specification during development:

```bash
python3 tools/import_stage_specs.py
python3 tools/validate_content.py
```

The validator invokes the dependency-free Godot schema/checkpoint validator. An
invalid fixture must exit 1:

```bash
godot --headless --path . --script tests/validate_stages.gd -- --file res://tests/fixtures/invalid_stage.json
```
