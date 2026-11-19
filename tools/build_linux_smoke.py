#!/usr/bin/env python3
"""Explicit local smoke bundle using a supplied runtime, not a release export."""
import argparse
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--runtime', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
runtime = args.runtime.expanduser().resolve()
if not runtime.is_file():
    parser.error(f'Runtime missing: {runtime}')
out = root / 'dist/linux-smoke'
out.mkdir(parents=True, exist_ok=True)
def checked_run(command, *, cwd=None, marker=None):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=120)
    output = result.stdout + result.stderr
    print(output, end='')
    if result.returncode or 'ERROR:' in output or (marker and marker not in output):
        raise SystemExit(f'Smoke command failed verification: {command[0]} (exit {result.returncode})')

checked_run(['godot', '--headless', '--path', str(root), '--export-pack', 'Linux', str(out / 'VoidLantern.pck')])
shutil.copy2(runtime, out / 'VoidLantern.x86_64')
checked_run([str(out / 'VoidLantern.x86_64'), '--headless', '--quit-after', '3'], cwd=out, marker='VOID_LANTERN_BOOT_OK')
print(f'Smoke bundle: {out}')
