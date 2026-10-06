#!/usr/bin/env python3
"""Make a realm's painting breathe (decision 142, docs/plan-2.0/p27-living-worlds.md), from the painting itself:
  1. Floaters: things floating in the sky (books, small islands) are cut out as their own sprites, so they really
     float, drift and flap; the sky behind them is filled in (a soft diffusion fill: skies are soft).
     Found automatically (anything fully surrounded by sky in the lights map's sky band) plus boxes given by eye in
     tools/life/<id>.json {"floaters": [[u, v, w, h, "book"|"island"], ...]} (u, v = top-left, fractions).
  2. The life map <id>-world-life.png (half size): R = foliage (sways with the wind), G = cloth (banners wave),
     B = 0, A = 1. Read by the realm shader.
Writes SpikeLab/Assets/<id>-float-<k>.png, <id>-floaters.json, <id>-world-life.png, and the filled painting
(<id>-world-paint.png; the original is kept once in tools/originals/). Run from prototypes/p2-spikes."""
import json, os, sys, shutil
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

rid = sys.argv[1]
A = "SpikeLab/Assets"
os.makedirs("tools/originals", exist_ok=True)
orig = f"tools/originals/{rid}-world-paint.png"
if not os.path.exists(orig): shutil.copy(f"{A}/{rid}-world-paint.png", orig)
paint = Image.open(orig).convert("RGB"); W, H = paint.size
P = np.asarray(paint).astype(float)
L = np.asarray(Image.open(f"{A}/{rid}-world-lights.png").convert("RGBA").resize((W, H), Image.NEAREST)).astype(float) / 255
aMap = L[..., 3]
sky = (aMap > 0.3) & (aMap < 0.7)
water = aMap > 0.72
hints = json.load(open(f"tools/life/{rid}.json")) if os.path.exists(f"tools/life/{rid}.json") else {}

# ---- 1. Floaters ----
boxes = []
land = ~sky
lab, n = nd.label(land)
sizes = nd.sum(land, lab, range(1, n + 1))
big = int(np.argmax(sizes)) + 1 if n else 0
for i, o in enumerate(nd.find_objects(lab) if hints.get("auto") else []):   # only where things really float
    if i + 1 == big or not (120 <= sizes[i] <= 14000): continue
    m = lab[o] == i + 1
    boxes.append((o[1].start, o[0].start, o[1].stop - o[1].start, o[0].stop - o[0].start, "book", m))
def matte_by_eye(x, y, w, h):
    """Inside a box drawn by eye: the object is what differs from the sky around the box's edge."""
    crop = P[y:y + h, x:x + w]
    edge = np.concatenate([crop[0], crop[-1], crop[:, 0], crop[:, -1]])
    skyc = np.median(edge, 0)
    d = np.sqrt(((crop - skyc) ** 2).sum(-1))
    m = d > max(28, np.percentile(d, 40))
    m = nd.binary_opening(m, iterations=1); m = nd.binary_fill_holes(nd.binary_closing(m, iterations=2))
    lb, k = nd.label(m)
    if k: m = lb == (np.argmax(nd.sum(m, lb, range(1, k + 1))) + 1)
    return m
for u, v, w, h, kind in hints.get("floaters", []):
    x, y, bw, bh = int(u * W), int(v * H), int(w * W), int(h * H)
    boxes.append((x, y, bw, bh, kind, matte_by_eye(x, y, bw, bh)))

filled = P.copy()
known = np.ones((H, W))
out = []
for k, (x, y, w, h, kind, m) in enumerate(boxes):
    pad = 6
    x0, y0, x1, y1 = max(0, x - pad), max(0, y - pad), min(W, x + w + pad), min(H, y + h + pad)
    full = np.zeros((H, W), bool); full[y:y + h, x:x + w] = m
    full = nd.binary_dilation(full, iterations=2)
    alpha = nd.gaussian_filter(full.astype(float), 1.2)[y0:y1, x0:x1]
    sprite = np.dstack([P[y0:y1, x0:x1], np.clip(alpha * 1.3, 0, 1) * 255]).astype(np.uint8)
    Image.fromarray(sprite, "RGBA").save(f"{A}/{rid}-float-{k}.png")
    known[nd.binary_dilation(full, iterations=4)] = 0
    out.append({"file": f"{rid}-float-{k}", "u": (x0 + x1) / 2 / W, "v": 1 - (y0 + y1) / 2 / H,
                "w": (x1 - x0) / W, "h": (y1 - y0) / H, "kind": kind})
