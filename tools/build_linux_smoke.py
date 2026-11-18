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
subprocess.run(['godot', '--headless', '--path', str(root), '--export-pack', 'Linux', str(out / 'VoidLantern.pck')], check=True)
shutil.copy2(runtime, out / 'VoidLantern.x86_64')
subprocess.run([str(out / 'VoidLantern.x86_64'), '--headless', '--quit-after', '3'], cwd=out, check=True)
print(f'Smoke bundle: {out}')
