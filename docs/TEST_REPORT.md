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


# Actual verification — VL-003

Date: 2026-11-18. Baseline `bf97195`, same Godot 4.7.1 editor / 4.7.2 local smoke
runtime as previous milestones. Scope: base ship weapons and friendly projectile
collision pipeline; this is not enemy/campaign implementation.

| Command | Observed result |
|---|---|
| `godot --headless --path . --editor --import --quit` | Exit 0, scripts/scenes import; no ERROR output |
| `godot --headless --path . --script tests/run_all.gd` | Exit 0, **291 assertions, 0 failures** |
| `godot --path . --script tests/capture_weapons.gd` | Exit 0, real OpenGL range; `kills=5 sixth_hp=56 bullets=0` |
| `python3 tools/validate_content.py` | Exit 0; VL-003 files and locale valid; no campaign validator claim |
| `python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"` | Exit 0, PCK built, title boot marker verified, no runtime ERROR output |
| `./dist/linux-smoke/VoidLantern.x86_64 res://scenes/game/weapon_range.tscn --headless --quit-after 180` | **Blocked** by runtime scene-path override restriction; ERROR printed despite exit 0; range did not launch |
| `python3 -m py_compile tools/build_linux_smoke.py tools/validate_content.py` | Exit 0 |
| `git diff --check` | Exit 0 |

Raw evidence: `qa/vl-003-{import,tests,visual,linux-smoke,range-smoke}.log`.
Inspected actual logical viewport captures `qa/vl-003-charge.png`,
`qa/vl-003-projectile.png`, `qa/vl-003-penetration.png`. First capture shows a
full gauge and nose halo; second a travelling full capsule; third exactly five
aligned targets removed and sixth untouched. HUD text no longer overlaps gauge.

## New test coverage

118 additional assertions (173 → 291) cover:

- T004: Pulse fires at ticks 0,9,…81 over 90 ticks, one update per physics tick.
- T005: release at 0/11/12/44/45/95/96/160 ticks, sizes/speeds/damage/penetration,
  cap at 96, ready signal once, Pulse suppressed throughout charge, immediate
  charge start between ordinary Pulse shots, exact 12-tick recovery and new-press
  requirement if charge was pressed during recovery.
- T006: cancel does not emit a shot; pause clears actual weapon/HUD charge; release
  after resume produces no ghost shot; new charge works; DEATH transition clears
  pool and charge and does not accept firing. Full death/respawn gameplay is later.
- T014/T015 relevant foundation: full charge hits five distinct groups, duplicate
  colliders cannot multiply damage, overlaps cannot re-hit next tick, fast shot
  crossing a 5.5r circle, relative motion against circles/boxes, velocity-oriented
  capsule, rounded-corner near miss, analytic AABB TOI, hash versus exhaustive
  contact candidates across 12 lanes. Shields/hostile shots remain VL-004.
- Thin terrain/armor blocks full charge before target; terrain wins equal-time
  contact; simultaneous lethal hits emit one kill and count damage once. No score
  award is implemented for development targets.
- New projectile overlaps can hit immediately but movement starts the next tick;
  exact speed, pool 192 with eight reserved full-charge slots, lifetime boundary,
  offscreen cleanup, 100 resets clearing all collision/HP/hit-group scope, paused
  projectile position/lifetime unchanged.

## Corrections found during work

Initial integration rejected the first Charge press after entering SCROLL because
weapon cancellation always assumed the button remained held. Cancellation now
uses actual held input; pause-held input is still blocked until release. Ordinary
Pulse cooldown is separate from Charge recovery, so starting charge interrupts
held fire immediately. Subthreshold release emits no shot even if Pulse is held.
First visual capture showed gauge overlapping TYPE text; moved weapon/status text
to a separate label region and recaptured. Runtime scene override error returning
exit 0 led to strengthening smoke validation (ERROR text and boot marker).

## Implementation decisions and limits

Friendly capsule collision dimensions match weapon entries (Pulse uses a 9×3
capsule within its stated envelope). Collision math uses relative movement and a
rounded Minkowski hull for AABBs rather than a rectangular size inflation. The
64px spatial hash is rebuilt from swept target bounds; contact order is TOI,
category (terrain before armor before damage), stable shape ID, projectile ID.
HP belongs to a damage group, not individual shape. Pool slots are preallocated
and reused. Collision candidate/contact arrays still allocate; no performance
benchmark is claimed. Four-second lifetime (240 ticks) and 64px offscreen margin
are cleanup policies; GDD did not prescribe numeric lifetime. No balance values
were changed. Signals expose damage/death/charge-ready for later VFX/audio.

New source: `scripts/combat/{weapon_controller,collision_world,damage_resolver,
projectile_system}.gd`, `scripts/game/weapon_range.gd`,
`scenes/game/weapon_range.tscn`, `tests/{test_combat,capture_weapons}.gd` and UIDs.
Updated mission/player/HUD/menu/boot scenes and scripts, locale, runner, validators,
smoke helper, README and milestone documentation.

