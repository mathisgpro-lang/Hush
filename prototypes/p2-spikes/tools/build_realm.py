#!/usr/bin/env python3
"""Build a living realm from Codex's paintings (2026-10-03): one tool for every realm, as the Grove was built.
  1. Stitch [left | main | right] when the side panels exist (best-overlap seams, feathered), so you can look around.
  2. Depth with Apple's Depth Anything V2 (tools/depthmap).
  3. The realm's lights (its lanterns, lamps, fires, furnaces): bright warm blobs (the sun excluded by size), ordered
     outward from the stone circle, so they relight one by one as you grow in its pillar.
     <id>-world-lights.png (half size): R = order of the nearest light (Voronoi), G = the light's core, B = its pool,
     A = water (moving, reflecting).
  4. <id>-layout.json: the wide layout, where the Spark hovers (circleU/V), and <id>-lights.json (light positions).
Usage (from prototypes/p2-spikes): python3 tools/build_realm.py <id> circleU circleV [water: band y0,y1 as top-down
fractions] [--water-hue lo,hi] [--preview out.png]"""
import json, subprocess, sys, os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

rid = sys.argv[1]; cu, cv = float(sys.argv[2]), float(sys.argv[3])
opts = sys.argv[4:]
def opt(name, default=None):
    return opts[opts.index(name) + 1] if name in opts else default
A = "SpikeLab/Assets"; D = "../../docs/design/realms"
main = Image.open(f"{D}/{rid}.png").convert("RGB")
W, H = 852, 1846
main = main.resize((W, H), Image.LANCZOS)
panels = [f"{D}/{rid}-left.png", f"{D}/{rid}-right.png"]

# ---- 1. Stitch ----
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

if all(os.path.exists(p) for p in panels):
    left = Image.open(panels[0]).convert("RGB").resize((W, H), Image.LANCZOS)
    right = Image.open(panels[1]).convert("RGB").resize((W, H), Image.LANCZOS)
    _, ovL, dyL = best_overlap(left, main); _, ovR, dyR = best_overlap(main, right)
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
    put(left, 0, -dyL, 0, ovL); put(main, W - ovL, 0, ovL, ovR); put(right, 2 * W - ovL - ovR, -dyR, ovR, 0)
    world = Image.fromarray((canvas / np.maximum(weight, 1e-6)).clip(0, 255).astype(np.uint8))
    x0 = W - ovL
    print("stitched", total, "x", H)
else:
    world = main; total = W; x0 = 0
    print("no side panels yet: single view")
world.save(f"{A}/{rid}-world-paint.png")

# ---- 2. Depth ----
subprocess.run(["./tools/depthmap", "tools/models/DepthAnythingV2SmallF16.mlmodelc", f"{A}/{rid}-world-paint.png", f"{A}/{rid}-world-depth.png"],
               check=True, capture_output=True)

