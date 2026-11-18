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