**Manual playthrough not verified.** The user confirmed prior editor launch works;
that does not establish human weapon balance/feel testing or a full Arcade pass.
No physical-controller weapon trial, audio review, full campaign, Windows export,
matched-template Linux export or full packaged range interaction is claimed.
Range shapes are explicit development fixtures permitted before VL-008, not final
art or enemy archetypes. Sound, final sprites/animations, Toggle Charge settings UI,
AEGIS, hostile projectiles, moving terrain and campaign remain their later milestones.


# Actual verification — VL-004

Date: 2026-11-18. Source baseline: `5cd5fd9`. Tested engine/runtime/host unchanged.
User reported VL-003 works before this work; no human module-range pass claimed.

| Command | Actual result |
|---|---|
| `godot --headless --path . --editor --import --quit` | Exit 0; scripts/scenes import without ERROR output |
| `godot --headless --path . --script tests/run_all.gd` | Exit 0; **416 assertions, 0 failures** |
| `godot --path . --script tests/capture_aegis.gd` | Exit 0; ARC/PRISM/EMBER rank-3 captures, detached `FREE` at (300,180); 0 visual errors |
| `python3 tools/validate_content.py` | Exit 0; VL-004 file/locale checks; stage/art/audio manifests not yet claimed |
| `python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"` | Exit 0; updated PCK, title boot marker present, no ERROR output |
| `git diff --check` | Exit 0 |

Evidence: `qa/vl-004-{import,tests,visual,linux-smoke}.log`,
`qa/vl-004-{arc,prism,ember,detached}.png`. Screenshots are actual 640×360 rendered
viewports. Inspected PRISM/EMBER/detached captures: module, support weapons, colored
shots, target HP, HUD and range controls are visible. Module art is development
geometry, not final pixel sprite animation or audio.

## Additional automated coverage (125 assertions)

- T007/T008: front start, exact 12-tick swap with inactive shield/fire, 21-tick
  launch at 330px/s, detached desired-side semantics, recall, nearest safe port,
  invisible nine-tick fallback without a swept teleport shield, blocked/edge
  ports and six-tick stowed retry. Two 300-tick spam replays produce identical
  signatures and no invalid/stale shield states.
- T009/T015/T016 relevant scope: front/rear ordinary shot interception, ship-first
  contact remains lethal, heavy orb bypass, bit interception and orb bypass,
  beam-like hazard active/inactive contracts, Assist absorbs simultaneous hits
  once, terrain bypasses invulnerability. Real beam emitters/clipping and enemy
  body actors are not yet implemented; these are collision fixtures.
- All nine type/rank patterns: exact volley counts/damage/cooldowns, rear fan
  mirrors X while preserving Y, detached universal shot, charge suppression.
  Contact damage is 5 per unique group every 12 ticks, independent across targets;
  duplicate colliders do not amplify damage; dead-target cooldown entries removed.
- T012: two PRISM bounces then termination on third contact within a tick, remaining
  path consumed after reflection, diagonal corner normal, reflected path can hit
  another target in the same tick. No unbounded corner loop.
- T013: EMBER 160°/s and missile 120°/s turn limits, dead-target straight flight until
  reacquisition, nine-tick reacquisition, missile forward/range restriction and
  138-tick TTL. ARC deterministic sine uses A=12, period 0.48s.
- T011 and pickups: matching type ranks up, changing type preserves rank, rank and
  support caps/bonuses, life event cannot award twice, offscreen carrier rejection,
  swept ship collection, 38px/s drift, offscreen removal, deterministic slide to
  unblocked Y, simultaneous pickups apply in spawn order.
- Bits at y±25, two-bit/two-missile volley, damage/TTL, blocked bit stows, charge
  suppresses bits/missiles. Hostile pool max512 and reset cleanup.
- T017: bomb consumes one, six warning ticks, one impulse clears ordinary and
  heavy on-screen shots, per-group 25 ordinary damage, max30 total per boss,
  invulnerable boss section unaffected, subsequent bullets survive, repeat blocked
  by cooldown, same-tick ordinary hit protected but solid still lethal.
- Integration: mission routes V to swap, pause freezes swap/bomb warning, held input
  does not retrigger after resume, orb death clears active combat, R recovers range,
  pickup changes module appearance/type in the same tick, one bomb impulse after
  resume. Campaign life penalties/death animations remain later milestones.

## Corrections and implementation decisions

Tests found an eight-frame fallback where nine hidden ticks were required; corrected
the boundary. Runtime typed-array mismatch in an initial fixture call was corrected
and the complete suite rerun without script errors. Reviewed simultaneous pickup
processing and fixed reverse removal order changing upgrade semantics: effects now
apply in authored spawn order, removals afterward. Fallback chooses the nearest
available port and resets its previous position before enabling a shield.

