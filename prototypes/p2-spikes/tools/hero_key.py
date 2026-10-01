#!/usr/bin/env python3
"""Key Codex's hero painting off its dark background (route C preview). Only darkness connected to the image border
is background; dark details inside the Flame (irises, lashes) stay opaque. Writes hero-keyed/blink/happy.png."""
from PIL import Image, ImageDraw, ImageFilter
import colorsys, random, sys
from collections import deque
src_path, out_dir = sys.argv[1], sys.argv[2]
im = Image.open(src_path).convert("RGB")
w, h = im.size
im = im.crop((int(w * 0.12), 0, int(w * 0.88), int(h * 0.93)))
im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
W, H = im.size
px = im.load()
lum = [[(0.299 * px[x, y][0] + 0.587 * px[x, y][1] + 0.114 * px[x, y][2]) / 255 for x in range(W)] for y in range(H)]
# Flood fill the background from the borders through dark-ish pixels.
bg = [[False] * W for _ in range(H)]
q = deque()
for x in range(W):
    for y in (0, H - 1): q.append((x, y))
for y in range(H):
    for x in (0, W - 1): q.append((x, y))
while q:
    x, y = q.popleft()
    if not (0 <= x < W and 0 <= y < H) or bg[y][x] or lum[y][x] > 0.42: continue
    bg[y][x] = True
    q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
out = Image.new("RGBA", (W, H)); op = out.load()
base_bg = (34, 18, 10)
for y in range(H):
    for x in range(W):
        r, g, b = px[x, y]
        if bg[y][x]:
            a = max(0.0, min(1.0, (lum[y][x] - 0.22) / 0.20))      # soft glow at the silhouette
            ey = min(y, H - 1 - y) / (H * 0.06); ex = min(x, W - 1 - x) / (W * 0.10)
            a *= max(0.0, min(1.0, ex)) * max(0.0, min(1.0, ey))
            c = [min(255, max(0, int(base_bg[i] + (v - base_bg[i]) / max(a, 0.35)))) for i, v in enumerate((r, g, b))] if a > 0 else [0, 0, 0]
            op[x, y] = (*c, int(a * 255))
        else:
            op[x, y] = (r, g, b, 255)                               # the Flame itself: fully opaque
# Fade the floor reflection at the feet.
start = int(H * 0.86)
for y in range(start, H):
    k = (1 - (y - start) / (H - start)) ** 2
    for x in range(W):
        r, g, b, a = op[x, y]; op[x, y] = (r, g, b, int(a * k))
out.save(f"{out_dir}/hero-keyed.png")

# Closed-eye and happy variants: find each eye (non-skin pixels near the eye guesses), refill from the skin above and below.
src = out.load()
guess = [((443 - 137) / 2, 662 / 2), ((718 - 137) / 2, 662 / 2)]
mask = Image.new("L", (W, H), 0); mp = mask.load(); boxes = []
for (cx, cy) in guess:
    x0, x1, y0, y1 = int(cx - 55), int(cx + 55), int(cy - 50), int(cy + 40)
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b, a = src[x, y]
            hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if not (0.05 <= hh <= 0.17 and s > 0.45 and v > 0.55): mp[x, y] = 255
    boxes.append((x0, y0, x1, y1))
mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(7))
mp = mask.load()
random.seed(5)
def filled():
    o = out.copy(); p = o.load()
    for (x0, y0, x1, y1) in boxes:
        for x in range(x0, x1):
            col = [y for y in range(y0, y1) if mp[x, y]]
            if not col: continue
            top, bot = min(col) - 2, max(col) + 2
            ct, cb = src[x, top], src[x, bot]
            for y in range(top + 1, bot):
                t = (y - top) / (bot - top)
                c = [max(0, min(255, int(ct[i] * (1 - t) + cb[i] * t + random.uniform(-5, 5)))) for i in range(3)]
                p[x, y] = (*c, 255)
    return Image.composite(o.filter(ImageFilter.GaussianBlur(5)), o, mask.filter(ImageFilter.GaussianBlur(3)))
def bounds(b):
    x0, y0, x1, y1 = b
    pts = [(x, y) for y in range(y0, y1) for x in range(x0, x1) if mp[x, y]]
    return min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)
eb = [bounds(b) for b in boxes]
for kind in ("blink", "happy"):
    o = filled(); d = ImageDraw.Draw(o)
    for (x0, y0, x1, y1) in eb:
        ww, hh2 = x1 - x0, y1 - y0; cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        if kind == "blink":
            d.arc((cx - ww * 0.42, cy - hh2 * 0.25, cx + ww * 0.42, cy + hh2 * 0.35), 15, 165, fill=(74, 32, 14, 255), width=5)
        else:
            d.arc((cx - ww * 0.38, cy - hh2 * 0.12, cx + ww * 0.38, cy + hh2 * 0.48), 205, 335, fill=(74, 32, 14, 255), width=5)
    o.save(f"{out_dir}/hero-{kind}.png")
print("keyed", W, H, "eyes", eb)