# Fill what the floaters covered: a normalised blur from the sky around it, coarse to fine, plus a little grain.
if out:
    hole = known == 0
    acc = filled * known[..., None]; wsum = known.copy()
    fill = np.zeros_like(filled)
    for sig in (24, 10, 4):
        a = np.stack([nd.gaussian_filter(acc[..., c], sig) for c in range(3)], -1)
        wt = nd.gaussian_filter(wsum, sig)
        est = a / np.maximum(wt, 1e-6)[..., None]
        fill = np.where((wt > 0.02)[..., None], est, fill)
    grain = nd.gaussian_filter(np.random.default_rng(7).normal(0, 3, (H, W)), 1)[..., None]
    filled = np.where(hole[..., None], fill + grain, filled)
Image.fromarray(np.clip(filled, 0, 255).astype(np.uint8)).save(f"{A}/{rid}-world-paint.png")
json.dump(out, open(f"{A}/{rid}-floaters.json", "w"), indent=1)

# ---- 2. The life map (half size) ----
s = paint.resize((W // 2, H // 2), Image.LANCZOS)
hsv = np.asarray(s.convert("HSV")).astype(float) / 255
h_, sat, val = hsv[..., 0], hsv[..., 1], hsv[..., 2]
sky2 = np.asarray(Image.fromarray(sky.astype(np.uint8) * 255).resize(s.size, Image.NEAREST)) > 0
water2 = np.asarray(Image.fromarray(water.astype(np.uint8) * 255).resize(s.size, Image.NEAREST)) > 0
rgb2 = np.asarray(s).astype(float)
green = (h_ > 0.16) & (h_ < 0.45) & (sat > 0.25) & (val > 0.12) & (rgb2[..., 1] > rgb2[..., 0] * 0.97)   # real greens, not gold
flowers = (h_ > 0.68) & (h_ < 0.92) & (sat > 0.18) & (val > 0.35)            # wisteria, lilac blossoms
if hints.get("grass"):                                                     # golden grass and autumn leaves
    green |= (h_ > 0.09) & (h_ <= 0.16) & (sat > 0.3) & (val > 0.2) & (rgb2[..., 1] > rgb2[..., 0] * 0.8)
if not hints.get("flowers"): flowers = np.zeros_like(flowers)        # only worlds that have blossoms (wisteria, lotus)
depth2 = np.asarray(Image.open(f"{A}/{rid}-world-depth.png").convert("L").resize(s.size, Image.BILINEAR)).astype(float) / 255
near = depth2 > np.percentile(depth2, 35)                                  # far hills and mountains stay still
foliage = (green | flowers) & ~sky2 & ~water2 & near
foliage = nd.binary_opening(foliage, iterations=1)
blue = (h_ > 0.55) & (h_ < 0.7) & (sat > 0.35) & (val > 0.18) & (val < 0.75)
red = ((h_ < 0.02) | (h_ > 0.95)) & (sat > 0.5) & (val > 0.25) & (val < 0.8)
cloth = np.zeros_like(blue)
cl, cn = nd.label(nd.binary_closing(blue | red, iterations=2))
for i, o in enumerate(nd.find_objects(cl)):
    hh, ww = o[0].stop - o[0].start, o[1].stop - o[1].start
    if hh >= 30 and hh >= 2.2 * ww: cloth[o] |= cl[o] == i + 1                # tall hanging banners
def soft(m, g): return nd.gaussian_filter(m.astype(float), g)
life = np.dstack([np.clip(soft(foliage, 1.2) * 1.4, 0, 1), np.clip(soft(cloth, 1.5) * 1.3, 0, 1),
                  np.zeros(foliage.shape), np.ones(foliage.shape)])
Image.fromarray((life * 255).astype(np.uint8), "RGBA").save(f"{A}/{rid}-world-life.png")
print(rid, "floaters", len(out), "foliage", round(foliage.mean(), 3), "cloth", round(cloth.mean(), 4))
