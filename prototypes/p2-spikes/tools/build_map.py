#!/usr/bin/env python3
"""The living world map (iteration 2, decision 124): from Codex's map painting, a sharpened 2x copy (map-paint.png)
and the motion masks (map-motion.png: R water, G falling water, B fire and lanterns, A sky), the same channels as the
Sanctuary so the same shader brings it alive. Run from prototypes/p2-spikes after tools/depthmap made map-depth.png."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

A = "SpikeLab/Assets"
import sys
WIDE = "--wide" in sys.argv          # the map with Codex's side panels (tools/stitch_map.py)
src = Image.open(f"{A}/world-map-wide.png" if WIDE else f"{A}/world-map.png").convert("RGB")
W, H = src.size
K = 1.6 if WIDE else 2               # (the wide map at 1.6x keeps its texture within memory)
PIXEL = "--pixel" in sys.argv        # decision 149: snapped to a true pixel grid like the Sanctuary, 4× hard-edged
if PIXEL:
    src = src.resize((round(W / 2.2), round(H / 2.2)), Image.BOX).quantize(colors=72, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    W, H = src.size
    big = src.resize((W * 4, H * 4), Image.NEAREST)
    print("pixel map grid", W, "x", H)
elif "--native" in sys.argv:          # Codex's map exactly as painted: no grid, no palette, no sharpening (2026-10-15)
    big = src
else:
    big = src.resize((int(W * K), int(H * K)), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=1.6, percent=70, threshold=2))
big.save(f"{A}/map-paint.png")

px = np.asarray(src).astype(float) / 255
hsv = np.asarray(src.convert("HSV")).astype(float) / 255
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
d = np.asarray(Image.open(f"{A}/map-depth.png").convert("L").resize((W, H), Image.BILINEAR)).astype(float) / 255
Y = np.mgrid[0:H, 0:W][0] / H
L = px @ [0.299, 0.587, 0.114]
water = (h > 0.42) & (h < 0.62) & (s > 0.25) & (v > 0.3)
# The lake in the middle mirrors the sunset: pink and smooth (little texture), between the hills.
smooth = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)) + np.abs(nd.sobel(L, axis=0)), 5) < 0.08
lake = (Y > 0.42) & (Y < 0.58) & smooth & (v > 0.55) & ((h < 0.08) | (h > 0.85)) & (s > 0.15)
water |= lake
mgx = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)), 5); mgy = nd.uniform_filter(np.abs(nd.sobel(L, axis=0)), 5)
fall = (v > 0.74) & (s < 0.25) & (mgx > 1.3 * mgy) & (mgx > 0.04)
lab, n = nd.label(nd.binary_closing(fall, structure=np.ones((5, 1)), iterations=2))
keep = np.zeros(n + 1, bool)
for i, o in enumerate(nd.find_objects(lab)):
    hh, ww = o[0].stop - o[0].start, o[1].stop - o[1].start
    keep[i + 1] = hh >= 6 and hh >= 1.1 * ww
fall = keep[lab] & fall & (Y > 0.4)        # (higher up, pale streaks are clouds around the floating islands)
fire = (v > 0.97) & (h > 0.06) & (h < 0.16) & (s > 0.4)      # only the hottest cores: lanterns, the forge (not the golden road)
fl, n = nd.label(fire); sizes = nd.sum(fire, fl, range(1, n + 1))
keepf = np.zeros(n + 1, bool)
for i, o in enumerate(nd.find_objects(fl)):       # lanterns and the forge's fire are round; road segments are long
    hh, ww = o[0].stop - o[0].start, o[1].stop - o[1].start
    keepf[i + 1] = sizes[i] <= 60 and max(hh, ww) <= 2.0 * min(hh, ww) + 2
fire = keepf[fl]
sky = (Y < 0.16) & (d < 0.03) & (L > 0.35)
# The sea of clouds around the floating Library drifts too (pale, soft, unsaturated, in the upper half).
softc = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)) + np.abs(nd.sobel(L, axis=0)), 7) < 0.12
cloudsea = (Y < 0.45) & (s < 0.32) & (v > 0.62) & softc & ~water
cloudsea = nd.binary_opening(cloudsea, iterations=2)
sky |= cloudsea

def soft(m, grow, blur):
    im = Image.fromarray((m * 255).astype(np.uint8))
    if grow: im = im.filter(ImageFilter.MaxFilter(grow))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(blur)))
mask = np.dstack([soft(water, 0, 2), soft(fall, 3, 1.5), soft(fire, 5, 3), soft(sky, 0, 4)]).astype(np.uint8)
Image.fromarray(mask, "RGBA").save(f"{A}/map-motion.png")
print("water", round(water.mean(), 3), "fall", round(fall.mean(), 4), "fire", round(fire.mean(), 4), "sky", round(sky.mean(), 3))
