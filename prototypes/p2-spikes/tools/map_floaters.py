#!/usr/bin/env python3
"""The world map breathes too (decision 142): the small islands and books floating around the Library are cut out
of the wide map (boxes given by eye, tools/life/map.json), the clouds behind them filled in, so MapScene can make
them bob, tilt and flap. Writes SpikeLab/Assets/map-float-<k>.png, map-floaters.json and the filled
world-map-wide.png (the original kept in tools/originals/). Then run tools/build_map.py --wide.
Run from prototypes/p2-spikes."""
import json, os, shutil
import numpy as np
from PIL import Image
from scipy import ndimage as nd

A = "SpikeLab/Assets"
os.makedirs("tools/originals", exist_ok=True)
orig = "tools/originals/world-map-wide.png"
if not os.path.exists(orig): shutil.copy(f"{A}/world-map-wide.png", orig)
P = np.asarray(Image.open(orig).convert("RGB")).astype(float); H, W, _ = P.shape
# Found automatically: anything fully surrounded by the sea of clouds (pale, soft, unsaturated, upper half) that
# isn't the big floating Library itself.
from PIL import ImageFilter
img = Image.fromarray(P.astype(np.uint8))
hsv = np.asarray(img.convert("HSV")).astype(float) / 255
Lm = P @ [0.299 / 255, 0.587 / 255, 0.114 / 255]
Yg = np.mgrid[0:H, 0:W][0] / H
softc = nd.uniform_filter(np.abs(nd.sobel(Lm, axis=1)) + np.abs(nd.sobel(Lm, axis=0)), 7) < 0.2
cloud = (Yg < 0.45) & (hsv[..., 1] < 0.42) & (hsv[..., 2] > 0.55) & softc
cloud = nd.binary_closing(nd.binary_opening(cloud, iterations=2), iterations=3)
lab, n = nd.label(~cloud)
sizes = nd.sum(~cloud, lab, range(1, n + 1))
boxes = []
def add(m, ys0, xs0):
    yy, xx = np.where(m)
    if len(yy) < 120: return
    y0, y1, x0, x1 = yy.min(), yy.max() + 1, xx.min(), xx.max() + 1
    sub = m[y0:y1, x0:x1]
    cx, cy = (xs0 + (x0 + x1) / 2) / W, (ys0 + (y0 + y1) / 2) / H
    kind = "book" if (0.4 < cx < 0.62 and 0.17 < cy < 0.33 and len(yy) < 2500) else "island"   # books fly by the Library
    boxes.append(((xs0 + x0) / W, (ys0 + y0) / H, (x1 - x0) / W, (y1 - y0) / H, kind, sub))
for i, o in enumerate(nd.find_objects(lab)):
    ys, xs = o
    if not (150 <= sizes[i] <= 9000): continue                       # specks out; the Library island out
    if ys.start < int(H * 0.06) or xs.start == 0 or ys.stop >= int(H * 0.46): continue   # (not the far sky's top)
    m = lab[o] == i + 1
    parts, k = nd.label(nd.binary_erosion(m, iterations=3))           # islands touching through haze: apart
    if k > 1:
        grown = nd.grey_dilation(parts, size=(9, 9)) * m
        for j in range(1, k + 1): add(grown == j, ys.start, xs.start)
    else:
        add(m, ys.start, xs.start)
filled = P.copy(); known = np.ones((H, W)); out = []
for k, (u, v, w, h, kind, m) in enumerate(boxes):
    x, y, bw, bh = int(round(u * W)), int(round(v * H)), m.shape[1], m.shape[0]
    full = np.zeros((H, W), bool); full[y:y + bh, x:x + bw] = m
    full = nd.binary_dilation(full, iterations=1)
    pad = 4; x0, y0, x1, y1 = max(0, x - pad), max(0, y - pad), min(W, x + bw + pad), min(H, y + bh + pad)
    alpha = nd.gaussian_filter(full.astype(float), 1.0)[y0:y1, x0:x1]
    Image.fromarray(np.dstack([P[y0:y1, x0:x1], np.clip(alpha * 1.3, 0, 1) * 255]).astype(np.uint8)).save(f"{A}/map-float-{k}.png")
    known[nd.binary_dilation(full, iterations=3)] = 0
    out.append({"file": f"map-float-{k}", "u": (x0 + x1) / 2 / W, "v": 1 - (y0 + y1) / 2 / H, "w": (x1 - x0) / W, "h": (y1 - y0) / H, "kind": kind})
hole = known == 0
acc = filled * known[..., None]; fill = np.zeros_like(filled)
for sig in (20, 8, 3):
    a = np.stack([nd.gaussian_filter(acc[..., c], sig) for c in range(3)], -1); wt = nd.gaussian_filter(known, sig)
    fill = np.where((wt > 0.02)[..., None], a / np.maximum(wt, 1e-6)[..., None], fill)
grain = nd.gaussian_filter(np.random.default_rng(3).normal(0, 3, (H, W)), 1)[..., None]
filled = np.where(hole[..., None], fill + grain, P)
Image.fromarray(np.clip(filled, 0, 255).astype(np.uint8)).save(f"{A}/world-map-wide.png")
json.dump(out, open(f"{A}/map-floaters.json", "w"), indent=1)
print("map floaters", len(out))
