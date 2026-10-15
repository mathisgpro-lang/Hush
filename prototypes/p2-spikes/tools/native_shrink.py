#!/usr/bin/env python3
"""Realms built with --native (no pixel filter, Mathis 2026-10-15) are made at 4x their art grid for the masks; this
brings each painting back to the size Codex painted it (smooth, Lanczos), recorded in <id>-native.json.
Run from prototypes/p2-spikes after tools/native_realms.sh's builds."""
import json, os
from PIL import Image
A = "SpikeLab/Assets"
for r in ["library", "stillwater", "highlands", "wilds", "forge", "grove"]:
    j = f"{A}/{r}-native.json"
    if not os.path.exists(j): continue
    size = json.load(open(j)); p = f"{A}/{r}-world-paint.png"
    im = Image.open(p)
    if im.size == (size["w"], size["h"]): print(r, "already", im.size); continue
    im.resize((size["w"], size["h"]), Image.LANCZOS).save(p)
    print(r, im.size, "->", (size["w"], size["h"]))