Tick conversions use nearest integer (ARC .28s→17, PRISM .48s→29, EMBER .58s→35).
ARC starts exactly at its declared port offset, then uses phase-adjusted sine
`12*(sin(2π*t/.48+phase)-sin(phase))`; its mean follows from the phase offset.
Homing keeps a valid target and only reacquires when invalid, with stable shape-ID
ties; acquisition does not turn instantly. Reflection performs up to three contacts
per tick, offsets 0.5px along the normal and consumes remaining travel distance.

Bomb protection starts on activation (90 protected simulation ticks); impulse
follows the six-tick ring. This resolves the otherwise unspecified warning-time
protection and preserves same-tick bomb safety; terrain always wins. The GDD's
per-section wording also requires max30 per boss: distribute the total30 over
visible vulnerable sections in stable group-ID order, never damage closed groups.
These are implementation clarifications, not numeric balance changes.

Pickup slide currently scans for nearest free Y, preferring the direction toward
playfield center. VL-005 will supply actual corridor profile integration. Development
range R resets targets/combat, preserving earned loadout; it is not campaign respawn.
Spawnable fixtures (1–7, T/H) are keyboard-only development controls; normal ship
controls retain keyboard/controller bindings. No random waves introduced.

Added: `scripts/entities/{aegis_controller,pickup_system}.gd`,
`scripts/combat/{defense_system,support_system}.gd`,
`scenes/game/aegis_range.tscn`, `tests/{test_aegis,capture_aegis}.gd` and UID files.
Extended existing collision/projectile/damage pipeline, mission, state, range, HUD,
menu/boot, locale, validator and documentation. No architecture replacement.

**Manual playthrough not verified.** No human VL-004 range session, physical gamepad
trial, audio/art quality acceptance, complete enemy/boss campaign, representative
stress benchmark or Windows run is claimed. Source renders and local Linux title
smoke pass. Matching-template release and packaged range interaction limitations
from earlier reports remain. Stage collision geometry, full death/checkpoint rules,
enemy beam/arm sources and final assets/audio remain VL-005 onward.

# Actual verification — VL-005

Date: 2026-11-18. Clean starting baseline: `696f8c8` (already committed when work
resumed). Same editor 4.7.1 / local runtime 4.7.2 and Linux host as previous stages.
Scope: terrain, authored stage timeline, checkpoint/recovery and stage beam hazards.

| Command | Actual result |
|---|---|
| `python3 tools/import_stage_specs.py` | Transcribed all eight profiles/tables, **233 expanded spawn events**, 32 authored solid hazards and six stage beams |
| `godot --headless --path . --editor --import --quit` | Exit 0; no script/import ERROR in final log |
| `godot --headless --path . --script tests/run_all.gd` | Exit 0; **593 assertions, 0 failures** |
| `python3 tools/validate_content.py` | Exit 0; `STAGE_VALIDATION files=8 failures=0`, including 32 safe checkpoints |
| `godot --headless --path . --script tests/validate_stages.gd -- --file res://tests/fixtures/invalid_stage.json` | Expected exit 1; malformed data rejected, not silently replaced |
| `godot --path . --script tests/capture_stages.gd` | Exit 0; actual S01/S04/S07 OpenGL viewport captures, no drawing errors |
| `python3 tools/build_linux_smoke.py --runtime "$HOME/.local/share/godot/export_templates/4.7.2.stable/linux_release.x86_64"` | Exit 0; stage JSON included, updated local PCK and verified title boot |
| `python3 -m py_compile tools/import_stage_specs.py tools/validate_content.py` | Exit 0 |
| `git diff --check` | Exit 0 |

Evidence: `qa/vl-005-{import,tests,visual,invalid-data,linux-smoke}.log` and
`qa/vl-005-{s01,s04,s07}.png`. Final images were inspected: terrain edges, container,
vertically moving gate gap and stage beam are visible. Stage inspection counters
were moved into the HUD so they do not cover collision boundaries. These are
functional development visuals, not final stage art.

## Added assertions (177 beyond VL-004)

- All eight stage schemas and exact expanded GDD counts (43/39/32/21/24/29/20/25).
  Stable IDs, ordered equal-time rows, cyclic Y lists, corridor fractions, mount
  fallback at open edges, pickup x600, allowed left entries, single dispatch per
  tick, binary checkpoint seek without historical catch-up. Every timeline is
  drained through tick7200 with all expected events exactly once.
- All 8×4 checkpoints have a deterministic safe point at radius20. Profile clamp,
  right-edge world coordinate conversion, interpolation, shared polygon geometry,
  swept circle against slopes, world scroll applied once, absolute oscillation,
  fixed gate gap, pre-entry hazard warning and clean boss arena.
