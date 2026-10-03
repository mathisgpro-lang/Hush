#!/usr/bin/env python3
"""The swipeable Whispering Grove (iteration 2): [Codex's left panel | the Grove painting | right panel], seams found
by best alignment and feathered (as tools/build_world.py does for the Sanctuary). Also moves the lantern-order map
into the wider layout (no lanterns in the side panels yet). Outputs into SpikeLab/Assets: grove-world-paint.png,
grove-world-lanterns.png, grove-layout.json. Then run tools/depthmap on grove-world-paint.png → grove-world-depth.png.
Run from prototypes/p2-spikes."""
import json
import numpy as np
from PIL import Image

A = "SpikeLab/Assets"; D = "../../docs/design/iter2"
home = Image.open(f"{A}/grove-paint.png").convert("RGB")
W, H = home.size
left = Image.open(f"{D}/grove-left.png").convert("RGB").resize((W, H), Image.LANCZOS)
right = Image.open(f"{D}/grove-right.png").convert("RGB").resize((W, H), Image.LANCZOS)

def best_overlap(a_img, b_img, max_ov=int(W * 0.18)):
    a = np.asarray(a_img).astype(float); b = np.asarray(b_img).astype(float)
    best = (1e18, 24, 0)
    for ov in range(16, max_ov, 4):
        for dy in range(-12, 13, 4):
            aa = a[max(0, dy):H + min(0, dy), W - ov:]
            bb = b[max(0, -dy):H + min(0, -dy), :ov]
            err = np.mean((aa - bb) ** 2)
            if err < best[0]: best = (err, ov, dy)
    return best

_, ovL, dyL = best_overlap(left, home)
_, ovR, dyR = best_overlap(home, right)
print("left overlap", ovL, dyL, "| right overlap", ovR, dyR)
ovL = max(ovL, 60); ovR = max(ovR, 60)
total = W * 3 - ovL - ovR
canvas = np.zeros((H, total, 3)); weight = np.zeros((H, total, 1))
def put(img, x0, dy, rl, rr):
    a = np.asarray(img).astype(float)
    if dy > 0: a = np.concatenate([np.repeat(a[:1], dy, 0), a[:-dy]], 0)       # shift, repeating the edge row
    elif dy < 0: a = np.concatenate([a[-dy:], np.repeat(a[-1:], -dy, 0)], 0)   # (rolling wrapped the bottom to the top)
    w = np.ones((H, W, 1))
    if rl: w[:, :rl, 0] = np.linspace(0, 1, rl)[None, :]
    if rr: w[:, W - rr:, 0] = np.linspace(1, 0, rr)[None, :]
    canvas[:, x0:x0 + W] += a * w; weight[:, x0:x0 + W] += w
put(left, 0, -dyL, 0, ovL); put(home, W - ovL, 0, ovL, ovR); put(right, 2 * W - ovL - ovR, -dyR, ovR, 0)
Image.fromarray((canvas / np.maximum(weight, 1e-6)).clip(0, 255).astype(np.uint8)).save(f"{A}/grove-world-paint.png")
x0 = W - ovL
# The lantern map (half size) moved into the wider layout; nearest resampling keeps each lantern's order exact.
lm = Image.open(f"{A}/grove-lanterns.png").convert("RGB")
lw, lh = lm.size; k = lw / W
out = Image.new("RGB", (int(round(total * k)), lh))
out.paste(lm, (int(round(x0 * k)), 0))
out.save(f"{A}/grove-world-lanterns.png")
json.dump({"total": total, "height": H, "homeX0": x0, "homeW": W}, open(f"{A}/grove-layout.json", "w"))
print("grove world", total, "x", H, "home at", x0)
