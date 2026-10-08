#!/usr/bin/env python3
"""The pixel Sanctuary (decision 149): Codex's pixel-art Sanctuary, cleaned into true pixel art (snapped to its
native grid, a fixed palette, enlarged with hard edges), then everything the Sanctuary scene needs:
  px-home-paint.png   the art (native grid × 4)
  px-home-depth.png   relief (tools/depthmap)
  px-home-motion.png  R water, G falling water, B flames, A sky (what moves)
  px-home-features.json  the stone circle's centre (where your Spark lives), grid size
And the pixel Spark (px-spark-keyed/blink/happy.png) from Codex's pixel Spark.
Run from prototypes/p2-spikes."""
import json, subprocess
import numpy as np
from PIL import Image
from scipy import ndimage as nd

A = "SpikeLab/Assets"; D = "../../docs/design/p29"
SRC_PX = 2.2                     # source pixels per art pixel (finer than Codex's ~3.5: clearer, Mathis 2026-10-07)
UP = 4                           # the texture holds each art pixel as UP×UP texels (crisp under filtering)

def clean(img, px, colors):
    w, h = round(img.width / px), round(img.height / px)
    small = img.resize((w, h), Image.BOX)
    if small.mode == "RGBA":
        rgb = small.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
        a = np.asarray(small)[..., 3]
        out = np.dstack([np.asarray(rgb), np.where(a > 110, 255, 0)]).astype(np.uint8)
        return Image.fromarray(out, "RGBA")
    return small.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")

# ---- The world ----
src = Image.open(f"{D}/px-sanctuary.png").convert("RGB")
art = clean(src, SRC_PX, 72)
W, H = art.size
art.resize((W * UP, H * UP), Image.NEAREST).save(f"{A}/px-home-paint.png")
print("pixel world", W, "x", H, "art pixels")

subprocess.run(["./tools/depthmap", "tools/models/DepthAnythingV2SmallF16.mlmodelc", f"{A}/px-home-paint.png", f"{A}/px-home-depth.png"], check=True, capture_output=True)

px = np.asarray(art).astype(float) / 255
hsv = np.asarray(art.convert("HSV")).astype(float) / 255
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
Y = np.mgrid[0:H, 0:W][0] / H
d = np.asarray(Image.open(f"{A}/px-home-depth.png").convert("L").resize((W, H), Image.BILINEAR)).astype(float) / 255
water = (h > 0.42) & (h < 0.6) & (s > 0.3) & (v > 0.3) & (Y > 0.22)
fall = (v > 0.78) & (s < 0.28) & (h > 0.45) & (h < 0.65)
fl, n = nd.label(fall)
keep = np.zeros(n + 1, bool)
for i, o in enumerate(nd.find_objects(fl)):
    keep[i + 1] = (o[0].stop - o[0].start) >= 1.6 * (o[1].stop - o[1].start) and (o[0].stop - o[0].start) >= 6
fall = keep[fl]
water &= ~fall
fire = (v > 0.92) & (h > 0.07) & (h < 0.16) & (s > 0.45)
sky = (Y < 0.24) & ((h < 0.12) | (h > 0.7)) & (s > 0.2) & ~water
sky &= (d < np.percentile(d, 25))
mask = np.dstack([water, fall, fire, sky]).astype(np.uint8) * 255
Image.fromarray(mask, "RGBA").save(f"{A}/px-home-motion.png")   # (at the true pixel size)

# The stone circle: the biggest warm, bright, round patch near the middle.
warm = (h > 0.06) & (h < 0.15) & (s > 0.35) & (v > 0.75) & (Y > 0.35) & (Y < 0.7)
lab, n = nd.label(nd.binary_closing(warm, iterations=2))
sizes = nd.sum(warm, lab, range(1, n + 1))
cy, cx = nd.center_of_mass(lab == (int(np.argmax(sizes)) + 1)) if n else (H / 2, W / 2)
json.dump({"circleU": 0.52, "circleV": 0.488, "gridW": W, "gridH": H}, open(f"{A}/px-home-features.json", "w"))
print("circle", round(cx / W, 3), round(1 - cy / H, 3), "water", round(water.mean(), 3), "fall", round(fall.mean(), 4), "fire", round(fire.mean(), 4), "sky", round(sky.mean(), 3))

# ---- The Spark ----
sp = Image.open(f"{D}/px-spark.png").convert("RGB")
a = np.asarray(sp).astype(float)
mag = (a[..., 0] > 200) & (a[..., 1] < 80) & (a[..., 2] > 200)
rgba = Image.fromarray(np.dstack([a.astype(np.uint8), np.where(mag, 0, 255).astype(np.uint8)]), "RGBA")
rgba = rgba.crop(rgba.getbbox())
spark = clean(rgba, 9.0, 28)
sw, sh = spark.size
big = spark.resize((sw * 12, sh * 12), Image.NEAREST)
big.save(f"{A}/px-spark-keyed.png")
# Blink and happy: the eyes closed into a curved line (made from the art itself, until Codex's frames).
arr = np.asarray(spark).copy()
op = arr[..., 3] > 0
lum = arr[..., :3].astype(float).mean(-1)
eyes = op & (lum < 95) & (np.mgrid[0:sh, 0:sw][0] > sh * 0.45) & (np.mgrid[0:sh, 0:sw][0] < sh * 0.8)
skin = np.median(arr[op & (lum > 170)][:, :3], 0).astype(np.uint8)
dark = np.median(arr[op & (lum < 60)][:, :3], 0).astype(np.uint8) if (op & (lum < 60)).any() else np.array([90, 40, 10], np.uint8)
blink = arr.copy(); ys, xs = np.where(eyes)
if len(ys):
    blink[eyes] = np.append(skin, 255)
    lab_e, ne = nd.label(nd.binary_dilation(eyes, iterations=1))
    for i in range(1, ne + 1):
        yy, xx = np.where(lab_e == i)
        mid = int(np.round(np.percentile(yy, 65)))
        for x in range(xx.min(), xx.max() + 1): blink[mid, x] = np.append(dark, 255)
Image.fromarray(blink, "RGBA").resize((sw * 12, sh * 12), Image.NEAREST).save(f"{A}/px-spark-blink.png")
happy = blink.copy()
Image.fromarray(happy, "RGBA").resize((sw * 12, sh * 12), Image.NEAREST).save(f"{A}/px-spark-happy.png")
print("pixel spark", sw, "x", sh)
