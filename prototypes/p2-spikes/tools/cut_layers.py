#!/usr/bin/env python3
"""Cut the stitched Sanctuary world into living layers (decision 121): the sky (far), the sea (middle) and the land
(near), so each can move on its own. Inputs: SpikeLab/Assets/world-paint.png + world-depth.png, and Codex's clean
plates docs/design/v2/plate-sky.png and plate-sea.png (same framing as the world).
Outputs into SpikeLab/Assets:
  world-land.png      the world with alpha = 0 where the sky or the open sea show (foam and waterfalls stay land)
  world-sky.png       the sky plate (+ world-sky-base.png, its blurred light, so the shader can drift the clouds
                      while the sun's glow stays put)
  world-sea.png       the sea plate, its horizon aligned to the world's, alpha = 0 above the horizon
  world-layers.json   the horizon row and the sea's depth curve (relief per row) for the scene
Run from prototypes/p2-spikes: python3 tools/cut_layers.py"""
import json
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

A = "SpikeLab/Assets"
D = "../../docs/design/v2"
world = Image.open(f"{A}/world-paint.png").convert("RGB")
W, H = world.size
WORLD_HZ = 382          # the world's horizon row (checked by eye against the sun and the far mountains)
SEA_HZ = 370            # the sea plate's horizon row

# ---- Work at half size for the classification, then upsample the masks smoothly. ----
w2, h2 = W // 2, H // 2
im = np.asarray(world.resize((w2, h2), Image.LANCZOS)).astype(float) / 255
d = np.asarray(Image.open(f"{A}/world-depth.png").convert("L").resize((w2, h2), Image.BILINEAR)).astype(float) / 255
hsv = np.asarray(Image.fromarray((im * 255).astype(np.uint8)).convert("HSV")).astype(float) / 255
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
r, g, b = im[..., 0], im[..., 1], im[..., 2]
lum = im @ [0.299, 0.587, 0.114]
Y, X = np.mgrid[0:h2, 0:w2]
hz = WORLD_HZ // 2

# ---- The open sea: pixels lying on the sea's smooth depth surface, not foliage, not foam, joined to the open water.
turq = (h > 0.42) & (h < 0.66) & (s > 0.25) & (v > 0.3)
seed = turq & (X > w2 * 0.55) & (Y > h2 * 0.35)
rows, depths = [], []
for y in range(h2):
    m = seed[y]
    if m.sum() > 30:
        rows.append(y); depths.append(np.percentile(d[y][m], 40))
fit = np.polyfit(rows, depths, 2)
seaD = np.clip(np.polyval(fit, np.arange(h2)), 0, 1); seaD[:hz] = 0
# Far rows: the fitted curve is extrapolated there, so measure the sea's level in the open water of each row instead.
for y in range(hz, int(h2 * 0.4)):
    row = d[y, int(w2 * 0.55):int(w2 * 0.85)]
    seaD[y] = np.percentile(row, 25)
dev = d - seaD[:, None]
nearRow = np.clip((Y - hz) / (h2 - hz), 0, 1)
tol = 0.006 + 0.03 * nearRow ** 2       # far away the rocks stand only a few depth steps above the sea
foliage = ((h > 0.17) & (h < 0.42) & (s > 0.3)) | ((h > 0.7) & (h < 0.85) & (s > 0.25))
white = (v > 0.82) & (s < 0.18)
# Near the horizon the sea is sunlit (pink and gold, not turquoise): there, anything not dark and not a mountain.
band = (Y >= hz) & (Y < hz + 40)
rock = (lum < 0.42) & ~turq            # dark stone: near the horizon its depth is almost the sea's, colour decides
cand = (dev < np.maximum(tol, 0.012 * (nearRow > 0.35)) ) & (Y >= hz) & ~foliage & ~white & ~rock
cand |= band & (dev < 0.006) & (lum > 0.42) & ~foliage & ~(((r - b) < 0.22) | (lum < 0.47))
lab, _ = nd.label(cand)
seeds2 = (seed | (turq & (Y > h2 * 0.55) & (dev < 0.05)) | (band & (X > w2 * 0.5) & cand)) & cand
keep = np.unique(lab[seeds2]); keep = keep[keep > 0]
sea = np.isin(lab, keep)
sea = nd.binary_closing(sea, iterations=2) & ~white
sea = nd.binary_opening(sea, iterations=1)
# Small specks of foam or glints inside the sea become sea (rocks are bigger and stay land).
holes = nd.binary_fill_holes(sea) & ~sea
hl, n = nd.label(holes)
sizes = nd.sum(holes, hl, range(1, n + 1))
bright = nd.mean(lum, hl, range(1, n + 1))
small = np.isin(hl, np.where((sizes < 60) | ((sizes < 1500) & (bright > 0.55)))[0] + 1)   # foam patches; rocks are dark
sea |= small

