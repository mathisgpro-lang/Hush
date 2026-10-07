#!/usr/bin/env python3
"""The world map, wider (corrections list #8, 2026-10-05): Codex's side panels stitched on each side of the map
painting (best-overlap seams, feathered), keeping only the inner part of each panel, so the land goes on past the
realms at the sides and the map breathes. Writes SpikeLab/Assets/world-map-wide.png and map-wide.json (x0 = where the
original map starts, its width) for MapScene. Then: tools/depthmap on it, and tools/build_map.py --wide.
Run from prototypes/p2-spikes."""
import json
import numpy as np
from PIL import Image

A = "SpikeLab/Assets"; D = "../../docs/design/iter2"
import sys
PIXEL = "--pixel" in sys.argv                         # decision 149: Codex's pixel map in the middle
main = Image.open("../../docs/design/p29/px-map.png" if PIXEL else f"{A}/world-map.png").convert("RGB").resize((803, 1958), Image.LANCZOS); W, H = main.size
if PIXEL:
    import os
    pl, pr = "../../docs/design/p29/px-map-left.png", "../../docs/design/p29/px-map-right.png"
    if os.path.exists(pl) and os.path.exists(pr): D = "../../docs/design/p29"; LEFT, RIGHT = "px-map-left", "px-map-right"
    else: LEFT, RIGHT = "map-left", "map-right"
else: LEFT, RIGHT = "map-left", "map-right"
left = Image.open(f"{D}/{LEFT}.png").convert("RGB").resize((W, H), Image.LANCZOS)
right = Image.open(f"{D}/{RIGHT}.png").convert("RGB").resize((W, H), Image.LANCZOS)
KEEP = 0.62                                         # how much of each panel's inner side is kept

def best_overlap(a_img, b_img, max_ov=int(W * 0.2)):
    a = np.asarray(a_img).astype(float); b = np.asarray(b_img).astype(float)
    best = (1e18, 24, 0)
    for ov in range(16, max_ov, 4):
        for dy in range(-12, 13, 4):
            aa = a[max(0, dy):H + min(0, dy), W - ov:]
            bb = b[max(0, -dy):H + min(0, -dy), :ov]
            err = np.mean((aa - bb) ** 2)
            if err < best[0]: best = (err, ov, dy)
    return best

_, ovL, dyL = best_overlap(left, main); _, ovR, dyR = best_overlap(main, right)
ovL = max(ovL, 60); ovR = max(ovR, 60)
total = W * 3 - ovL - ovR
canvas = np.zeros((H, total, 3)); weight = np.zeros((H, total, 1))
def put(img, x0, dy, rl, rr):
    a = np.asarray(img).astype(float)
    if dy > 0: a = np.concatenate([np.repeat(a[:1], dy, 0), a[:-dy]], 0)
    elif dy < 0: a = np.concatenate([a[-dy:], np.repeat(a[-1:], -dy, 0)], 0)
    w = np.ones((H, W, 1))
    if rl: w[:, :rl, 0] = np.linspace(0, 1, rl)[None, :]
    if rr: w[:, W - rr:, 0] = np.linspace(1, 0, rr)[None, :]
    canvas[:, x0:x0 + W] += a * w; weight[:, x0:x0 + W] += w
put(left, 0, -dyL, 0, ovL); put(main, W - ovL, 0, ovL, ovR); put(right, 2 * W - ovL - ovR, -dyR, ovR, 0)
wide = Image.fromarray((canvas / np.maximum(weight, 1e-6)).clip(0, 255).astype(np.uint8))
cut = int(W * (1 - KEEP))
wide = wide.crop((cut, 0, total - cut, H))
x0 = W - ovL - cut
wide.save(f"{A}/world-map-wide.png")
json.dump({"x0": x0, "centerW": W, "width": wide.width, "height": H}, open(f"{A}/map-wide.json", "w"))
print("wide", wide.size, "x0", x0, "overlaps", ovL, ovR)
