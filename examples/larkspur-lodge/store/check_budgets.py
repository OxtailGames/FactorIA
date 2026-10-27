#!/usr/bin/env python3
"""Draw and entity budgets of the busiest room (the ground floor) at the sizes the stores show the game.

Run from anywhere: FACTORIA=path/to/factoria python3 -I store/check_budgets.py. It plays scenes/ground.scene.json for 300
headless frames at 1280x720 (the design), 1280x800 (Steam Deck), 1180x820 (iPad points) and 2732x2048 (iPad Pro 13 pixels)
and fails when a size goes over the caps of tools/cli/tests/perf/larkspur-lodge.perf.json in the engine repo (maxDrawCalls
300, maxEntities 400, maxTriangles 30000, maxLights 16). Draw calls change with the aspect ratio (culling), entities do not.
CPU time and memory are CI's to measure; here they are printed only.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
FACTORIA = os.environ.get("FACTORIA", "factoria")
CAPS = {"drawCalls": 300, "entities": 400, "triangles": 30000, "lights": 16}
SIZES = [(1280, 720), (1280, 800), (1180, 820), (2732, 2048)]

bad = 0
for w, h in SIZES:
    out = subprocess.run([FACTORIA, "run", "--headless", "--project", PROJECT, "--scene", "scenes/ground.scene.json",
                          "--width", str(w), "--height", str(h), "--frames", "300", "--json"],
                         capture_output=True, text=True).stdout
    perf = json.loads(out)["perf"]
    over = [k for k, cap in CAPS.items() if perf[k] > cap]
    bad += len(over)
    print("%s %4dx%-4d drawCalls %3d entities %3d triangles %5d lights %2d cpu %.2f ms peak %.0f MB%s" % (
        "BAD" if over else "ok ", w, h, perf["drawCalls"], perf["entities"], perf["triangles"], perf["lights"],
        perf["cpuMsAvg"], perf["peakMemoryMB"], "  over: " + ", ".join(over) if over else ""))
sys.exit(1 if bad else 0)
