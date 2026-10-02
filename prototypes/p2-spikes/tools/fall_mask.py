#!/usr/bin/env python3
"""Rebuild the falling-water channel (G) of world-motion.png from the streaks of real waterfalls only.
Waterfalls are pale AND streaked vertically (strong left-right contrast, little up-down contrast); painted mist is
pale but smooth, so it is left alone (animating it as water turned it into white fog). Run from prototypes/p2-spikes."""
import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

A = "SpikeLab/Assets"
w = Image.open(f"{A}/world-paint.png").convert("RGB")
W, H = w.size
s = w.resize((W // 2, H // 2)); px = np.asarray(s).astype(float) / 255
hsv = np.asarray(s.convert("HSV")).astype(float) / 255
v, sat = hsv[..., 2], hsv[..., 1]
L = px @ [0.299, 0.587, 0.114]
mgx = nd.uniform_filter(np.abs(nd.sobel(L, axis=1)), 7)
mgy = nd.uniform_filter(np.abs(nd.sobel(L, axis=0)), 7)
fall = (v > 0.74) & (sat < 0.22) & (mgx > 1.3 * mgy) & (mgx > 0.04)
fall = nd.binary_opening(fall, iterations=1)
lab, n = nd.label(nd.binary_closing(fall, structure=np.ones((5, 1)), iterations=2))
keep = np.zeros(n + 1, bool)
for i, o in enumerate(nd.find_objects(lab)):
    hgt, wid = o[0].stop - o[0].start, o[1].stop - o[1].start
    keep[i + 1] = hgt >= 8 and hgt >= 1.1 * wid
fall = keep[lab] & fall
g = Image.fromarray((fall * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.5))
m = np.asarray(Image.open(f"{A}/world-motion.png")).copy()
m[..., 1] = np.asarray(g.resize((m.shape[1], m.shape[0]), Image.BILINEAR))
Image.fromarray(m, "RGBA").save(f"{A}/world-motion.png")
if len(sys.argv) > 1:
    vis = (px * 255 * 0.5).astype(np.uint8); vis[fall] = [0, 255, 0]
    Image.fromarray(vis).save(sys.argv[1])
print("falling water", round(fall.mean(), 4))
