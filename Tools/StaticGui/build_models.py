#!/usr/bin/env python3
"""Regenerate StarterGui/*.model.json from the GUI builders (P2-3 static GUI).

Usage:  python3 Tools/StaticGui/build_models.py /path/to/luau

Runs Tools/StaticGui/builders/*.luau through GuiRecorder with a mocked Roblox
API and writes one Rojo .model.json per ScreenGui into StarterGui/.
"""
import glob, os, shutil, subprocess, sys, tempfile

here = os.path.dirname(os.path.abspath(__file__))
repo = os.path.dirname(os.path.dirname(here))
luau = sys.argv[1] if len(sys.argv) > 1 else "luau"

def long_string(s):
    level = 3
    while ("]" + "=" * level + "]") in s:
        level += 1
    return "[" + "=" * level + "[" + s + "]" + "=" * level + "]"

builders = sorted(glob.glob(os.path.join(here, "builders", "*.luau")))
if not builders:
    sys.exit("no builders found in Tools/StaticGui/builders")

with tempfile.TemporaryDirectory() as tmp:
    shutil.copy(os.path.join(here, "GuiRecorder.luau"), tmp)
    entries = []
    for path in builders:
        name = os.path.splitext(os.path.basename(path))[0]
        src = open(path, encoding="utf-8").read()
        entries.append("{ name = %s, src = %s }" % (long_string(name), long_string(src)))
    runner = "SOURCES = {\n" + ",\n".join(entries) + "\n}\n" + open(os.path.join(here, "build_models.luau"), encoding="utf-8").read()
    run_path = os.path.join(tmp, "run.luau")
    open(run_path, "w", encoding="utf-8").write(runner)
    out = subprocess.run([luau, run_path], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stdout + out.stderr)

current = None
models = {}
for line in out.stdout.splitlines(keepends=True):
    if line.startswith("@@@@MODEL "):
        name, summary = line[len("@@@@MODEL "):].rstrip("\n").split(" ", 1)
        current = name
        models[name] = []
        print(f"{name}: {summary}")
    elif line.startswith("@@@@END"):
        current = None
    elif current:
        models[current].append(line)  # builder print() output falls outside the markers

for name, lines in models.items():
    path = os.path.join(repo, "StarterGui", name + ".model.json")
    open(path, "w", encoding="utf-8").write("".join(lines))
    print("wrote", os.path.relpath(path, repo))
