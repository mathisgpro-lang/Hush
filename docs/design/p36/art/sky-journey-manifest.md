# P3.6 journey sky and state assets

Generated 2026-10-24 for approved decision 190, using the built-in image generation tool. Style references inspected: `map-islands-start.png`, `map-islands-midway.png` and the runtime `map-cloud.png`. These are background plates and isolated art pieces; the live renderer supplies movement.

## Runtime assets

Under `prototypes/p2-spikes/SpikeLab/Assets/`:

| Asset | Pixels | Format / treatment |
| --- | --- | --- |
| `map-sky-dusk.jpg` | 900 × 1500 | Opaque portrait plate, 3:5, 82% saturation, JPEG quality 91 |
| `map-sky-wisp.png` | 800 × 215 | Wide cloud with preserved keyed alpha, 82% saturation, padded transparent bounds |
| `island-{realm}-waiting.png` | 900 × 900 | Existing runtime island, 50% color and 84% brightness |
| `island-{realm}-unreached.png` | 900 × 900 | Existing runtime island, 94% brightness |
| `map-stone-ahead.png` | 900 × 900 | Existing runtime stone, 35% color and 78% brightness |

The realm variants exist for sanctuary, grove, stillwater, highlands, library, wilds, forge and veil. The original island/stone images were already graded to 82% saturation by `scripts/p36-map-art.sh`; that grade is not applied twice. Every state variant retains the original alpha byte for byte. The variants bake the former state color adjustments into textures so the renderer does not need animated color filters.

Raw images: `sky-dusk-raw.png` and `sky-wisp-raw.png`. Full-size keyed wisp: `map-sky-wisp-keyed.png`. Small composition preview: `sky-art-preview.jpg`.

## Processing

The dusk plate uses Pillow `ImageEnhance.Color(...).enhance(0.82)`, then a tiny centered aspect crop with `ImageOps.fit(..., (900, 1500), LANCZOS)`.

The wisp uses the project's unmodified `prototypes/p2-spikes/tools/magenta_key.py`. The keyed alpha bounds are cropped with 18 source pixels of padding, color graded to 82% while retaining alpha, then downscaled to 800 pixels wide with LANCZOS. All four corners have zero alpha; the image contains both fully transparent and fully opaque pixels. It should be drawn with normal alpha blending, with no blur or screen blend required.

## Final generation prompts

### Dusk plate

```text
Use case: stylized-concept.
Asset type: full-screen portrait background plate for a painted fantasy mobile game, 3:5 portrait composition.
Primary request: A rich hand-painted dusk sea of clouds viewed from high above, spacious and dreamy. The entire top 60% and central path area are quiet deep slate blue and muted lavender air, with very subtle distant cloud veils. Soft sculpted lavender-blue cloud banks rise along the lower sides and fill the bottom quarter, lit underneath and along their rounded edges with restrained pale peach and warm cream dusk light. Beautiful atmospheric depth, soft brush texture, the dimensional painterly fantasy aesthetic of warm floating-island world maps. The background supports foreground islands and a winding path which will be placed later.
Composition: A single continuous illustrated background from edge to edge. Broad open dark space through the center. Keep the brightest cloud light low and toward the side edges, low contrast behind the center. No central focus object. Cloud formations feel vast and layered, not a thin fog or a gradient.
Palette: slate blue, lavender, muted blue-violet shadows, pale peach light. Colorful but calm, no neon. The blue air is deep and readable, not black.
Constraints: only sky and clouds. NO islands, rocks, mountains, buildings, stepping stones, paths, horizon line, ocean, land, sun, moon, stars, galaxies, vortex, text, UI, border, watermark or characters. No photorealism, no 3D render. Fill portrait canvas.
```

### Wisp

```text
Use case: stylized-concept.
Asset type: separate horizontal parallax cloud sprite for a painted fantasy mobile game.
Primary request: ONE wide airy drifting cloud wisp/bank, alone on perfectly flat uniform pure magenta #FF00FF. Painterly fantasy illustration, soft dimensional brushwork, delicate curled wisps at the ends, a few gentle rounded lobes, lavender and slate-blue shadows with restrained peach-cream light from below. The cloud is horizontally flowing and airy, lower and thinner than a towering cumulus, with a readable silhouette; not a rectangle of mist.
Composition: Landscape 3:2 canvas. Cloud extends across about 88% of width and 38% of height, centered with generous clear magenta margin on all four sides. It must remain fully inside the canvas. Crisp clean outer silhouette with small fine wisps, no glow or translucent haze spilling far onto the magenta background. Paint solid cloud colors against magenta for later chroma-key processing.
Constraints: No sky, no other clouds or separate objects, no islands, rocks, stars, text, watermark or UI. Background must be exactly pure flat magenta #FF00FF. No shadow cast onto the background. No photographic or 3D render look.
```
