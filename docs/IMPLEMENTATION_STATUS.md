# Implementation status

Updated 2026-11-18. This delivery implements VL-002 after VL-001. Future milestones
remain sequential; no gameplay, art or audio milestone is declared complete.

| Milestone | Deliverable | Actual status |
|---|---|---|
| VL-001 | init Godot, viewport, input, repo structure, headless test runner | Implemented; verification limits below |
| VL-002 | player movement, fixed tick, camera/HUD/debug | Implemented; automated checks pass; human input trial pending |
| VL-003 | Pulse/Charge, swept collisions, projectile lifetime/pool | Not started |
| VL-004 | AEGIS FSM, ARC/PRISM/EMBER, bit/missile/bomb, pickups | Not started |
| VL-005 | terrain + DSL stage director + checkpoint/recovery | Not started |
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

Next: VL-003 Pulse/Charge, swept collision resolution, projectile lifetime/pool.