# ---- 3. Lights and water (half size) ----
s = world.resize((total // 2, H // 2), Image.LANCZOS); w2, h2 = s.size
px = np.asarray(s).astype(float) / 255
hsv = np.asarray(s.convert("HSV")).astype(float) / 255
h, sat, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
Y, X = np.mgrid[0:h2, 0:w2]
# A light is a small, very bright, warm core that stands out from what's around it (leaves and sunlit stone don't).
around = nd.uniform_filter(v, 15)
warm = (v > 0.93) & (h > 0.03) & (h < 0.13) & (sat > 0.45) & (v - around > float(opt("--light-contrast", "0.1")))
lab, n = nd.label(warm)
sizes = nd.sum(warm, lab, range(1, n + 1))
cx_home = (x0 + cu * W) / 2; cy_home = (1 - cv) * H / 2
blobs = []
for i, o in enumerate(nd.find_objects(lab)):
    if not (int(opt("--min-light", "4")) <= sizes[i] <= 220): continue     # specks out; the sun (huge) out
    ys, xs = np.where(lab[o] == i + 1)
    by, bx = ys.mean() + o[0].start, xs.mean() + o[1].start
    if by < h2 * 0.08: continue                              # the sky's top edge
    score = float((v[lab == i + 1] - around[lab == i + 1]).mean()) * np.sqrt(sizes[i])   # how much it shines
    blobs.append((bx, by, int(sizes[i]), score))
cap = int(opt("--max-lights", "100000"))
blobs = sorted(blobs, key=lambda b: -b[3])[:cap]
blobs = [b[:3] for b in blobs]
blobs.sort(key=lambda b: (b[0] - cx_home) ** 2 + (b[1] - cy_home) ** 2)   # outward from the circle
nL = len(blobs)
order = np.zeros((h2, w2)); core = np.zeros((h2, w2)); pool = np.zeros((h2, w2))
if nL:
    pts = np.array([[b[1], b[0]] for b in blobs])
    seeds = np.zeros((h2, w2), int)
    for k, (bx, by, _) in enumerate(blobs): seeds[int(by), int(bx)] = k + 1
    dist, (iy, ix) = nd.distance_transform_edt(seeds == 0, return_indices=True)
    nearest = seeds[iy, ix]
    within = dist < 34
    ordv = (1 + (254 * (nearest - 1) / max(1, nL - 1)).astype(int)) / 255.0
    order = np.where(within, ordv, 0)
    cmask = np.zeros((h2, w2))
    for (bx, by, sz) in blobs: cmask[int(by), int(bx)] = 1
    core = nd.gaussian_filter(nd.maximum_filter(cmask, 5), 2.0); core = np.clip(core / max(core.max(), 1e-6) * 1.6, 0, 1)
    pool = nd.gaussian_filter(cmask, 14); pool = np.clip(pool / max(pool.max(), 1e-6) * 2.2, 0, 1)
# Water: blue-turquoise hues, or (when given) a band of smooth reflective surface.
L = px @ [0.299, 0.587, 0.114]
smooth = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)) + np.abs(nd.sobel(L, axis=0)), 5) < float(opt("--smooth", "0.09"))
green = (h > 0.17) & (h < 0.45) & (sat > 0.3)
water = (h > 0.45) & (h < 0.62) & (sat > 0.25) & (v > 0.3)
band = opt("--water-band")
if band:
    y0, y1 = [float(t) for t in band.split(",")]
    hl, hh = [float(t) for t in opt("--water-hue", "0,1").split(",")]
    huemask = ((h >= hl) & (h <= hh)) if hl <= hh else ((h >= hl) | (h <= hh))
    water |= (Y >= y0 * h2) & (Y <= y1 * h2) & smooth & ~green & huemask & (sat > 0.12) & (v > 0.35)
    water = nd.binary_closing(water, iterations=3)
# Waterfalls: pale and streaked vertically (strong left-right contrast, little up-down), joined into the water.
mgx = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)), 5); mgy = nd.uniform_filter(np.abs(nd.sobel(L, axis=0)), 5)
falls = (v > 0.72) & (sat < 0.25) & (mgx > 1.3 * mgy) & (mgx > 0.04)
fl, nf = nd.label(nd.binary_closing(falls, structure=np.ones((5, 1)), iterations=2))
keepF = np.zeros(nf + 1, bool)
for i, o in enumerate(nd.find_objects(fl)):
    hh_, ww_ = o[0].stop - o[0].start, o[1].stop - o[1].start
    keepF[i + 1] = hh_ >= 8 and hh_ >= 1.1 * ww_
water |= keepF[fl] & falls
water = nd.binary_opening(water, iterations=1)
lab2, n2 = nd.label(water); sz2 = nd.sum(water, lab2, range(1, n2 + 1))
water = np.isin(lab2, np.where(sz2 > 80)[0] + 1)
waterA = np.asarray(Image.fromarray((water * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))).astype(float) / 255
out = np.dstack([order, core, pool, waterA]) * 255
Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA").save(f"{A}/{rid}-world-lights.png")
json.dump([{"u": b[0] / w2, "v": 1 - b[1] / h2, "size": b[2]} for b in blobs], open(f"{A}/{rid}-lights.json", "w"))
json.dump({"total": total, "height": H, "homeX0": x0, "homeW": W, "circleU": cu, "circleV": cv}, open(f"{A}/{rid}-layout.json", "w"))
print("lights", nL, "water", round(water.mean(), 3))
prev = opt("--preview")
if prev:
    vis = (px * 255 * 0.5)
    vis[..., 2] += waterA * 120; vis[..., 0] += core * 255; vis[..., 1] += core * 160
    Image.fromarray(vis.clip(0, 255).astype(np.uint8)).save(prev)
