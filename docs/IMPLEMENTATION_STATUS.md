# Implementation status

Updated 2026-11-18. This delivery implements VL-001, as requested. Future milestones
remain sequential; no gameplay, art or audio milestone is declared complete.

| Milestone | Deliverable | Actual status |
|---|---|---|
| VL-001 | init Godot, viewport, input, repo structure, headless test runner | Implemented; verification limits below |
| VL-002 | player movement, fixed tick, camera/HUD/debug | Not started |
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
The implemented foundation is the source baseline for VL-002; create a baseline
commit before subsequent milestone changes per GDD section 16.

Next: VL-002 player movement and input snapshot (D-pad priority, analog deadzone,
diagonal normalization), fixed-tick mission ownership, HUD/debug and pause/focus.
Do not implement that behavior inside the UI shell.
