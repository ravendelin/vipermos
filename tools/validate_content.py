#!/usr/bin/env python3
"""Validate content implemented to date; does not certify future stage/art data."""
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
errors = []
try:
    catalog = json.loads((root / 'data/locales/en.json').read_text())
    required = {'title', 'tagline', 'prompt', 'campaign', 'practice', 'scores',
                'options', 'credits', 'quit', 'back', 'build', 'pending',
                'future', 'credits_body', 'quit_question', 'cancel', 'hint',
                'charge_label', 'range_title', 'range_hint', 'hud_top', 'hud_bottom',
                'lab_hint', 'range_dead', 'aegis_return', 'aegis_stowed'}
    for key in sorted(required):
        if not isinstance(catalog.get(key), str) or not catalog[key].strip():
            errors.append(f'en.json: missing or empty string {key}')
except (OSError, ValueError, TypeError) as exc:
    errors.append(str(exc))
for path in ['project.godot', 'scenes/boot.tscn', 'autoload/input_bindings.gd',
             'autoload/locale.gd', 'scripts/ui/menu_shell.gd', 'export_presets.cfg',
             'assets/licenses/Godot-LICENSE.txt', 'assets/licenses/Godot-COPYRIGHT.txt',
             'scenes/game/weapon_range.tscn', 'scripts/combat/weapon_controller.gd',
             'scripts/combat/projectile_system.gd', 'scripts/combat/collision_world.gd',
             'scripts/combat/damage_resolver.gd', 'scripts/entities/aegis_controller.gd',
             'scripts/entities/pickup_system.gd', 'scripts/combat/defense_system.gd',
             'scripts/combat/support_system.gd', 'scenes/game/aegis_range.tscn']:
    if not (root / path).is_file():
        errors.append(f'Missing {path}')
for error in errors:
    print(f'FAIL: {error}', file=sys.stderr)
print(f'VL-004 content: {len(errors)} errors. Stage/art/audio validation begins in later milestones.')
sys.exit(bool(errors))