# ---- The sky: far (no depth), above the horizon, minus the far mountains (purple, darker than the sunset sky).
mountain = ((r - b) < 0.22) | (lum < 0.47)
near_hz = Y > hz - 45
sky = (Y < hz) & (d < 0.035) & ~(near_hz & mountain)
sky |= (Y < hz - 45) & (d < 0.02)
# Refine the skyline by colour: stone and leaves are darker and less pink than the sky there.
landish = (lum < 0.38) | foliage
sky &= ~(landish & (d > 0.008))
sky = nd.binary_opening(sky, iterations=1)
sky = nd.binary_closing(sky, iterations=1) & (Y < hz)
# Isolated small islands of "sky" low down are paint, not sky.
sl, n = nd.label(sky)
sizes = nd.sum(sky, sl, range(1, n + 1))
sky = np.isin(sl, np.where(sizes > 150)[0] + 1)

def up(mask):
    """Half-size mask → full size, smooth edges (a soft 0…1 alpha the shader thresholds)."""
    m = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    return np.asarray(m.resize((W, H), Image.BILINEAR)).astype(float) / 255

hole = np.maximum(up(sea), up(sky))
land_alpha = 1 - hole
paint = np.asarray(world)
land = Image.fromarray(np.dstack([paint, (land_alpha * 255).astype(np.uint8)]), "RGBA")
# The phone shows the painting magnified about 1.7×: doubling it here with a high-quality resampling and a gentle
# sharpening keeps it crisp (the GPU's own magnification is softer).
land = land.resize((W * 2, H * 2), Image.LANCZOS)
rgb2 = land.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1.6, percent=70, threshold=2))
land = Image.merge("RGBA", (*rgb2.split(), land.split()[3]))
land.save(f"{A}/world-land.png")

# The land's motion mask: its sky channel (A) now only marks the real sky (cut out of the land). The old colour-based
# sky mask also caught pale mist and far rocks, which the daylight grade turned into white clouds on the land.
mo = Image.open(f"{A}/world-motion.png"); mw, mh = mo.size
mo_np = np.asarray(mo).copy()
mo_np[..., 3] = np.asarray(Image.fromarray((sky * 255).astype(np.uint8)).resize((mw, mh), Image.BILINEAR))
Image.fromarray(mo_np, "RGBA").save(f"{A}/world-motion.png")

# ---- The sky plate (+ its blurred light).
sky_plate = Image.open(f"{D}/plate-sky.png").convert("RGB").resize((W, H), Image.LANCZOS)
sky_plate.save(f"{A}/world-sky.png")
sky_plate.filter(ImageFilter.GaussianBlur(40)).save(f"{A}/world-sky-base.png")

# ---- The sea plate, its horizon moved onto the world's, transparent above it.
sp = np.asarray(Image.open(f"{D}/plate-sea.png").convert("RGB").resize((W, H), Image.LANCZOS)).astype(float)
out = np.zeros_like(sp)
src = SEA_HZ + (np.arange(H) - WORLD_HZ) * (H - SEA_HZ) / (H - WORLD_HZ)     # world row → plate row (below horizon)
src = np.clip(src, 0, H - 1)
lo = np.floor(src).astype(int); hi = np.minimum(lo + 1, H - 1); f = (src - lo)[:, None, None]
out = sp[lo] * (1 - f) + sp[hi] * f
alpha = np.clip((np.arange(H) - (WORLD_HZ - 2)) / 3.0, 0, 1)[:, None] * np.ones((1, W))
Image.fromarray(np.dstack([out.clip(0, 255).astype(np.uint8), (alpha * 255).astype(np.uint8)]), "RGBA").save(f"{A}/world-sea.png")

# ---- The sea's depth per row (0…1, white = near) for its relief mesh, from v = 0 (bottom) to 1 (top), 64 samples.
curve = []
for k in range(64):
    vv = k / 63
    y = int((1 - vv) * (h2 - 1))
    curve.append(float(seaD[y]) if y >= hz else 0.0)
json.dump({"horizonV": 1 - WORLD_HZ / H, "seaDepth": curve}, open(f"{A}/world-layers.json", "w"))

# A preview for checking the cut.
vis = (np.asarray(world.resize((w2, h2))).astype(float) * 0.45)
vis[sea] = vis[sea] * 0.4 + np.array([0, 230, 255]) * 0.6
vis[sky] = vis[sky] * 0.4 + np.array([255, 60, 200]) * 0.6
import os, sys
Image.fromarray(vis.astype(np.uint8)).save(os.environ.get("PREVIEW", "layers-preview.png"))
print("sea", round(sea.mean(), 3), "sky", round(sky.mean(), 3), "horizon v", round(1 - WORLD_HZ / H, 4))
