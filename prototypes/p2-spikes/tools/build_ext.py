#!/usr/bin/env python3
"""The ground below each pixel world (decision 160). Codex painted every world taller (docs/design/p29/px-<id>-tall.png:
the original, untouched, on top, the scene continued below). This cuts out what lies below the part the app already
shows, on the same art-pixel grid and in the same palette as the world's painting, so the seam is invisible:
  <asset>-ext.png   at true size (one texel per art pixel), drawn by the scene right under the painting.
Run from prototypes/p2-spikes:  python3 tools/build_ext.py [world ...]"""
import sys, os
import numpy as np
from PIL import Image

A = "SpikeLab/Assets"; D = "../../docs/design/p29"; T = 0.40
# world: (asset name, the crop the build used: Sanctuary in build_pixel_world.py, realms --circle in pixel_realms.sh)
WORLDS = {"sanctuary": ("px-home", ("sanctuary", 0.5, 0.443)),
          "library": ("library-world", ("realm", 0.5, 0.392)), "stillwater": ("stillwater-world", ("realm", 0.5, 0.413)),
          "highlands": ("highlands-world", ("realm", 0.5, 0.413)), "wilds": ("wilds-world", ("realm", 0.5, 0.39)),
          "forge": ("forge-world", ("realm", 0.5, 0.408)), "grove": ("grove-world", ("realm", 0.5, 0.425))}

def crop_box(kind, cu, cv, sw, sh):
    if kind == "sanctuary":
        return int((2 * cu - 1) * sw), 0, sw, int(sh - (cv - T) / (1 - T) * sh)
    left = max(0.0, 2 * cu - 1); right = max(0.0, 1 - 2 * cu)
    top = max(0.0, 1 - cv / T) if cv < T else 0.0
    bottom = (cv - T) / (1 - T) if cv > T else 0.0
    return int(left * sw), int(top * sh), int(sw - right * sw), int(sh - bottom * sh)

for w in (sys.argv[1:] or WORLDS):
    asset, (kind, cu, cv) = WORLDS[w]
    tall_p = f"{D}/px-{w}-tall.png"
    if not os.path.exists(tall_p): print(w, ": no tall painting yet"); continue
    orig = Image.open(f"{D}/px-{w}.png"); tall = Image.open(tall_p).convert("RGB")
    if tall.width != orig.width:                       # (keep the original's scale if Codex changed the width)
        tall = tall.resize((orig.width, round(tall.height * orig.width / tall.width)), Image.LANCZOS)
    l, t, r, b = crop_box(kind, cu, cv, *orig.size)
    paint = Image.open(f"{A}/{asset}-paint.png").convert("RGB")
    W, H = paint.size
    sy = H / (b - t)                                   # art pixels per source pixel (vertical)
    ext_src = tall.crop((l, b, r, tall.height))
    eh = round(ext_src.height * sy)
    small = ext_src.resize((W, eh), Image.LANCZOS)
    # The painting's own palette (≤72 colours), so the ground is drawn with exactly the same colours.
    cols = np.unique(np.asarray(paint).reshape(-1, 3), axis=0)
    if len(cols) > 256:                                # a painting with no pixel filter: the strip as painted
        ext = small
    else:                                              # (a pixel-filtered painting: the same palette)
        pal = Image.new("P", (1, 1)); flat = cols.flatten().tolist(); pal.putpalette(flat + flat[:3] * (256 - len(cols)))
        ext = small.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    ext.save(f"{A}/{asset}-ext.png")
    # What moves in it, as the scene's shader reads it: water ripples, waterfalls fall, flames flicker.
    hsv = np.asarray(ext.convert("HSV")).astype(float) / 255
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    fall = (v > 0.78) & (s < 0.28) & (h > 0.45) & (h < 0.65)
    water = (h > 0.42) & (h < 0.6) & (s > 0.3) & (v > 0.3) & ~fall
    fire = (v > 0.92) & (h > 0.07) & (h < 0.16) & (s > 0.45)
    z = np.zeros_like(water)
    if kind == "sanctuary":     # px-home-motion layout: R water, G falling water, B flames, A sky
        m = np.dstack([water, fall, fire, z])
        Image.fromarray(m.astype(np.uint8) * 255, "RGBA").save(f"{A}/{asset}-ext-motion.png")
    else:                       # <id>-world-lights layout: RGB lantern light (none down here), A water
        m = np.dstack([z, z, z, water | fall])
        Image.fromarray(m.astype(np.uint8) * 255, "RGBA").save(f"{A}/{asset}-ext-lights.png")
    print(f"{w}: {asset}-ext.png {W}x{eh} (painting {W}x{H}, {len(cols)} colours)")
