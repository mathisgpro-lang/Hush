#!/usr/bin/env python3
"""Pixel worlds at their true size (one texel per art pixel): the tools build them 4x for their masks, then this
shrinks the paintings back (exact, nearest), 16x less memory and faster loading; the shaders snap every lookup to a
pixel's centre so they stay crisp. Run from prototypes/p2-spikes after tools/pixel_realms.sh, build_pixel_world.py
and build_map.py --pixel."""
from PIL import Image
A = "SpikeLab/Assets"
for n in ["px-home-paint", "map-paint"] + [f"{r}-world-paint" for r in ["library", "stillwater", "highlands", "wilds", "forge", "grove"]]:
    p = f"{A}/{n}.png"
    im = Image.open(p)
    w, h = im.size
    if h < 1300 or w % 4 or h % 4: print(n, "skip", im.size); continue      # already native, or not a pixel world
    im.resize((w // 4, h // 4), Image.NEAREST).save(p)
    print(n, (w, h), "->", (w // 4, h // 4))
