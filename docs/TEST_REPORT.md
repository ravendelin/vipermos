# Actual verification — VL-001

Date: 2026-11-18. Scope: foundation only. Commands executed from repository root
unless stated otherwise. Engine/platform details are in BUILD.md.

| Check / command | Actual result |
|---|---|
| `godot --headless --path . --editor --import --quit` | PASS, exit 0, project and scripts imported |
| `python3 tools/validate_content.py` | PASS, exit 0, locale/foundation files valid; not a campaign validator yet |
| `godot --headless --path . --script tests/run_all.gd` | PASS, exit 0, 115 assertions, 0 failures |
| Same runner with `-- --self-test-failure` | Expected exit 1, 116 assertions, one intentional failure; runner failure path confirmed |
| `godot --headless --path . --quit-after 3` | PASS, exit 0, boot marker |
| `godot --path . --script tests/capture_shell.gd` | PASS, exit 0, real OpenGL render; PNG saved and visually inspected |
| `godot --headless --path . --export-release Linux dist/linux/VoidLantern.x86_64` | BLOCKED, exit 1, missing matching 4.7.1 export templates |
| `python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"` | PASS, exit 0, PCK packaged and explicit 4.7.2 runtime booted headless |
| `./dist/linux-smoke/VoidLantern.x86_64 --quit-after 5` | PASS, exit 0, Compatibility/OpenGL startup and boot marker |
| Copy only runtime + PCK to temporary directory with spaces, launch there headless | PASS, exit 0, no source tree/cache required |

## Automated scope

The 115 assertions verify 60 Hz configuration, viewport/window sizes, integer
letterbox settings, renderer, all required keyboard/button bindings, stick axes,
0.22 deadzones, idempotent binding installation, title-to-menu input, six menu
entries, initial focus, synthesized D-pad navigation, every destination/back
route, cancel-first quit confirmation, and 100 UI round trips without accumulating
child nodes. These are foundation tests, not substitutes for GDD gameplay T001–T042.
No saves are written. No gameplay movement behavior is asserted yet.

`qa/vl-001-tests.log`, `qa/vl-001-visual.log`, `qa/vl-001-linux-smoke.log` and
`qa/vl-001-isolated.log` retain actual output. `qa/vl-001-menu.png` is the inspected
640×360 viewport image. All six buttons, title and navigation hint fit and the
selected first button is visibly distinct. This is a development menu shell;
final title art/animation/music are not claimed.

## Issues found and resolved

- Source reference JPEGs initially imported by Godot. Added `docs/.gdignore`,
  removed generated reference import sidecars and excluded documentation from
  exports. User JPEGs and specification unchanged.
- Installed release runtime rejects `--path` by build configuration. Smoke helper
  now uses the executable's directory with its adjacent PCK; rerun passed.
- Export templates do not match editor. Retained the failure as an outstanding
  release-toolchain limitation; tested explicit cross-patch smoke separately.

## Outstanding acceptance

**Manual playthrough not verified.** No human gameplay pass, physical-controller
trial, controller hotplug, manual resize/fullscreen, audio review or performance
benchmark has occurred. There is no gameplay in VL-001 to play through. Injected
controller events and rendered screenshots are automated checks, not human testing.
Windows export/run untested. Standard Linux release export remains blocked until
matching templates/editor are available. The remaining milestones, final asset
production and full campaign acceptance are not complete.

## Patch inventory

- `project.godot`, `export_presets.cfg`, `.gitignore`: engine, display, export setup.
- `autoload/input_bindings.gd`, `autoload/locale.gd`: defaults and English catalog.
- `scenes/boot.tscn`, `scripts/ui/menu_shell.gd`, `data/locales/en.json`: UI shell.
- `tests/run_all.gd`, `tests/capture_shell.gd`: assertions and real-render capture.
- `tools/validate_content.py`, `tools/build_linux_smoke.py`: validation and smoke packaging.
- `assets/licenses/Godot-{LICENSE,COPYRIGHT}.txt`: dependency terms.
- `README.md`, `docs/{GDD,BUILD,IMPLEMENTATION_STATUS,TEST_REPORT,ASSET_LICENSES,BALANCE_CHANGES}.md`,
  `docs/.gdignore`, `docs/qa/*`: setup, backlog, evidence and limitations.
- `.gitkeep` directory markers and Godot `.gd.uid` sidecars establish the specified
  repository layout and stable script IDs without inventing empty game systems.


