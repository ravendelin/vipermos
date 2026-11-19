# Build record — VL-001

Date: 2026-11-18. Host: Linux x86_64. Tested editor:
`4.7.1.stable.fedora.a13da4feb`. Compatibility/OpenGL, AMD Radeon RX 6600,
Mesa 26.2.6. Minimum design target is Godot 4.5; 4.5 itself was not tested.
No external addons or Python dependencies at this stage.

## Standard exports

Install export templates matching the exact Godot editor version first:

```bash
mkdir -p dist/linux dist/windows
godot --headless --path . --export-release Linux dist/linux/VoidLantern.x86_64
godot --headless --path . --export-release Windows dist/windows/VoidLantern.exe
```

Linux command was attempted and failed (exit 1): installed editor requires
`4.7.1.stable/linux_release.x86_64`; only 4.7.2 templates are installed.
No templates were renamed or global toolchain settings changed. Windows export
and execution have not been verified. A matched release toolchain remains required.

## Verified local Linux smoke bundle

An explicit fallback packages the project with the installed editor and copies a
supplied runtime beside the PCK. This is a smoke artifact, not the release pipeline:

```bash
python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"
./dist/linux-smoke/VoidLantern.x86_64 --quit-after 5
```

Both headless and graphical runs passed with runtime
`4.7.2.stable.official.ed1daf0bf`, boot marker printed, exit 0.
The runtime and `VoidLantern.pck` must remain together. The runtime forbids `--path`,
so the smoke script runs from the artifact directory without that flag.
This cross-patch smoke does not establish broader compatibility.

## Layout capture

```bash
godot --path . --script tests/capture_shell.gd
```

Writes `docs/qa/vl-001-menu.png` from the real graphical viewport, then exits.
Tests and documentation are excluded from packaged resources. PNG shows logical
640×360 pixels; physical 2×/fullscreen interaction verification is still pending.


## VL-003 smoke update

Rebuilt local Linux smoke bundle with Pulse/Charge and range resources. Boot marker
verified; helper now rejects runtime `ERROR:` output even if Godot exits zero, and
requires the boot marker. Both editor and runtime versions remain unchanged.
Attempting `./dist/linux-smoke/VoidLantern.x86_64 res://scenes/game/weapon_range.tscn
--headless --quit-after 180` is rejected because this runtime disables scene path
overrides. Despite exit 0 it did **not** launch the range; the log is retained.
Source range renders via `godot --path . --script tests/capture_weapons.gd`.
Full packaged range interaction is not claimed verified.


## VL-004 smoke update

Same editor/runtime version pair. `tools/build_linux_smoke.py` rebuilt the PCK with
AEGIS, support/pickup/hostile systems and passed verified title boot. Matching
4.7.1 templates are still absent; cross-patch smoke is not a release certification.
Source graphical capture: `godot --path . --script tests/capture_aegis.gd`.
