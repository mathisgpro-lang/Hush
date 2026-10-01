#!/usr/bin/env python3
"""Painted-rig assets (P2 plan §B.6b, route C). Throwaway.

  rig_assets.py placeholder <outdir>            draw simple placeholder layers (to build the rig before the art exists)
  rig_assets.py keyout <in.png> <outdir> <prefix> [--min-area N]
        key out a flat magenta (#FF00FF) background, split the picture into its separate parts
        (connected regions), trim each, save <prefix>-<n>.png sorted top-to-bottom then left-to-right,
        and write <prefix>.json with each part's box in the source image.
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFilter


def placeholder(outdir):
    os.makedirs(outdir, exist_ok=True)
    W = 512
    # Body: a round fluffy-ish blob with a warm radial gradient and a glowing core.
    body = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    px = body.load()
    cx, cy, r = W / 2, W * 0.58, W * 0.36
    for y in range(W):
        for x in range(W):
            d = math.hypot((x - cx) / r, (y - cy) / (r * 1.08))
            if d < 1:
                core = max(0.0, 1 - math.hypot(x - cx, y - (cy + r * 0.25)) / (r * 0.45))
                rr = 255
                g = int(120 + 90 * (1 - d) + 60 * core)
                b = int(30 + 40 * core + 120 * core ** 3)
                a = int(255 * min(1, (1 - d) * 8))
                px[x, y] = (rr, min(g, 255), min(b, 255), a)
    body.save(os.path.join(outdir, "body.png"))
    # Five flame tongues, the center one tallest.
    for i, h in enumerate((0.55, 0.75, 1.0, 0.75, 0.55)):
        t = Image.new("RGBA", (160, 320), (0, 0, 0, 0))
        d = ImageDraw.Draw(t)
        top = 320 * (1 - h)
        d.polygon([(20, 319), (80, top), (140, 319)], fill=(255, 190, 70, 255))
        d.polygon([(50, 319), (80, top + (319 - top) * 0.35), (110, 319)], fill=(255, 235, 150, 255))
        t.filter(ImageFilter.GaussianBlur(2)).save(os.path.join(outdir, f"tongue-{i}.png"))
    # Eyes (open/closed) and mouths.
    def eye(closed):
        e = Image.new("RGBA", (96, 112), (0, 0, 0, 0)); d = ImageDraw.Draw(e)
        if closed:
            d.arc((10, 30, 86, 90), 200, 340, fill=(70, 30, 12, 255), width=9)
        else:
            d.ellipse((8, 8, 88, 104), fill=(255, 250, 240, 255))
            d.ellipse((20, 20, 84, 100), fill=(70, 34, 14, 255))
            d.ellipse((30, 30, 50, 50), fill=(255, 255, 255, 255)); d.ellipse((60, 70, 70, 80), fill=(255, 255, 255, 230))
        return e
    eye(False).save(os.path.join(outdir, "eye-open.png")); eye(True).save(os.path.join(outdir, "eye-closed.png"))
    shapes = {"smile": [(10, 10, 110, 70), 20, 160], "joy": None, "o": None, "flat": None, "talk": None}
    for name in shapes:
        m = Image.new("RGBA", (120, 90), (0, 0, 0, 0)); d = ImageDraw.Draw(m)
        if name == "smile": d.arc((15, 0, 105, 60), 20, 160, fill=(110, 35, 15, 255), width=8)
        elif name == "joy": d.chord((20, 5, 100, 80), 0, 180, fill=(140, 40, 25, 255))
        elif name == "o": d.ellipse((45, 25, 75, 60), fill=(120, 35, 20, 255))
        elif name == "flat": d.line((30, 40, 90, 40), fill=(110, 35, 15, 255), width=8)
        else: d.ellipse((35, 20, 85, 60), fill=(130, 38, 22, 255))
        m.save(os.path.join(outdir, f"mouth-{name}.png"))
    print("placeholder layers written to", outdir)


def keyout(src, outdir, prefix, min_area=400):
    os.makedirs(outdir, exist_ok=True)
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    # Alpha from distance to magenta, with despill so pink fringes don't remain on soft glowing edges.
    alpha = Image.new("L", (w, h), 0)
    ap = alpha.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            mag = min(r, b) - g                      # high for magenta-ish pixels
            a = 255 if mag < 40 else (0 if mag > 150 else int(255 * (150 - mag) / 110))
            ap[x, y] = a
            if 0 < a < 255:                          # despill: pull magenta out of edge pixels
                spill = max(0, min(r, b) - g) * (1 - a / 255)
                px[x, y] = (int(max(0, r - spill)), g, int(max(0, b - spill)), a)
            else:
                px[x, y] = (r, g, b, a)
    # Connected regions on a slightly dilated mask, so a part's soft glow stays with it.
    mask = alpha.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(5))
    mp = mask.load()
    seen = bytearray(w * h)
    parts = []
    for y0 in range(h):
        for x0 in range(w):
            if mp[x0, y0] == 0 or seen[y0 * w + x0]:
                continue
            stack = [(x0, y0)]; seen[y0 * w + x0] = 1
            minx, miny, maxx, maxy, area = x0, y0, x0, y0, 0
            while stack:
                x, y = stack.pop(); area += 1
                minx, miny, maxx, maxy = min(minx, x), min(miny, y), max(maxx, x), max(maxy, y)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and mp[nx, ny] and not seen[ny * w + nx]:
                        seen[ny * w + nx] = 1; stack.append((nx, ny))
            if area >= min_area:
                parts.append((minx, miny, maxx + 1, maxy + 1, area))
    # Sort in reading order: rows (by vertical center, with tolerance), then left to right.
    parts.sort(key=lambda p: (round(((p[1] + p[3]) / 2) / (h / 6)), p[0]))
    manifest = {"source": os.path.basename(src), "size": [w, h], "parts": []}
    for i, (x0, y0, x1, y1, area) in enumerate(parts):
        name = f"{prefix}-{i}.png"
        im.crop((x0, y0, x1, y1)).save(os.path.join(outdir, name))
        manifest["parts"].append({"file": name, "box": [x0, y0, x1, y1], "area": area})
    with open(os.path.join(outdir, f"{prefix}.json"), "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"{len(parts)} parts from {src} → {outdir}")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "placeholder":
        placeholder(sys.argv[2])
    elif cmd == "keyout":
        args = sys.argv[2:]
        min_area = int(args[args.index("--min-area") + 1]) if "--min-area" in args else 400
        keyout(args[0], args[1], args[2], min_area)
