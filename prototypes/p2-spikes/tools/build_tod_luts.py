#!/usr/bin/env python3
"""The looks of the hour (corrections list #7, 2026-10-05): from Codex's repaintings of the Sanctuary at dawn, day
and night (docs/design/p26/tod-*.png) against the painting itself (dusk), a colour look-up per mood, fitted
separately for the land and for the sky, so every world can wear the light of any hour exactly as painted.
Writes SpikeLab/Assets/tod-lut.png: 1024 × 256, rows of 32 px; row k = one 32³ look-up (32 tiles of 32×32, blue
across tiles, red across a tile, green down it). Rows 0–3 land dawn/day/dusk/night, rows 4–7 the sky.
Colours are stored in a gamma-2 space (sqrt of linear), as the shader reads them. Dusk is the painting (identity).
A missing painting gives an identity look (until Codex delivers). Run from prototypes/p2-spikes."""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

A = "SpikeLab/Assets"; D = "../../docs/design/p26"
N = 32

def lin(s):  # sRGB 0..1 → linear
    return np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)

def g2(img):  # PIL RGB → gamma-2 space (sqrt of linear), float
    return np.sqrt(lin(np.asarray(img).astype(float) / 255))

grid = (np.arange(N) / (N - 1))
R, G, B = np.meshgrid(grid, grid, grid, indexing="ij")
identity = np.stack([R, G, B], -1)                   # [r, g, b, 3]

def fit(src, dst, mask):
    """Mean target colour per source-colour cell, filled and smoothed where the painting has no such colour."""
    s = src[mask]; d = dst[mask]
    idx = np.clip(np.rint(s * (N - 1)).astype(int), 0, N - 1)
    flat = idx[:, 0] * N * N + idx[:, 1] * N + idx[:, 2]
    cnt = np.bincount(flat, minlength=N ** 3).astype(float)
    acc = np.stack([np.bincount(flat, d[:, k], minlength=N ** 3) for k in range(3)], -1)
    cnt = cnt.reshape(N, N, N); acc = acc.reshape(N, N, N, 3)
    # A global fit (affine, plus a little curvature) for colours the painting never uses.
    X = np.c_[s, s ** 2, np.ones(len(s))]
    coef, *_ = np.linalg.lstsq(X, d, rcond=None)
    Xg = np.c_[identity.reshape(-1, 3), identity.reshape(-1, 3) ** 2, np.ones(N ** 3)]
    glob = (Xg @ coef).reshape(N, N, N, 3)
    # Normalised convolution: smooth where data is, spread it into empty cells.
    out = glob.copy()
    for sig in (3.0, 1.6, 0.8):                          # coarse to fine: finer wins where the data is dense
        c = nd.gaussian_filter(cnt, sig)
        a = np.stack([nd.gaussian_filter(acc[..., k], sig) for k in range(3)], -1)
        m = a / np.maximum(c, 1e-6)[..., None]
        w = np.clip(c / 4.0, 0, 1)[..., None]
        out = out * (1 - w) + m * w
    return np.clip(out, 0, 1)

YCC = np.array([[0.299, 0.587, 0.114], [-0.169, -0.331, 0.5], [0.5, -0.419, -0.081]])

def match(lut, s, d):
    """Averaging slightly misaligned pixels greys the colours: re-match the painting's own spread of brightness and
    colour (histogram matching in a luma/chroma space, on what the look gives the painting vs the repainting)."""
    from scipy.ndimage import map_coordinates
    got = np.stack([map_coordinates(lut[..., k], (s * (N - 1)).T, order=1) for k in range(3)], -1)
    a = got @ YCC.T; b = d @ YCC.T
    L = lut.reshape(-1, 3) @ YCC.T
    q = np.linspace(0, 1, 256)
    for k in range(3):
        qa = np.quantile(a[:, k], q); qb = np.quantile(b[:, k], q)
        L[:, k] = np.interp(L[:, k], qa, qb)
    return np.clip((L @ np.linalg.inv(YCC).T).reshape(lut.shape), 0, 1)

