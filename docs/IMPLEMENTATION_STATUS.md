# Implementation status

Updated 2026-11-18. This delivery implements VL-005 after VL-004. Future milestones
remain sequential; complete campaign, final art and audio are not yet delivered.

| Milestone | Deliverable | Actual status |
|---|---|---|
| VL-001 | init Godot, viewport, input, repo structure, headless test runner | Implemented; verification limits below |
| VL-002 | player movement, fixed tick, camera/HUD/debug | Implemented; automated checks pass; human input trial pending |
| VL-003 | Pulse/Charge, swept collisions, projectile lifetime/pool | Implemented; 291 automated assertions pass; human range playtest pending |
| VL-004 | AEGIS FSM, ARC/PRISM/EMBER, bit/missile/bomb, pickups | Implemented; 416 automated assertions pass; human module trial pending |
| VL-005 | terrain + DSL stage director + checkpoint/recovery | Implemented; 593 assertions pass; human terrain playthrough pending |
| VL-006 | E01–E11, E16, E12–E15 + pattern library | Not started |
| VL-007 | B01 + S01 complete data, tutorial, death/continue/results | Not started |
| VL-008 | original art pipeline/core set, S01 polish, audio pipeline/core cues and T01/B01/M00/M01 | Not started |
| VL-009 | S02 & S03 + bosses B02/B03 + unique art/music | Not started |
| VL-010 | S04 & S05 + B04/B05 art/music | Not started |
| VL-011 | S06 & S07 + B06/B07 art/music | Not started |
| VL-012 | S08 & B08 + ending/credits, final soundtrack | Not started |
| VL-013 | profile/save, full menu/practice/highscore/difficulty/accessibility | Not started |
| VL-014 | balance, accessibility pass, automated and manual full campaign, performance | Not started |
| VL-015 | release packaging Linux/Windows, documentation and manifests | Not started |

## VL-001 verification boundary

Godot project imports, title/menu shell runs, 115 foundation assertions pass.
Linux PCK + explicit installed runtime smoke passed headless and with graphics.
Standard matched-template export is blocked (editor 4.7.1, templates 4.7.2).
Manual human playthrough not verified; there is no playable campaign at this stage.
Physical controller, fullscreen and resize verification remain outstanding.
See TEST_REPORT.md for commands and actual observations.

## Baseline and next step

Initial repository: no commits, only untracked user-supplied `docs/` specification
and 15 JPEG references; no AGENTS.md found. Those source materials were preserved.
`docs/GDD.md` points to the actual supplied filename. No push/publication performed.
VL-001 baseline committed locally as `620be51` before VL-002 changes, as required
by GDD section 16. No push/publication performed.

## VL-002 verification boundary

173 assertions pass (115 original foundation assertions plus 58 movement/integration
assertions). Real graphical resize checks cover 1×, 2×, letterbox and fullscreen.
Linux smoke bundle rebuilt and boots. Human playthrough and physical controller
verification remain unverified. Development ship/backdrop are explicitly temporary;
final original sprites, animations and audio remain VL-008 deliverables.
No combat, terrain, stage spawning or camera scrolling is implied by this milestone.

VL-002 and editor-visibility correction committed as baseline `bf97195` before
VL-003 changes. User confirmed the editor launch works; this does not establish a
full human gameplay playthrough.

## VL-003 verification boundary

Pulse 9-tick cadence; Charge 12/45/96 thresholds, 12-tick recovery, cap and cancel;
relative capsule sweeps, circle/box targets, stable contact resolution, 64px spatial
hash and pooled 192 friendly projectiles with eight reserved full-charge slots.
Damage groups prevent duplicate hits and deaths. Range is an explicit development
fixture, separate from the mission base scene, with resettable targets and barriers.
291 assertions pass; real-render range test kills exactly five of six 56HP targets.
HUD/capsule screenshots inspected. Ready is a testable signal; audible ready cue
and final animated assets remain VL-008. Hostile bullet/shield priority is VL-004;
actual terrain/player death/checkpoint logic is VL-005/007.

Linux smoke title boot passes. Direct scene override in installed release runtime
is forbidden by its build configuration; full packaged range interaction is not
verified. Matching-template release export/Windows and human input trial remain
outstanding. See TEST_REPORT.md for exact commands and recorded limits.

VL-003 baseline committed locally as `5cd5fd9`. User confirmed the weapon build
works; this does not establish a full campaign or physical-controller playtest.

## VL-004 verification boundary

AEGIS front/rear, 12-tick swap, launch/free/return, bounded recall fallback, stowed
ports and per-group contact cooldown are implemented. ARC/PRISM/EMBER all ranks,
reflected remaining paths, limited homing, bits, missiles, bomb and pickup effects
are connected to the fixed-tick mission. Hostile shots have a 512-slot pool and
relative sweeps against terrain, module, bits and ship. The AEGIS range adds explicit
pickup/emitter controls without pretending to be a scripted campaign stage.

416 assertions pass. Three rank-3 module captures and detached capture rendered and
inspected. Linux smoke title boot passes. Human playthrough of this milestone,
physical controller, final pixel assets/audio and full release acceptance remain
unverified. Actual stage terrain/checkpoints, enemy/beam producers and boss behavior
remain later milestones; test fixtures cover their current collision contracts.

Existing VL-004 baseline `696f8c8` was clean at the start of VL-005.

## VL-005 verification boundary

All eight full section-10 profiles, wave tables (233 expanded events), solid hazards
and six stage beams transcribed to JSON. Schema and all 32 checkpoint safe points
validated. Runtime director emits stable event IDs without historical catch-up;
actors intentionally bind in VL-006. Terrain renderer and collision share 8px
sampled polygons; world/oscillating rectangles, gates, telegraphs and clipped stage
beams are implemented. Stage lifecycle now includes guarded life loss, 39-tick death,
checkpoint reconstruction, 18-tick appearance, difficulty i-frames, score rollback,
persistent extra-life/collected-life flags, 180-tick boss warning and boss handoff.

593 assertions pass, including two matching 1800-tick replay hashes. Real-render
S01/S04/S07 captures inspected after fixing a background layer that hid terrain.
Linux title smoke passes; matching templates/Windows blockers remain. Preview is
explicitly labeled: no enemy/boss actors, final terrain art or full campaign claim.
Human terrain playthrough and full geometric reachability under combat pressure
remain unverified. Manual debug checkpoint jumps do not count as stage completion.

Next: VL-006 enemy archetypes E01–E16 and attack-pattern library.
