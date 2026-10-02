#!/usr/bin/env python3
"""Cut a Codex painting out of its flat magenta (#FF00FF) background, keeping soft glowing edges: alpha from how
far each pixel is from magenta, and the color recovered by removing the magenta mixed into edge pixels.
Usage: magenta_key.py in.png out.png [crop box from the first image: x0,y0,x1,y1 as fractions] """
import sys
import numpy as np
from PIL import Image, ImageFilter

src, dst = sys.argv[1], sys.argv[2]
im = np.asarray(Image.open(src).convert("RGB")).astype(float) / 255
M = np.array([1.0, 0.0, 1.0])
# How much "magenta" is in a pixel: magenta has high red and blue and no green. Green is the giveaway.
g = im[..., 1]; rb = np.minimum(im[..., 0], im[..., 2])
magenta_ness = np.clip((rb - g) * 1.6, 0, 1)
a = np.clip(1.0 - magenta_ness, 0, 1)
a = np.where(a > 0.985, 1.0, a)
a = np.where(a < 0.04, 0.0, a)
safe = np.maximum(a, 0.05)[..., None]
rgb = np.clip((im - (1 - a)[..., None] * M) / safe, 0, 1)
# Transparent pixels take the color of the nearest character pixels (no dark or magenta fringe when filtered).
from scipy import ndimage as nd
pre = rgb * a[..., None]
blur_pre = np.dstack([nd.gaussian_filter(pre[..., k], 6) for k in range(3)])
blur_a = nd.gaussian_filter(a, 6)[..., None]
fill = np.clip(blur_pre / np.maximum(blur_a, 1e-4), 0, 1)
rgb = np.where((a < 0.05)[..., None], fill, rgb)
out = np.dstack([rgb, a]) * 255
img = Image.fromarray(out.astype(np.uint8), "RGBA")
# Trim to the character with a small margin, unless a box is given (so several expressions share one frame).
if len(sys.argv) > 3:
    x0, y0, x1, y1 = [float(v) for v in sys.argv[3].split(",")]
    W, H = img.size
    img = img.crop((int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H)))
img.save(dst)
bb = Image.fromarray((a * 255).astype(np.uint8)).getbbox()
W, H = Image.open(src).size
print("bbox fractions", [round(bb[0] / W, 3), round(bb[1] / H, 3), round(bb[2] / W, 3), round(bb[3] / H, 3)])
