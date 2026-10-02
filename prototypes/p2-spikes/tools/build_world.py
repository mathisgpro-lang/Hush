#!/usr/bin/env python3
"""Stitch the swipeable Sanctuary world (decision 120): [left panel | home image | right panel], with seams found by
best alignment and feathered, then compute the motion masks (R water, G falling water, B brazier flames, A sky) and a
soft backdrop. Output into SpikeLab/Assets: world-paint.png, world-motion.png, world-backdrop.png, world-layout.json.
Depth is computed afterwards with tools/depthmap (Apple Depth Anything V2)."""
import json, sys, colorsys
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

A = "SpikeLab/Assets"
home = Image.open(f"{A}/home-paint.png").convert("RGB")
W, H = home.size
left = Image.open(sys.argv[1]).convert("RGB").resize((W, H), Image.LANCZOS)
right = Image.open(sys.argv[2]).convert("RGB").resize((W, H), Image.LANCZOS)

def best_overlap(a_right_edge, b_left_edge, max_ov=int(W * 0.18)):
    """How many columns of b's left side best match a's right side (search overlap widths and small vertical shifts)."""
    a = np.asarray(a_right_edge).astype(float); b = np.asarray(b_left_edge).astype(float)
    best = (1e18, 24, 0)
    for ov in range(16, max_ov, 4):
        for dy in range(-12, 13, 4):
            aa = a[max(0, dy):H + min(0, dy), W - ov:]
            bb = b[max(0, -dy):H + min(0, -dy), :ov]
            err = np.mean((aa - bb) ** 2)
            if err < best[0]: best = (err, ov, dy)
    return best

e1, ovL, dyL = best_overlap(left, home)
e2, ovR, dyR = best_overlap(home, right)
print("left overlap", ovL, "dy", dyL, "err", round(e1), "| right overlap", ovR, "dy", dyR, "err", round(e2))
ovL = max(ovL, 60); ovR = max(ovR, 60)          # always blend over a generous band

total = W * 3 - ovL - ovR
canvas = np.zeros((H, total, 3), float); weight = np.zeros((H, total, 1), float)
def put(img, x0, dy, ramp_left, ramp_right):
    a = np.asarray(img).astype(float)
    a = np.roll(a, dy, axis=0)
    w = np.ones((H, W, 1))
    if ramp_left: w[:, :ramp_left, 0] = np.linspace(0, 1, ramp_left)[None, :]
    if ramp_right: w[:, W - ramp_right:, 0] = np.linspace(1, 0, ramp_right)[None, :]
    canvas[:, x0:x0 + W] += a * w; weight[:, x0:x0 + W] += w
put(left, 0, -dyL, 0, ovL)
put(home, W - ovL, 0, ovL, ovR)
put(right, 2 * W - ovL - ovR, -dyR, ovR, 0)
world = (canvas / np.maximum(weight, 1e-6)).clip(0, 255).astype(np.uint8)
Image.fromarray(world).save(f"{A}/world-paint.png")
home_x0 = W - ovL
json.dump({"total": total, "height": H, "homeX0": home_x0, "homeW": W}, open(f"{A}/world-layout.json", "w"))
print("world", total, "x", H, "home starts at", home_x0)

# Motion masks over the whole world (same rules as the home masks).
s = Image.fromarray(world).resize((total // 2, H // 2)); w2, h2 = s.size; px = np.asarray(s).astype(float) / 255
water = np.zeros((h2, w2)); fall = np.zeros((h2, w2)); cand = np.zeros((h2, w2), bool)
for y in range(h2):
    for x in range(w2):
        r, g, b = px[y, x]; hh, ss, v = colorsys.rgb_to_hsv(r, g, b)
        if (0.45 < hh < 0.62 and ss > 0.2 and v > 0.35) or (h2 * 0.19 < y < h2 * 0.45 and v > 0.5 and b > 0.55 and b > r): water[y, x] = 1
        if v > 0.82 and ss < 0.16: fall[y, x] = 1
        if y > h2 * 0.22 and v > 0.96 and 0.08 < hh < 0.17 and ss > 0.5: cand[y, x] = True
fire = np.zeros((h2, w2)); seen = np.zeros_like(cand)
for y0 in range(h2):
    for x0 in range(w2):
        if not cand[y0, x0] or seen[y0, x0]: continue
        q = deque([(x0, y0)]); seen[y0, x0] = True; pts = []
        while q:
            x, y = q.popleft(); pts.append((x, y))
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w2 and 0 <= ny < h2 and cand[ny, nx] and not seen[ny, nx]: seen[ny, nx] = True; q.append((nx, ny))
        if 4 <= len(pts) <= 300:
            for (x, y) in pts: fire[y, x] = 1
lum = px.mean(axis=2); yy = np.mgrid[0:h2, 0:w2][0] / h2
sky = ((yy < 0.36) & (lum > 0.45) & (px[..., 2] > px[..., 1] * 0.8)).astype(float)
def soft(m, grow, blur):
    im = Image.fromarray((m * 255).astype(np.uint8))
    if grow: im = im.filter(ImageFilter.MaxFilter(grow))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(blur)))
mask = np.dstack([soft(water, 0, 3), soft(fall, 3, 2), soft(fire, 7, 4), soft(sky, 0, 6)]).astype(np.uint8)
Image.fromarray(mask, "RGBA").save(f"{A}/world-motion.png")

# A soft backdrop beyond the world's edges (mirror + increasing blur), for safety only.
px_, py_ = int(total * 0.15), int(H * 0.25)
big = np.pad(world, ((py_, py_), (px_, px_), (0, 0)), mode="reflect")
B = Image.fromarray(big); blur = np.asarray(B.filter(ImageFilter.GaussianBlur(24))).astype(float)
Hh, Ww = big.shape[:2]; yy2, xx2 = np.mgrid[0:Hh, 0:Ww]
d = np.clip(np.maximum(np.maximum(np.maximum(px_ - xx2, xx2 - (px_ + total - 1)) / px_, np.maximum(py_ - yy2, yy2 - (py_ + H - 1)) / py_), 0), 0, 1)[..., None]
out = big * (1 - d) + blur * d
Image.fromarray(out.astype(np.uint8)).save(f"{A}/world-backdrop.png")
json.dump({"total": total, "height": H, "homeX0": home_x0, "homeW": W, "backdropW": Ww, "backdropH": Hh},
          open(f"{A}/world-layout.json", "w"))
print("masks and backdrop done")
