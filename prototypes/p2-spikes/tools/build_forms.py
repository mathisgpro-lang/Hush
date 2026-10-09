#!/usr/bin/env python3
"""The Flame's forms as game sprites (decision 152): Codex's pixel evolutions (docs/design/p29/px-stage-<name>.png)
keyed, snapped to the same pixel grid as the Spark (9 source px per art pixel), a fixed palette, 12x hard-edged.
Writes SpikeLab/Assets/px-<name>-keyed.png (+ -blink/-happy, the same until Codex paints faces). Run from
prototypes/p2-spikes."""
import os, numpy as np
from PIL import Image
D = "../../docs/design/p29"; A = "SpikeLab/Assets"
for n in ["flame", "blaze", "kindled", "radiant", "beyond"]:
    p = f"{D}/px-stage-{n}.png"
    if not os.path.exists(p): print(n, "not yet"); continue
    a = np.asarray(Image.open(p).convert("RGB")).astype(int)
    m = (a[..., 0] > 190) & (a[..., 1] < 90) & (a[..., 2] > 190)
    im = Image.fromarray(np.dstack([a.astype(np.uint8), np.where(m, 0, 255).astype(np.uint8)]), "RGBA")
    im = im.crop(im.getbbox())
    w, h = round(im.width / 9.0), round(im.height / 9.0)
    small = im.resize((w, h), Image.BOX)
    rgb = small.convert("RGB").quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    al = np.where(np.asarray(small)[..., 3] > 110, 255, 0).astype(np.uint8)
    out = Image.fromarray(np.dstack([np.asarray(rgb), al])).resize((w * 12, h * 12), Image.NEAREST)
    for f in ["keyed", "blink", "happy"]: out.save(f"{A}/px-{n}-{f}.png")
    print(n, (w, h))