- Corrupt data cases: illegal left entry, event crossing end, unknown gameplay
  keys, missing courier drop, nonfinite geometry, invalid identity and absent
  profile endpoint. Independent validator CLI's negative fixture exits nonzero.
- Death before/at40s, checkpoints80/120, one life decrement, 39 death ticks,
  18 appearance ticks, movement lock and stage-clock freeze during recovery,
  difficulty-specific i-frames, safe reconstruction, zero-lives GAME_OVER.
  Score rolls back while bomb count, lives and speed do not; rank/bits/missiles
  lose one tier. 50k/120k extra lives cannot be farmed by checkpoint rollback.
- Tick7200 is transition-only, scroll solids clear, boss warning lasts180 ticks
  excluding pause, preserved Assist protection, boss handoff does not advance
  scroll time. Boss actor itself remains a future milestone.
- Stage beam warning is inactive, active/expiry ticks exact, clip to nearest
  current solid across beam width, previous-frame solid movement cannot move
  the instantaneous clipping point, warning begun before a checkpoint is skipped.
- Two accelerated 1800-tick runs with the same input produce the same aggregate
  SHA-256: `0c5e4b66c3903cbfcc63882051c5bea384f80bc841b316c315cc84c45bc6d692`.
  Each tick hashes implemented gameplay state: player/module, weapons, sorted
  projectile records, damage groups, defense/support, pickups, run flags, checkpoint,
  director cursor, terrain samples and beams. Rendering/time measurements are
  excluded. This is same-build determinism, not cross-platform determinism or an
  enemy/boss replay test before those actors exist.

## Defects found and corrected

- Early headless preload could not resolve an autoload name in pickup code.
  Lifetime flags are now queried via the scene tree for spawning and the passed
  run state for collection. Final full suite compiles/runs without those errors.
- JSON arrays contain floating numbers; direct deep comparison to an integer
  checkpoint array rejected valid files. Validate checkpoint values individually.
- Old parent-level backdrop covered negative-Z terrain. Moved it to an explicit
  `z=-100` child; recaptured and visually inspected the visible collision outlines.
- Death cleanup erased collision geometry before it could be drawn as a frozen
  scene. Terrain view now retains its last visual geometry independently until
  reconstruction; a test checks retention while transient collision records clear.
- Instantaneous beam clipping initially reused moving-target sweep history. It now
  freezes each solid at its current pose for the ray/width query.
- Boss warning cleared remaining Assist protection via generic defense reset.
  Preserve the protection flag across this nonlethal transition; regression added.
- Added the previously omitted normative +100 per collected pickup and persistent
  score/life flags. This is a specification correction, documented in
  BALANCE_CHANGES.md; no authored geometry/wave/weapon values were rebalanced.

## Implementation and acceptance limits

Committed JSON is runtime input; optional source transcription is offline Python
standard library. Solid geometry is sampled at 8 world pixels and used by both
rendering and convex capsule sweeps. Gates use two fixed-height slabs translated
by the same oscillating gap center, so collision motion does not depend on changing
box dimensions. Broad-phase bounds avoid unnecessary solid sweeps. Geometry and
beams reconstruct from absolute stage ticks; event history never replays before
checkpoint. Pickups consult the actual corridor midpoint when sliding out of solids.

New source: `scripts/data/stage_data.gd`, `scripts/game/{stage_director,
terrain_profile,terrain_view,checkpoint_recovery,stage_beams,stage_controller}.gd`,
`scripts/ui/backdrop.gd`, `scenes/game/stage_preview.tscn`, `data/stages/s01..s08.json`,
`tools/import_stage_specs.py`, `tests/{test_stages,validate_stages,capture_stages}.gd`,
negative JSON fixture and UID files. Extended existing mission/combat geometry,
state/pickup scoring, menu, export filters, validators and documentation.

Enemy events currently emit `enemy_requested`; there are **no fake enemy actors**
or random replacement waves. Boss boundary emits `boss_requested` and visibly
identifies the pending boss actor. Full enemy behavior is VL-006; S01 boss/death/
continue/results integration is VL-007. The development preview permits checkpoint
inspection and next-geometry selection; these do not count as campaign completion.
At zero lives it stops at GAME_OVER; continue UI is not claimed delivered here.
Death/appearance durations are functional; final explosion/audio/animations remain
VL-008. Cached terrain visuals freeze while transient combat pools are cleared.

**Manual playthrough not verified.** Automated schema/safe-point/replay tests are
not full geometric reachability under all moving obstacles or bullet-pressure
fairness. No human complete Arcade pass, enemy/boss stage acceptance, physical
controller/Windows trial or representative performance benchmark is claimed.
Local Linux title smoke is verified; matched-template release and full packaged
stage interaction limitations remain. No publication or network dependence added.