# Actual verification — VL-002

Date: 2026-11-18. Baseline: `620be51`. Same editor/runtime and host as VL-001.

| Command | Actual result |
|---|---|
| `godot --headless --path . --editor --import --quit` | Exit 0, new scripts imported |
| `godot --headless --path . --script tests/run_all.gd` | Exit 0; **173 assertions, 0 failures** |
| `godot --path . --script tests/capture_movement.gd` | Exit 0, **0 visual check failures**, real OpenGL rendering |
| `python3 tools/validate_content.py` | Exit 0; foundation content validation, still not campaign validation |
| `python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"` | Exit 0; updated Linux PCK + runtime boots headless |
| `git diff --check` | Exit 0 |

Evidence: `qa/vl-002-tests.log`, `qa/vl-002-visual.log`,
`qa/vl-002-linux-smoke.log`, `qa/vl-002-*.png`.
Logical viewport captures of flight and pause were visually inspected: ship,
center hitbox, both 24px HUD bars and focused pause buttons are readable.
PNG captures contain logical pixels, not a desktop screenshot of the physical window.
Actual root-window transform checks recorded:

| Window | Logical viewport | Scale | Letterbox offset |
|---|---|---|---|
| 640×360 | 640×360 | 1× | 0,0 |
| 1280×720 | 640×360 | 2× | 0,0 |
| 1100×800 | 640×360 | 1× | 230,220 |
| Fullscreen on this host | 640×360 | 4× | not asserted |

Added tests cover fresh-run lives/bombs/loadout by difficulty, initial HUD, 60 ticks
at 145px/s, normalized diagonal distance, instant stop, both corner bounds, all
speed tiers/cycling, opposite keys/D-pad, proportional 0.22 deadzone, D-pad priority,
controller removal, one-shot edge handling, between-tick taps, held charge/edge
suppression and fresh presses after resume. Integration covers the exact 120-tick
intro, mission-owned movement clock, pause for 120 attempted ticks **and two seconds
of actual wall time**, focus-out/in staying paused, cleared movement after focus
loss, unplug pause, F3/hitbox toggle, quit cancel remaining paused, and real scene
transitions from menu → mission → confirmed quit → title.

T001/T002 and the currently implemented portion of T003 are covered. T006 only
checks charge-state cancellation/input gating: actual charge weapons and spawned
shots do not exist yet and are not claimed tested. Spawn/particle/audio pause
behavior must be verified when those systems are introduced.

Issues corrected during verification: retained short edge taps between ticks;
allowed a genuinely new press immediately after resume; canceling the quit
confirmation now returns to the pause menu; graphical resize harness uses the Godot
Window API so root size and transforms update together (direct DisplayServer size
changes left root size stale in the initial harness).

Implementation files added: `autoload/game_state.gd`,
`scripts/game/{input_snapshot,mission_controller}.gd`,
`scripts/entities/player_controller.gd`, `scripts/ui/mission_hud.gd`,
`scenes/game/mission.tscn`, `tests/{test_movement,capture_movement}.gd`, plus UID files.
Updated: `project.godot`, `scripts/ui/menu_shell.gd`, `data/locales/en.json`,
`tests/run_all.gd`, README and milestone/QA documentation.

**Manual playthrough not verified.** Synthesized keyboard/controller events and
programmatic focus/resize are not human interaction or a physical controller test.
Minimum-window drag behavior and physical controller feel/hotplug remain human
checks. Final visual animation/art/audio, collision walls and campaign are pending
their milestones. Matching-template Linux release and Windows blockers from
VL-001 remain; no final release or full-game acceptance is asserted.

## Editor visibility correction

User reported an empty scene in Godot. `boot.tscn` contained only a root Control;
all visible children were created in `_ready()`, which does not run in the editor.
Stored the title, background, labels, button and panel in `boot.tscn`; runtime menu
now reuses that panel. README documents opening the scene and F5/F6 launch.

Verification: editor import exit 0; full runner **173 assertions, 0 failures**;
graphical menu capture exit 0. `godot --path . --script tests/capture_static_title.gd`
renders the serialized scene with its runtime script removed, exit 0. Inspected
`qa/boot-static-preview.png`: title, build label and start button visible without
running `_ready()`. This verifies serialized content, not manual editor interaction.
Mission ship/HUD remain runtime drawing; direct mission preview uses F6.