def tile(lut):
    """[r, g, b, 3] → 32 × 1024 image row (blue across tiles, red across a tile, green down)."""
    img = np.zeros((N, N * N, 3))
    for b in range(N):
        img[:, b * N:(b + 1) * N] = lut[:, :, b].transpose(1, 0, 2)     # rows = green, cols = red
    return img

def night_by_hand(part):
    """Until Codex's night painting exists: a moonlit night by hand (blue-teal, the land still readable, painted
    lights and very warm glows kept warm; stars and the moon are added live by the shader)."""
    c = identity ** 2                                   # gamma-2 grid → linear
    Y = c @ [0.2126, 0.7152, 0.0722]
    if part == "sky":
        lo, hi = np.array([0.008, 0.014, 0.05]), np.array([0.07, 0.11, 0.26])
        out = lo + (hi - lo) * (Y ** 0.6)[..., None]
    else:
        y = 0.012 + 0.34 * Y ** 0.85                    # dimmer, but never pitch black
        tint = np.array([0.56, 0.76, 1.14])
        grey = (y[..., None] * tint)
        out = grey * 0.82 + c * y[..., None] / np.maximum(Y, 1e-4)[..., None] * 0.18   # a memory of its colour
        warm = np.clip((c[..., 0] - c[..., 2]) * 3, 0, 1) * np.clip((Y - 0.45) * 3, 0, 1)   # painted glows
        out = out * (1 - warm[..., None]) + c * 0.85 * warm[..., None]
    return np.sqrt(np.clip(out, 0, 1))

paint = Image.open(f"{A}/world-paint.png").convert("RGB")
W, H = 400, int(400 * paint.height / paint.width)
# Small and softly blurred: the repaintings are close to the original but never pixel-exact.
def prep(im): return g2(im.convert("RGB").resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.5)))
src = prep(paint)
sky = np.zeros((H, W), bool)
if os.path.exists(f"{A}/world-sky.png"):                       # the Sanctuary's sky layer (its alpha)
    sa = np.asarray(Image.open(f"{A}/world-sky.png").convert("RGBA").resize((W, H)))[..., 3] > 128
    land_a = np.asarray(Image.open(f"{A}/world-land.png").convert("RGBA").resize((W, H)))[..., 3] if os.path.exists(f"{A}/world-land.png") else None
    sky = sa & (land_a < 40) if land_a is not None else sa
else:
    sky[: int(H * 0.22)] = True
sky = nd.binary_erosion(sky, iterations=3)
land = ~nd.binary_dilation(sky, iterations=3)
print("sky", round(sky.mean(), 3), "land", round(land.mean(), 3))

rows = []
for part, mask in (("land", land), ("sky", sky)):
    for mood in ("dawn", "day", "dusk", "night"):
        ref = f"{D}/tod-{mood}.png"
        if mood == "night" and not os.path.exists(ref):
            rows.append(tile(night_by_hand(part))); print(part, mood, "by hand"); continue
        if mood == "dusk" or not os.path.exists(ref) or mask.sum() < 500:
            rows.append(tile(identity)); print(part, mood, "identity"); continue
        dst = prep(Image.open(ref))
        lut = match(fit(src, dst, mask), src[mask], dst[mask])
        if mood == "night":
            # Moonlight is calm: a little less saturated than the fit, so warm lights don't clash with neon blues.
            Y = (lut ** 2) @ [0.2126, 0.7152, 0.0722]
            L2 = lut ** 2
            L2 = L2 * 0.78 + Y[..., None] * np.array([0.82, 0.92, 1.12]) * 0.22
            lut = np.sqrt(np.clip(L2, 0, 1))
        rows.append(tile(lut)); print(part, mood, "fitted")
out = (np.concatenate(rows, 0) * 255 + 0.5).clip(0, 255).astype(np.uint8)
Image.fromarray(out).save(f"{A}/tod-lut.png")
print("wrote", out.shape)
