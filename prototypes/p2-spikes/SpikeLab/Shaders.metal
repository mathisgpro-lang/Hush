// SpikeLab shaders (throwaway). Geometry modifiers run per vertex; the probe checks they work on a skinned mesh.
#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

// Flame hair: continuous sway, stronger toward the tips (tips sit higher in model space).
[[visible]]
void hairSway(realitykit::geometry_parameters params)
{
    float3 p = params.geometry().model_position();
    float t = params.uniforms().time();
    float h = saturate((p.y - 0.18) / 0.12);          // 0 at the hair base, 1 at the tallest tip
    float sway = sin(t * 3.1 + p.x * 40.0) * 0.012 + sin(t * 7.3 + p.y * 60.0) * 0.004;
    params.geometry().set_model_position_offset(float3(sway * h, h * 0.006 * sin(t * 5.0), 0));
}

// Painted rig (route C). Plane meshes have uv.y = 0 at the bottom (the pivot) and 1 at the top.

// A flame tongue: the base stays put, the tip sways and stretches. custom: x = phase, y = sway amplitude (m).
[[visible]]
void tongueSway(realitykit::geometry_parameters params)
{
    float2 uv = params.geometry().uv0();
    float4 c = params.uniforms().custom_parameter();
    float t = params.uniforms().time();
    float3 p = params.geometry().model_position();
    float k = uv.y * uv.y;
    float s = sin(t * 2.6 + c.x) * c.y + sin(t * 6.1 + c.x * 1.7) * c.y * 0.35;
    float stretch = 0.035 * sin(t * 3.7 + c.x * 0.8) + 0.015 * sin(t * 9.0 + c.x);
    params.geometry().set_model_position_offset(float3(s * k, stretch * p.y * uv.y, 0));
}

// Breathing: a gentle scale around the bottom center. custom: x = rate, y = depth.
[[visible]]
void breathe(realitykit::geometry_parameters params)
{
    float3 p = params.geometry().model_position();
    float4 c = params.uniforms().custom_parameter();
    float t = params.uniforms().time();
    float b = sin(t * 1.6 * c.x) * c.y;
    params.geometry().set_model_position_offset(float3(p.x * b * 0.6, p.y * b, 0));
}

// Codex's hero painting, alive as one layer: flame hair (top of the image) sways and licks upward, the body breathes.
// custom: x = liveliness (mood), y = unused.
[[visible]]
void heroLive(realitykit::geometry_parameters params)
{
    float2 uv = params.geometry().uv0();
    float3 p = params.geometry().model_position();
    float4 c = params.uniforms().custom_parameter();
    float t = params.uniforms().time();
    float hair = smoothstep(0.50, 1.0, uv.y);
    float energy = 0.6 + 0.6 * c.x;
    float sway = (sin(t * 2.4 + uv.y * 9.0 + uv.x * 5.0) * 0.008 + sin(t * 5.7 + uv.x * 13.0) * 0.003) * hair * hair * energy;
    float lick = (sin(t * 3.3 + uv.x * 17.0) * 0.5 + 0.5) * 0.010 * hair * hair * hair * energy;
    float breath = sin(t * 1.6) * 0.012;
    float body = 1.0 - hair;
    float bob = sin(t * 1.25) * 0.002 + sin(t * 2.9) * 0.0008;           // never perfectly still
    // Follow-through (custom.zw, from the body's motion): the hair trails behind and lags, then catches up.
    float2 drag = c.zw * hair * hair;
    params.geometry().set_model_position_offset(float3(sway + p.x * breath * 0.6 * body + drag.x,
                                                       lick + p.y * breath * 0.5 * body + bob + drag.y, 0));
}

// Living fire inside Codex's painting: flames flow upward through the hair and fur (the face stays crisp),
// the core pulses like a heartbeat, and the whole body flickers softly. custom: x = liveliness (mood).
// uv0 has v = 0 at the bottom; textures are sampled with v flipped.
[[visible]]
void heroFireSurface(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float energy = 0.6 + 0.6 * params.uniforms().custom_parameter().x;

    float face = 1.0 - smoothstep(0.55, 1.0, length((uv - float2(0.5, 0.44)) / float2(0.30, 0.13)));
    float hair = smoothstep(0.52, 0.92, uv.y);
    float flame = saturate(0.30 + hair) * (1.0 - face);

    // Two layers of upward-scrolling waves give a flowing, never-repeating flicker.
    float w1 = sin(uv.y * 26.0 - t * 4.2 + sin(uv.x * 9.0 + t * 0.7) * 2.0);
    float w2 = sin(uv.y * 47.0 - t * 6.9 + uv.x * 21.0);
    float2 d = float2(w1 * 0.0045 + w2 * 0.0018, -abs(w2) * 0.0035) * flame * energy;

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y) + d);

    float core = 1.0 - smoothstep(0.0, 0.17, length((uv - float2(0.5, 0.25)) / float2(1.0, 1.3)));
    float beat = pow(0.5 + 0.5 * sin(t * 2.3), 8.0) + 0.35 * pow(0.5 + 0.5 * sin(t * 2.3 - 0.6), 12.0);
    col.rgb += half3(0.40, 0.26, 0.08) * half(core * beat * 0.55 * energy);
    col.rgb *= half(1.0 + 0.07 * w1 * flame);

    // custom.y = brightness (mood, night); the material tint isn't reliable on materials converted from unlit.
    // In a scene, brightness arrives + 10: then the world lights the Flame (A2): a sunset rim on the sun side
    // (a silhouette edge found from the alpha), and a touch of the scene's warm haze.
    float bright = params.uniforms().custom_parameter().y;
    if (bright > 5.0) {
        bright -= 10.0;
        float2 suv = float2(uv.x, 1.0 - uv.y) + d;
        float aHere = float(col.a);
        float aSun = float(params.textures().base_color().sample(s, suv + float2(0.035, -0.01)).a);
        float rim = saturate((aHere - aSun) * 1.6) * smoothstep(0.15, 0.7, uv.y);
        col.rgb = mix(col.rgb, col.rgb * half3(1.0, 0.86, 0.82) + half3(0.05, 0.0, 0.03), half(0.25));
        col.rgb += half3(1.0, 0.72, 0.55) * half(rim * 0.55);
    }
    // Output as emissive so the painting shows its own colors whether the material is treated as lit or unlit.
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(col.rgb * half(bright));
    params.surface().set_opacity(col.a);
}

// A soft glow that breathes with the core (ground pool and halo). custom: x = strength.
[[visible]]
void glowPulse(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y));
    float beat = 0.75 + 0.15 * pow(0.5 + 0.5 * sin(t * 2.3), 8.0) + 0.1 * sin(t * 7.7) * sin(t * 3.1);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(col.rgb);
    params.surface().set_opacity(col.a * half(beat * params.uniforms().custom_parameter().x));
}

// ---------- S2 · the painted Sanctuary, alive ----------

float s2hash(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }
float s2noise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(s2hash(i), s2hash(i + float2(1, 0)), u.x), mix(s2hash(i + float2(0, 1)), s2hash(i + float2(1, 1)), u.x), u.y);
}
float3 s2hourLight(float3 rgb, float2 uv, float skyM, float seaM, float hour, float sunU, float ratio, float t, texture2d<half> lut, float lightM);   // (defined below)
// ---- Pixel mode (Mathis, 2026-10-07: "pixelize the whole game") ----
// A material in pixel mode carries emissive tint (cols / 4096, rows / 4096, 0.5): the art-pixel grid over its texture.
// Its surface snaps to that grid (every effect computed per art pixel, so motion crawls pixel by pixel), and its
// colours are cut to a small palette with a light ordered dither. Off (white tint): untouched.
inline bool s2isPixel(half3 tint) { return tint.b < 0.75h; }
inline float2 s2grid(half3 tint) { return max(float2(8.0), float2(tint.rg) * 4096.0); }
// No pixel filter any more (Mathis, 2026-10-15: "is there a pixelized filter on top of the worlds? … take that away"):
// lookups are never snapped to a grid; the pixel-mode marker now only means "show the art's own colours exactly".
inline float2 s2pixelUV(float2 uv, half3 tint, float2 unused) { return uv; }
/// A texture lookup in pixel mode lands on a pixel's centre (even mid-motion), so pixel art stays crisp at any size.
inline float2 s2snap(float2 uv, half3 tint) { return uv; }
inline float3 s2pixelColor(float3 rgb, float2 uv, half3 tint, float2 unused)
{
    if (!s2isPixel(tint)) return rgb;
    int2 cell = int2(floor(uv * s2grid(tint)));
    const float bayer[16] = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};
    float d = bayer[(cell.x & 3) + (cell.y & 3) * 4] / 16.0 - 0.47;
    float levels = 22.0;
    float3 g = sqrt(max(rgb, 0.0));                                  // in a perceptual space: even steps
    g = floor(g * levels + 0.5 + d * 0.35) / levels;
    return g * g;
}

float s2night(float hour);

inline float3 depthStoneLight(float3 rgb, float2 uv, float2 center, float strength, float t) {
    float2 d = (uv - center) / float2(0.12, 0.038);
    float pool = exp(-dot(d, d) * 1.7) * strength;
    float pulse = 0.94 + 0.04 * sin(t * 2.3) + 0.02 * sin(t * 5.1);
    // Multiplication preserves stone joints and their shadows; a little bounced gold reaches dark stones.
    return rgb * (1.0 + float3(0.40, 0.22, 0.04) * pool * pulse)
         + float3(0.045, 0.021, 0.004) * pool * pulse;
}

float3 s2moods(float hour);
float3 s2look(texture2d<half> lut, float3 c, float skyM, float3 m);
float s2fbm(float2 p) { return s2noise(p) * 0.55 + s2noise(p * 2.1 + 3.7) * 0.3 + s2noise(p * 4.3 + 9.1) * 0.15; }

// The painting comes alive: rippling water with sparkles in the lower part, falling water where the painting is
// bright and pale in the waterfall band, and the Hush grading (R1: custom.x = vitality → mist, grey, dimming).
[[visible]]
void sanctuaryLive(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float vitality = params.uniforms().custom_parameter().x;
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);

    // Water (bottom of the painting): two crossing ripple trains, stronger toward the viewer.
    float water = 1.0 - smoothstep(0.26, 0.33, uv.y);
    float near = saturate(1.0 - uv.y / 0.3);
    float2 ripple = float2(sin(uv.y * 160.0 - t * 1.6 + sin(uv.x * 12.0 + t * 0.5)) * 0.0022,
                           sin(uv.x * 70.0 + t * 1.1) * 0.0012) * water * (0.4 + near);

    half4 base = params.textures().base_color().sample(s, tuv);
    // Waterfalls: pale bright pixels in the middle band flow downward.
    float lum = dot(float3(base.rgb), float3(0.299, 0.587, 0.114));
    float sat = float(max(base.r, max(base.g, base.b)) - min(base.r, min(base.g, base.b)));
    float fall = smoothstep(0.62, 0.8, lum) * (1.0 - smoothstep(0.15, 0.35, sat)) * smoothstep(0.34, 0.4, uv.y) * (1.0 - smoothstep(0.6, 0.66, uv.y));
    float2 flow = float2((s2noise(float2(uv.x * 60.0, uv.y * 30.0 + t * 4.0)) - 0.5) * 0.002,
                         (s2noise(float2(uv.x * 40.0, uv.y * 25.0 + t * 3.0)) - 0.5) * 0.007) * fall;

    // Wind (B3): foliage (greener than red and blue) sways with the gust, more higher up.
    float wind = params.material_constants().roughness_scale();
    float green = smoothstep(0.02, 0.12, float(base.g) - max(float(base.r) * 0.85, float(base.b)));
    float2 sway = float2(sin(t * 2.2 + uv.y * 30.0 + uv.x * 8.0) * 0.0035 * wind * green * (0.4 + uv.y), 0);

    half4 col = params.textures().base_color().sample(s, tuv + ripple + flow + sway);
    // Sparkles on the water where the sun reflects.
    float sp = s2noise(float2(uv.x * 140.0 + sin(t * 0.3) * 2.0, uv.y * 380.0 - t * 1.5));
    float sparkle = smoothstep(0.93, 1.0, sp) * (0.5 + 0.5 * sin(t * 6.0 + uv.x * 50.0)) * water * near * 0.6;
    col.rgb += half3(1.0, 0.85, 0.6) * half(sparkle);
    // Falling water shimmer.
    col.rgb += half3(0.08) * half(fall * (0.5 + 0.5 * sin(uv.y * 400.0 + t * 12.0)));

    // The Flame lights the world (A1): warm light on nearby surfaces, stronger on the ground below it.
    float4 cp = params.uniforms().custom_parameter();
    float2 fd = float2((uv.x - cp.y) * 0.46, uv.y - cp.z);
    float below = fd.y < 0.0 ? 1.25 : 0.6;
    float light = cp.w * exp(-dot(fd, fd) / 0.0035) * below;
    col.rgb += col.rgb * half3(1.0, 0.55, 0.18) * half(light * 1.4) + half3(0.22, 0.10, 0.02) * half(light * 0.35);

    // The Hush: grey, cooler, misty and dimmer as vitality drops (nothing disappears).
    float hush = 1.0 - vitality;
    float grey = dot(float3(col.rgb), float3(0.3, 0.59, 0.11));
    float3 c = mix(float3(col.rgb), float3(grey) * float3(0.85, 0.9, 1.05), hush * 0.75);
    float mist = s2fbm(uv * float2(3.0, 6.0) + float2(t * 0.02, 0)) * hush * 0.45;
    c = mix(c, float3(0.62, 0.65, 0.72), mist);
    c *= (1.0 - hush * 0.35);

    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(c));
    params.surface().set_opacity(1.0);
}

// A drifting mist card (opacity from custom.x; custom.y = speed; custom.z = seed).
[[visible]]
void mistDrift(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float4 c = params.uniforms().custom_parameter();
    float t = params.uniforms().time();
    float n = s2fbm(float2(uv.x * 3.0 + t * c.y + c.z, uv.y * 2.0 + c.z * 0.5));
    float edge = smoothstep(0.0, 0.25, uv.y) * (1.0 - smoothstep(0.6, 1.0, uv.y)) * smoothstep(0.0, 0.1, uv.x) * (1.0 - smoothstep(0.9, 1.0, uv.x));
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(0.8, 0.8, 0.86));
    params.surface().set_opacity(half(saturate(n * 1.6 - 0.35) * edge * c.x));
}

// The Flame's reflection: the same painting mirrored below its feet, fading with distance and rippling.
// custom: x mood, y brightness, zw hair follow-through (shared with heroLive).
[[visible]]
void heroReflection(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 r = float2(sin(uv.y * 70.0 + t * 3.2) * 0.012 * uv.y + sin(uv.y * 31.0 - t * 1.7) * 0.006 * uv.y, 0);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y) + r);
    float fade = 1.0 - smoothstep(0.0, 0.55, uv.y);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(col.rgb * half(0.75 * params.uniforms().custom_parameter().y));
    params.surface().set_opacity(col.a * half(0.38 * fade));
}

// ---------- S3 · restoration in the Whispering Grove ----------
// custom: x = restoration 0…1 (from the Heart pillar's Depth, R1), y = vitality 0…1 (atmosphere, R1),
//         z = order of the lantern relit last, w = seconds since it relit (for its flare).
// custom texture: lantern order map (0 = not a lantern; (0,1] = the order in which it relights).
// roughness_scale = wind.
[[visible]]
void groveRestore(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    half3 pxTint = half3(params.material_constants().emissive_color());
    float2 pxSize = float2(params.textures().base_color().get_width(), params.textures().base_color().get_height());
    uv = s2pixelUV(uv, pxTint, pxSize);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float r = c.x, vitality = c.y;
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);

    // Water moves again from restoration level ~1. New realms carry their water mask in the lights map's alpha
    // (metallic_scale = 1); the Grove's older map has none, so its water is the bottom band.
    // New realms (metallic_scale = 1) carry water and sky in the lights map's alpha: ~1 = water, ~0.5 = sky.
    bool newRealm = params.material_constants().metallic_scale() > 0.5;
    float aMap = float(params.textures().custom().sample(s, tuv).a);
    float water = newRealm ? smoothstep(0.72, 0.9, aMap) : 1.0 - smoothstep(0.12, 0.2, uv.y);
    float skyM = newRealm ? (smoothstep(0.3, 0.45, aMap) * (1.0 - smoothstep(0.55, 0.7, aMap))) : 0.0;
    // Clouds billow: a slow drifting warp in the sky only.
    float2 cw = float2(s2noise(float2(uv.x * 3.0 + t * 0.03, uv.y * 4.0)) - 0.5, s2noise(float2(uv.x * 2.0 - t * 0.02, uv.y * 3.0 + 5.0)) - 0.5);
    float2 cloud = (cw * 0.012 + float2(sin(t * 0.05 + uv.y * 6.0) * 0.004, 0)) * skyM;
    float flowing = newRealm ? 1.0 : smoothstep(0.15, 0.4, r);     // new realms: the water always moves
    float2 ripple = float2(sin(uv.y * 150.0 - t * 1.4 + sin(uv.x * 10.0 + t * 0.5)) * 0.002,
                           sin(uv.x * 60.0 + t * 1.0) * 0.001) * water * flowing;
    half4 base0 = params.textures().base_color().sample(s, tuv);
    float wind = params.material_constants().roughness_scale();
    float green = smoothstep(0.02, 0.12, float(base0.g) - max(float(base0.r) * 0.85, float(base0.b)));
    float2 sway = float2(sin(t * 2.0 + uv.y * 28.0 + uv.x * 7.0) * 0.003 * wind * green * (0.4 + uv.y), 0);
    // Falling water (pale, inside the water mask) races down instead of rippling sideways.
    float paleW = water * smoothstep(0.62, 0.8, dot(float3(base0.rgb), float3(0.299, 0.587, 0.114)))
                * (1.0 - smoothstep(0.15, 0.3, float(max(base0.r, max(base0.g, base0.b)) - min(base0.r, min(base0.g, base0.b)))));
    float2 flow = float2((s2noise(float2(uv.x * 70.0, uv.y * 30.0 + t * 4.0)) - 0.5) * 0.0015,
                         (s2noise(float2(uv.x * 50.0, uv.y * 25.0 + t * 3.2)) - 0.5) * 0.004) * paleW;
    // Foliage breathes all the time and bends further when a gust rolls across (a travelling wave), as at home.
    float gust = 0.5 + 0.5 * sin(uv.x * 7.0 - t * 1.4);
    float sw = sin(t * 1.7 + uv.y * 14.0 + uv.x * 6.0) * 0.6 + sin(t * 3.1 + uv.y * 31.0) * 0.4;
    float2 breeze = float2(sw * 0.0022 * green * (0.3 + uv.y) * (0.35 + wind * 1.3 * gust), sw * 0.0006 * green) * (newRealm ? 1.0 : 0.0);
    // The painting breathes (decision 142): the life map (normal texture; clearcoat_roughness_scale = 1 when the
    // realm has one) says what is foliage (R) and cloth (G). Each plant sways in its own rhythm and gusts roll
    // across them; banners ripple; clouds drift behind everything.
    bool hasLife = params.material_constants().clearcoat_roughness_scale() > 0.5;
    float foliage = 0.0, cloth = 0.0;
    if (hasLife) {
        half4 lifeM = params.textures().normal().sample(s, tuv);
        foliage = float(lifeM.r); cloth = float(lifeM.g);
        float ph = s2noise(uv * 9.0) * 6.2831853;                                   // each plant its own rhythm
        float roll = 0.5 + 0.5 * sin(uv.x * 5.0 - t * 1.1 + sin(uv.y * 3.0 + t * 0.35) * 1.5);   // a gust rolling across
        float bend = sin(t * 1.5 + ph + uv.y * 10.0) * 0.6 + sin(t * 2.7 + ph * 1.7) * 0.4;
        breeze = float2(bend * 0.0024 * (0.35 + roll * 1.1 + wind), cos(t * 1.2 + ph) * 0.0007) * foliage;
        float wave = sin(uv.y * 55.0 - t * 2.6 + uv.x * 8.0) * 0.6 + sin(uv.y * 23.0 - t * 1.7) * 0.4;
        breeze += float2(wave * 0.0016 * (0.6 + roll * 0.8), 0.0) * cloth;
        sway = float2(0.0);
        green = 0.0;
    }
    // Painted flames move (Mathis: "the fire isn't moving"): inside each lantern's core the paint wobbles and licks
    // upward, every flame in its own rhythm.
    half4 lm = params.textures().custom().sample(s, tuv);          // the lanterns map, read once for everything
    float core0 = float(lm.g);
    float2 lick = float2(sin(uv.y * 520.0 - t * 11.0 + uv.x * 90.0) * 0.0007 + sin(uv.y * 210.0 - t * 6.3) * 0.0004,
                         -(0.5 + 0.5 * sin(t * 8.0 + uv.x * 400.0 + uv.y * 60.0)) * 0.0011) * core0;
    half4 col = params.textures().base_color().sample(s, s2snap(tuv + ripple * (1.0 - paleW) + sway + flow + breeze + cloud + lick, pxTint));
    if (hasLife && skyM > 0.01) {
        // The sky drifts gently, one sharp reading (blending two shifted copies smeared the distant castles).
        float2 drift = float2(sin(t * 0.045) * 0.005 + sin(t * 0.017) * 0.003, sin(t * 0.03) * 0.0012);
        col = mix(col, params.textures().base_color().sample(s, s2snap(tuv + drift + cloud, pxTint)), half(skyM));
    }
    float3 rgb = float3(col.rgb);
    float3 rgbRaw = rgb;                              // (its lanterns keep their own fire, whatever the hour)
    float hourK0 = params.material_constants().clearcoat_scale();
    if (newRealm && hourK0 > 0.0) {
        rgb = s2look(params.textures().emissive_color(), rgb, skyM, s2moods(hourK0 * 24.0));
        float rawY = dot(rgbRaw, float3(0.299, 0.587, 0.114));                 // bright warm glows keep their gold
        rgb = mix(rgb, rgbRaw, smoothstep(0.5, 0.85, rawY) * saturate((rgbRaw.r - rgbRaw.b) * 2.5) * 0.7 * (1.0 - s2night(hourK0 * 24.0)));
    }
    // Waterfalls: bright streaks racing down, glints on still water.
    float colI = floor(uv.x * 260.0);
    float streak = fract(uv.y * 18.0 + t * (1.6 + fract(sin(colI * 12.9) * 43758.5) * 0.8));
    rgb += float3(0.95, 0.97, 1.0) * paleW * smoothstep(0.75, 1.0, streak) * 0.3;
    float glint = smoothstep(0.93, 1.0, s2noise(float2(uv.x * 160.0 + sin(t * 0.25) * 3.0, uv.y * 420.0 - t * 1.6)));
    rgb += float3(1.0, 0.88, 0.7) * glint * water * (1.0 - paleW) * (0.5 + 0.5 * sin(t * 6.0 + uv.x * 40.0)) * 0.6;

    // Lanterns (custom texture: R = order of the nearest lantern, G = the lantern itself, B = its pool of light).
    // R (order) must not be interpolated between lanterns or at its edge, so it's read with nearest filtering.
    constexpr sampler sn(address::clamp_to_edge, filter::nearest);
    float order = float(params.textures().custom().sample(sn, tuv).r), core = float(lm.g), pool = float(lm.b);
    float lit = step(0.001, order) * smoothstep(order - 0.004, order, r);
    float lum = dot(rgb, float3(0.299, 0.587, 0.114));
    float flicker = 0.92 + 0.08 * sin(t * 9.0 + order * 300.0) * sin(t * 3.7 + order * 91.0);
    if (hasLife) {
        // Every flame alive on its own: an uneven flicker, and its pool of light swaying with it, so the light and
        // the shadows on the floor, walls and books breathe with the fire.
        flicker = 0.78 + 0.22 * s2noise(float2(t * 5.5 + order * 53.0, order * 17.0)) + 0.05 * sin(t * 19.0 + order * 80.0);
        if (pool > 0.004) {                                         // only where there is light to sway
            float2 jit = float2(sin(t * 6.1 + order * 41.0), cos(t * 4.7 + order * 23.0)) * 0.003;
            pool = float(params.textures().custom().sample(s, tuv + jit).b);
        }
    }
    float flare = (1.0 - smoothstep(0.0, 0.006, abs(order - c.z))) * exp(-c.w * 2.5);

    // The Grove is always vivid (Mathis: never grey); while it sleeps, it is only a little dimmer and cooler, and
    // its lanterns are dark. Restoring it warms it up and lights them one by one.
    float localLight = lit * pool;
    float sat = max((newRealm ? 0.95 : 0.8) + 0.2 * smoothstep(0.0, 0.9, r), localLight);
    float3 graded = mix(float3(lum), rgb, sat);
    graded *= mix(float3(0.86, 0.9, 1.0), float3(1.04, 1.02, 0.98), smoothstep(0.0, 0.8, r));
    float base = newRealm ? 0.93 : 0.8;
    graded *= max(base + 0.12 * smoothstep(0.0, 0.8, r), base + 0.2 * localLight);
    // Unlit lanterns dim their own painted glow; lit ones shine (flickering, flaring right after relighting).
    float3 dark = rgb * float3(0.32, 0.3, 0.34);          // an unlit lantern: its own colors, just without fire
    float3 shining = rgbRaw * flicker * 1.12 + float3(1.0, 0.8, 0.45) * flare * 1.4;
    graded = mix(graded, mix(dark, shining, lit), core);
    graded += float3(1.0, 0.7, 0.35) * pool * lit * 0.06 * flicker + float3(1.0, 0.75, 0.4) * pool * flare * 0.35;
    if (hasLife) {
        // The painted light around every flame (lit or not yet) rises and falls with it: shadows deepen and lift.
        float breathe = (flicker - 0.9) * (0.55 + 0.45 * lit);
        graded *= 1.0 + pool * breathe * 0.9;
        graded += float3(1.0, 0.62, 0.3) * core * max(0.0, flicker - 0.85) * 0.5 * (0.4 + 0.6 * lit);
    }
    float m0 = 0.0;

    // Mist: thick when Hushed, lifting with restoration; vitality thickens or thins it day to day.
    float mistAmount = (1.0 - smoothstep(0.0, 0.85, r)) * (newRealm ? 0.06 : 0.14) + (1.0 - vitality) * 0.25;   // a light veil, never a fog
    float m = s2fbm(uv * float2(3.0, 5.0) + float2(t * 0.015, 0)) * mistAmount * (1.0 - localLight * 0.8) + m0;
    graded = mix(graded, float3(0.6, 0.63, 0.7), m);

    // The light of the hour, as in the Sanctuary (clearcoat_scale = hour / 24, specular_scale = the sun's u).
    float hourK = params.material_constants().clearcoat_scale();
    if (newRealm && hourK > 0.0) {
        float hourNow = hourK * 24.0;
        float3 before = graded;
        // The sky keeps some of its painting by day (a lavender sky shouldn't turn into a white cloud).
        graded = s2hourLight(graded, uv, skyM, water, hourNow, params.material_constants().specular_scale(), 0.37, t, params.textures().emissive_color(), core * lit + pool * lit * 0.5);
    }
    params.surface().set_base_color(half3(0));
    if (s2isPixel(pxTint)) {
        // Pixel art (decision 149, Mathis: "exactly these colors"): the art's own colours, untouched (no grading,
        // no hour look, no palette); only its lights breathe, and only by brightness.
        graded = rgbRaw * (1.0 + pool * (flicker - 0.9) * 0.6 + core * max(0.0, flicker - 0.9) * 0.5);
    }
    float3 anchor = float3(params.material_constants().base_color_tint().rgb);
    if (anchor.b < 0.5) graded = depthStoneLight(graded, uv, anchor.rg, 1.0, t);
    params.surface().set_emissive_color(half3(graded));
    params.surface().set_opacity(1.0);
}

// The light strand an action sends from the Flame to the world: a soft glowing orb (opacity from custom.x).
[[visible]]
void strandGlow(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float d = length(uv - float2(0.5));
    float a = pow(saturate(1.0 - d * 2.0), 2.2) * params.uniforms().custom_parameter().x;
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(1.0, 0.82, 0.5) * half(1.0 + (1.0 - d * 2.0)));
    params.surface().set_opacity(half(a));
}

// ---------- The living layered Flame (route C, Codex's separate parts) ----------
// Body: fire flowing upward through the fur, the face area kept crisp, a heartbeat in the core.
// custom: x = mood, y = brightness.
[[visible]]
void layerBodyFire(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float energy = 0.6 + 0.6 * c.x;
    float face = 1.0 - smoothstep(0.6, 1.0, length((uv - float2(0.5, 0.68)) / float2(0.36, 0.14)));
    float flameAmt = (1.0 - face) * (0.5 + 0.5 * smoothstep(0.45, 0.95, uv.y));
    float w1 = sin(uv.y * 30.0 - t * 4.0 + sin(uv.x * 10.0 + t * 0.6) * 2.0);
    float w2 = sin(uv.y * 55.0 - t * 6.5 + uv.x * 23.0);
    float2 d = float2(w1 * 0.004 + w2 * 0.0016, -abs(w2) * 0.003) * flameAmt * energy;
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y) + d);
    float core = 1.0 - smoothstep(0.0, 0.16, length((uv - float2(0.5, 0.40)) / float2(1.0, 0.75)));
    float beat = pow(0.5 + 0.5 * sin(t * 2.3), 8.0) + 0.35 * pow(0.5 + 0.5 * sin(t * 2.3 - 0.6), 12.0);
    col.rgb += half3(0.42, 0.28, 0.08) * half(core * beat * 0.6 * energy);
    col.rgb *= half(1.0 + 0.06 * w1 * flameAmt);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(col.rgb * half(c.y));
    params.surface().set_opacity(col.a);
}

// A flame tongue: flowing fire inside it (its sway and stretch come from tongueSway). custom: x phase, y amp, z brightness.
[[visible]]
void tongueFire(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float w = sin(uv.y * 22.0 - t * 5.0 + c.x * 3.0 + sin(uv.x * 8.0 + t) * 1.5);
    float2 d = float2(w * 0.012 * uv.y, -abs(w) * 0.01 * uv.y);
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y) + d);
    col.rgb *= half(1.0 + 0.1 * w * uv.y);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(col.rgb * half(c.z));
    params.surface().set_opacity(col.a);
}

// The light of the hour, shared by every layer of the world (land, sea, sky): day, morning, night (stars and a
// moon crossing the sky) and dusk (the painting itself), plus sun shafts. skyM = how much this pixel is sky.
float3 s2sat(float3 c, float k) { float g = dot(c, float3(0.299, 0.587, 0.114)); return mix(float3(g), c, k); }

// The time-of-day looks (corrections list #7, 2026-10-05), taken from Codex's paintings of the Sanctuary at dawn,
// day, dusk and night (tools/build_tod_luts.py): a colour look-up per mood, one for the land and one for the sky,
// in tod-lut.png (32 tiles of 32×32 per row of 32 pixels: rows 0–3 land dawn/day/dusk/night, rows 4–7 sky).
// Indexed in a gamma-2 space (sqrt of linear) so dark colours keep their precision.
float3 s2lut(texture2d<half> lut, float3 c, float row)
{
    constexpr sampler ls(address::clamp_to_edge, filter::linear, mip_filter::none);
    float3 g = sqrt(saturate(c));
    float b = g.b * 31.0, b0 = floor(b), b1 = min(b0 + 1.0, 31.0), f = b - b0;
    float x = (g.r * 31.0 + 0.5) / 1024.0, y = (row * 32.0 + g.g * 31.0 + 0.5) / 256.0;
    float3 s0 = float3(lut.sample(ls, float2(x + b0 / 32.0, y)).rgb);
    float3 s1 = float3(lut.sample(ls, float2(x + b1 / 32.0, y)).rgb);
    float3 o = mix(s0, s1, f);
    return o * o;
}

/// Which two moods the hour sits between, and how far (rows: 0 dawn, 1 day, 2 dusk, 3 night). The hour is the
/// "light hour" (SolarClock): sunrise is always 6:15, sunset 18:45, whatever the season.
float3 s2moods(float hour)
{
    if (hour < 4.5) return float3(3, 3, 0);
    if (hour < 6.5) return float3(3, 0, smoothstep(4.5, 6.5, hour));
    if (hour < 7.5) return float3(0, 0, 0);
    if (hour < 10.0) return float3(0, 1, smoothstep(7.5, 10.0, hour));
    if (hour < 15.5) return float3(1, 1, 0);
    if (hour < 18.5) return float3(1, 2, smoothstep(15.5, 18.5, hour));
    if (hour < 19.5) return float3(2, 2, 0);
    if (hour < 21.5) return float3(2, 3, smoothstep(19.5, 21.5, hour));
    return float3(3, 3, 0);
}

float3 s2look(texture2d<half> lut, float3 c, float skyM, float3 m)
{
    float3 land = s2lut(lut, c, m.x), sky = float3(0);
    if (m.z > 0.001) land = mix(land, s2lut(lut, c, m.y), m.z);
    if (skyM > 0.001) {
        sky = s2lut(lut, c, m.x + 4.0);
        if (m.z > 0.001) sky = mix(sky, s2lut(lut, c, m.y + 4.0), m.z);
        land = mix(land, sky, skyM);
    }
    return land;
}

// The light of the hour, shared by every layer of every world: the painted look of the hour (above), stars and a
// moon crossing the night sky, warm lights that keep glowing in the dark (lightM), and sun shafts at low sun.
float3 s2hourLight(float3 rgb, float2 uv, float skyM, float seaM, float hour, float sunU, float ratio, float t, texture2d<half> lut, float lightM)
{
    float asp = 0.4615 / ratio;
    float night = s2night(hour);
    float morning = smoothstep(5.0, 7.0, hour) * (1.0 - smoothstep(9.5, 11.5, hour));
    float day = smoothstep(9.5, 11.5, hour) * (1.0 - smoothstep(16.0, 18.0, hour));
    float dusk = saturate(1.0 - night - morning - day);
    // (The painted look of the hour is applied where each layer reads its painting: s2look.)
    if (night > 0.001 && skyM > 0.001) {
        // Stars (square cells: dots, not dashes), twinkling slowly; and the moon crossing the sky (20:00 → 06:00).
        float star = smoothstep(0.988, 1.0, s2hash(floor(uv * float2(470.0 / ratio * 0.4615, 470.0)))) * (0.6 + 0.4 * sin(t * 1.7 + uv.x * 90.0));
        float moonT = saturate(fmod(hour - 20.0 + 24.0, 24.0) / 10.0);
        float2 moonP = float2(sunU + mix(0.07, -0.33, moonT) * ratio, 0.8 + 0.09 * sin(moonT * 3.14159));
        float2 moonD = float2((uv.x - moonP.x) * asp, uv.y - moonP.y);
        float3 moon = float3(0.95, 0.95, 1.0) * (smoothstep(0.018, 0.014, length(moonD)) + exp(-length(moonD) * 18.0) * 0.22);
        rgb += (star * 0.85 * smoothstep(0.55, 0.85, uv.y) + moon) * skyM * night;
    }
    // Sun rays (low sun at dusk and morning, softer at midday, none at night).
    float2 sunP = float2(sunU, 0.82);
    float2 dv = uv - sunP; dv.x *= asp;
    float fall2 = exp(-length(dv) * 2.6);
    float rays = (dusk + morning * 0.8 + day * 0.35) * fall2;
    if (rays > 0.1) {           // only near the sun, where the rays really show (the rest of the screen skips it)
        float ang = atan2(dv.y, dv.x);
        float shafts = s2noise(float2(ang * 11.0 + t * 0.05, 1.7));
        shafts = smoothstep(0.45, 1.0, shafts) * smoothstep(0.1, 0.2, rays);   // fades in: no visible edge
        rgb += float3(1.0, 0.78, 0.5) * shafts * rays * (0.14 + 0.04 * sin(t * 0.7));
    }
    return rgb;
}

/// How dark the hour is (0 day … 1 night), for lights that carry further at night.
float s2night(float hour) { return saturate(1.0 - smoothstep(5.0, 7.0, hour) + smoothstep(20.5, 22.5, hour)); }

// The Hush (vitality): grey, cooler, misty and dimmer as vitality drops (nothing disappears).
float3 s2hush(float3 rgb, float2 uv, float vitality, float t)
{
    float hush = 1.0 - vitality;
    if (hush < 0.01) return rgb;
    float g = dot(rgb, float3(0.299, 0.587, 0.114));
    rgb = mix(rgb, float3(g) * float3(0.85, 0.9, 1.05), hush * 0.75);
    rgb = mix(rgb, float3(0.62, 0.65, 0.72), s2fbm(uv * float2(3.0, 6.0) + float2(t * 0.02, 0)) * hush * 0.45);
    return rgb * (1.0 - hush * 0.35);
}

// ---------- The Sanctuary in the Age of Stone (style anchor, decision 104) ----------
// custom texture (motion mask): R = water (sea, pools), G = falling water, B = brazier flames.
// custom: x = vitality, y/z = the Flame's position (uv), w = its light strength. roughness_scale = wind.
[[visible]]
void stoneLive(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    half3 pxTint = half3(params.material_constants().emissive_color());
    float2 pxSize = float2(params.textures().base_color().get_width(), params.textures().base_color().get_height());
    uv = s2pixelUV(uv, pxTint, pxSize);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);
    half4 mask = params.textures().custom().sample(s, tuv);
    float water = float(mask.r), fall = float(mask.g), fire = float(mask.b), skyM = float(mask.a);
    half4 base0 = params.textures().base_color().sample(s, tuv);
    // Where the land is cut out (the sky and sea layers show), do no work at all.
    if (base0.a < 0.004) {
        params.surface().set_base_color(half3(0));
        params.surface().set_emissive_color(half3(0));
        params.surface().set_opacity(0.0);
        return;
    }
    // Each effect below only runs where its mask is present: most pixels pay for none of them.
    // Clouds billow: a slow drifting warp in the sky only (the painted sky, when there's no sky layer).
    float2 cloud = float2(0.0);
    if (skyM > 0.01) {
        float2 cw = float2(s2noise(float2(uv.x * 3.0 + t * 0.03, uv.y * 4.0)) - 0.5, s2noise(float2(uv.x * 2.0 - t * 0.02, uv.y * 3.0 + 5.0)) - 0.5);
        cloud = (cw * 0.012 + float2(sin(t * 0.05 + uv.y * 6.0) * 0.004, 0)) * skyM;
    }

    float2 ripple = float2(sin(uv.y * 220.0 - t * 1.3 + sin(uv.x * 14.0 + t * 0.4)) * 0.0016,
                           sin(uv.x * 90.0 + t * 0.9) * 0.0008) * water;
    float2 flow = float2(0.0);
    if (fall > 0.01) {
        flow = float2((s2noise(float2(uv.x * 70.0, uv.y * 30.0 + t * 4.0)) - 0.5) * 0.0015,
                      (s2noise(float2(uv.x * 50.0, uv.y * 25.0 + t * 3.2)) - 0.5) * 0.004) * fall;
    }
    float wind = params.material_constants().roughness_scale();
    float green = smoothstep(0.02, 0.12, float(base0.g) - max(float(base0.r) * 0.85, float(base0.b)));
    // Foliage breathes all the time and bends further when a gust rolls across the scene (a travelling wave).
    float gust = 0.5 + 0.5 * sin(uv.x * 7.0 - t * 1.4);
    float sw = sin(t * 1.7 + uv.y * 14.0 + uv.x * 6.0) * 0.6 + sin(t * 3.1 + uv.y * 31.0) * 0.4;
    float2 sway = float2(sw * 0.0022 * green * (0.3 + uv.y) * (0.35 + wind * 1.3 * gust), sw * 0.0006 * green);
    {
        // Each plant in its own rhythm, gusts rolling across, and the wisteria blossoms moving too (decision 142).
        float3 b = float3(base0.rgb);
        float mx = max(b.r, max(b.g, b.b)), mn = min(b.r, min(b.g, b.b));
        float lilac = smoothstep(0.08, 0.2, b.b - b.g) * smoothstep(0.05, 0.15, b.r - b.g) * smoothstep(0.3, 0.5, mx) * step(0.12, mx - mn);
        float plant = saturate(green + lilac) * (1.0 - skyM) * (1.0 - water);
        float ph = s2noise(uv * 9.0) * 6.2831853;
        float roll = 0.5 + 0.5 * sin(uv.x * 5.0 - t * 1.1 + sin(uv.y * 3.0 + t * 0.35) * 1.5);
        float bend = sin(t * 1.5 + ph + uv.y * 10.0) * 0.6 + sin(t * 2.7 + ph * 1.7) * 0.4;
        sway = float2(bend * 0.0022 * (0.35 + roll * 1.1 + wind), cos(t * 1.2 + ph) * 0.0006) * plant;
    }
    float2 lick = float2(sin(uv.y * 520.0 - t * 11.0 + uv.x * 90.0) * 0.0007 + sin(uv.y * 210.0 - t * 6.3) * 0.0004,
                         -(0.5 + 0.5 * sin(t * 8.0 + uv.x * 400.0 + uv.y * 60.0)) * 0.0011) * saturate(fire * 1.5);   // flames lick upward
    half4 col = params.textures().base_color().sample(s, s2snap(tuv + ripple + flow + sway + cloud + lick, pxTint));
    if (params.material_constants().clearcoat_roughness_scale() > 0.5 && skyM > 0.01) {
        // (The map) its sea of clouds drifts gently, one sharp reading (decision 142).
        float2 drift = float2(sin(t * 0.04) * 0.004 + sin(t * 0.015) * 0.0025, sin(t * 0.028) * 0.001);
        col = mix(col, params.textures().base_color().sample(s, s2snap(tuv + drift + cloud, pxTint)), half(skyM));
    }
    float3 rgb = float3(col.rgb);

    // ---- Time of day (metallic_scale = hour / 24): night, morning, day, dusk (the painting is dusk). ----
    float hour = params.material_constants().metallic_scale() * 24.0;
    float sunU = params.material_constants().specular_scale();
    float ratio = max(0.05, params.material_constants().clearcoat_scale());
    float asp = 0.4615 / ratio;          // width ÷ height of what this texture shows
    // The painting as painted for this hour (Codex's repaintings, tod-lut.png); lanterns and fires keep their
    // own warm light in the dark.
    {
        float3 raw = rgb;
        rgb = s2look(params.textures().emissive_color(), rgb, skyM, s2moods(hour));
        rgb = mix(rgb, raw, saturate(fire * 1.2) * (0.3 + 0.6 * s2night(hour)));
        // Bright warm glows (the rune circle, sunlit gold) keep their painted gold at every hour.
        float rawY = dot(raw, float3(0.299, 0.587, 0.114));
        float glowK = smoothstep(0.5, 0.85, rawY) * saturate((raw.r - raw.b) * 2.5);
        rgb = mix(rgb, raw, glowK * 0.7 * (1.0 - s2night(hour)));          // (never at night: moonlight everywhere)
    }
    float night = 1.0 - smoothstep(5.0, 7.0, hour) + smoothstep(20.5, 22.5, hour);
    night = saturate(night);
    float morning = smoothstep(5.0, 7.0, hour) * (1.0 - smoothstep(9.5, 11.5, hour));
    float day = smoothstep(9.5, 11.5, hour) * (1.0 - smoothstep(16.0, 18.0, hour));
    float dusk = saturate(1.0 - night - morning - day);

    // ---- Water that moves: rolling swell bands, shimmering glints, foam where waterfalls land. ----
    if (water > 0.01) {
        float swell = sin(uv.y * 140.0 - t * 1.1 + sin(uv.x * 9.0 + t * 0.3) * 2.0) * 0.5 + 0.5;
        float swell2 = sin(uv.y * 260.0 + uv.x * 40.0 - t * 2.0) * 0.5 + 0.5;
        rgb *= 1.0 + water * ((swell - 0.5) * 0.10 + (swell2 - 0.5) * 0.05);
        float glint = smoothstep(0.93, 1.0, s2noise(float2(uv.x * 160.0 + sin(t * 0.25) * 3.0, uv.y * 420.0 - t * 1.6)));
        float3 glintCol = mix(float3(1.0, 0.86, 0.62), float3(0.75, 0.85, 1.0), night);
        rgb += glintCol * glint * water * (0.5 + 0.5 * sin(t * 6.0 + uv.x * 40.0)) * (0.9 - 0.5 * night);
    }
    // Waterfalls: bright streaks racing down, and churning foam at their feet.
    if (fall > 0.01) {
        float col2 = floor(uv.x * 260.0);
        float streak = fract(uv.y * 18.0 + t * (1.6 + fract(sin(col2 * 12.9) * 43758.5) * 0.8));
        rgb += float3(0.95, 0.97, 1.0) * fall * smoothstep(0.75, 1.0, streak) * 0.35;
        if (water > 0.01) {
            float foamN = s2noise(float2(uv.x * 120.0 + t * 1.5, uv.y * 120.0 - t * 2.0));
            rgb += float3(0.9) * fall * water * smoothstep(0.55, 0.9, foamN) * 0.4;
        }
    }

    // ---- Braziers that burn: flames lick upward, flicker, and throw a warm halo around them. ----
    // The halo is the fire mask blurred: one read from a small mip level (the GPU's own blur) instead of 8 reads.
    constexpr sampler sb(address::clamp_to_edge, filter::linear, mip_filter::linear);
    float halo = float(params.textures().custom().sample(sb, tuv, level(4.5)).b) * 1.6;
    if (halo > 0.005 || fire > 0.01) {
        float flick = 0.75 + 0.45 * s2noise(float2(t * 7.0, uv.x * 30.0 + uv.y * 20.0)) + 0.15 * sin(t * 13.0 + uv.x * 50.0);
        if (fire > 0.01) {
            float lick = s2noise(float2(uv.x * 80.0, uv.y * 40.0 - t * 5.0));
            rgb = mix(rgb, rgb * flick * 1.15 + float3(0.25, 0.1, 0.0) * lick, fire);
        }
        float glowK = 0.35 + 0.9 * night + 0.2 * dusk;
        rgb += float3(1.0, 0.55, 0.18) * halo * flick * glowK;
    }

    // Dehaze by day (Mathis: never blurry or grey): the painted mist is pulled back so the stone and leaves under it
    // show their color. Classic dehaze: J = (I − A·(1 − t)) / t, with A the mist's color and t how much shows through.
    {
        float mx = max(rgb.r, max(rgb.g, rgb.b)), mn = min(rgb.r, min(rgb.g, rgb.b));
        float satv = (mx - mn) / max(mx, 0.001);
        float misty = (1.0 - smoothstep(0.08, 0.3, satv)) * smoothstep(0.45, 0.85, mx) * (1.0 - fall);
        float amount = (day * 0.4 + morning * 0.3 + dusk * 0.25) * misty * 0.38;   // (the looks of the hour do most of it now)
        float3 A = float3(0.92, 0.9, 0.93);
        float tr = 1.0 - amount;
        rgb = max((rgb - A * amount) / tr, 0.0);
    }

    rgb = s2hourLight(rgb, uv, skyM, 0.0, hour, sunU, ratio, t, params.textures().emissive_color(), saturate(fire + halo * 0.6));

    // The Flame lights the circle around it (A1); at night its light carries much further.
    float2 fd = float2((uv.x - c.y) * asp, uv.y - c.z);
    float reach = 0.006 + 0.02 * night;
    // The painted glow breathes with the Flame's fire: its flicker comes from time here (no per-frame updates).
    float flickerS = (0.85 + 0.15 * (s2noise(float2(t * 7.0, 3.1)) * 2.0 - 1.0) + 0.05 * sin(t * 23.0) - 0.9) * 1.4;
    float light = (c.w * flickerS + night * 0.9 * c.w) * exp(-dot(fd, fd) / reach) * (fd.y < 0.0 ? 1.2 : 0.8);
    rgb += mix(rgb, float3(0.4, 0.22, 0.08), night) * float3(1.0, 0.62, 0.28) * light;

    // The Hush (vitality).
    rgb = s2hush(rgb, uv, c.x, t);

    params.surface().set_base_color(half3(0));
    if (s2isPixel(pxTint)) {
        // Pixel art: the art's own colours exactly (decision 149); fires flicker by brightness only.
        float fl = 0.92 + 0.08 * (s2noise(float2(t * 6.0 + uv.x * 50.0, uv.y * 40.0)) * 2.0 - 1.0);
        rgb = float3(col.rgb) * (1.0 + saturate(fire * 1.5) * (fl - 0.92) * 2.0);
    }

    rgb = depthStoneLight(rgb, uv, c.yz, c.w, t);
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(col.a);      // the land layer is cut out where the sky and the sea show
}

// ---------- The living layers of the Sanctuary world (decision 121) ----------
// Both layers share the land's parameters: custom.x = vitality, metallic_scale = hour / 24, specular_scale = the sun's u,
// clearcoat_scale = home width ÷ world width. Their uv is the world's uv (Codex's plates are painted on the same frame).

// The sky, far behind everything: the clouds really drift (slowly, to the right), billowing as they go, while the
// sun and its glow stay where they are. custom texture = the plate's blurred light (so only the clouds' detail moves).
[[visible]]
void skyLive(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    half3 pxTint = half3(params.material_constants().emissive_color());
    float2 pxSize = float2(params.textures().base_color().get_width(), params.textures().base_color().get_height());
    uv = s2pixelUV(uv, pxTint, pxSize);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float hour = params.material_constants().metallic_scale() * 24.0;
    float sunU = params.material_constants().specular_scale();
    float ratio = max(0.05, params.material_constants().clearcoat_scale());
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    constexpr sampler sm(address::mirrored_repeat, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);

    // Drift: about a screen width every few minutes; the billow changes the clouds' shapes as they travel.
    float2 drift = float2(t * 0.0012, 0.0);
    float2 billow = float2(s2noise(float2(uv.x * 4.0 - t * 0.02, uv.y * 5.0)) - 0.5,
                           s2noise(float2(uv.x * 3.0 + 7.0, uv.y * 4.0 - t * 0.015)) - 0.5) * 0.010;
    float2 cuv = tuv - drift + billow;
    float3 detail = float3(params.textures().base_color().sample(sm, cuv).rgb) - float3(params.textures().custom().sample(sm, cuv).rgb);
    float3 light = float3(params.textures().custom().sample(s, tuv).rgb);
    float3 rgb = light + detail;
    // The sun itself never drifts.
    float asp = 0.4615 / ratio;
    float2 sd = float2((uv.x - sunU) * asp, uv.y - 0.82);
    float sun = exp(-dot(sd, sd) / 0.0012);
    rgb = mix(rgb, float3(params.textures().base_color().sample(s, tuv).rgb), sun);
    rgb = s2look(params.textures().emissive_color(), rgb, 1.0, s2moods(hour));     // the sky as painted for this hour

    rgb = s2hourLight(rgb, uv, 1.0, 0.0, hour, sunU, ratio, t, params.textures().emissive_color(), 0.0);
    rgb = s2hush(rgb, uv, c.x, t);
    params.surface().set_base_color(half3(0));
    if (s2isPixel(pxTint)) rgb = float3(params.textures().base_color().sample(s, tuv).rgb);   // pixel art: its own colours
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(1.0);
}

// The open sea, between the sky and the land: Codex's painted water really moves. Its waves roll in toward the
// shore (bigger and faster near us, tiny and slow at the horizon), swell bands travel in, and the sun's path
// glitters. Alpha comes from the plate (0 above the horizon, where the sky shows).
constant float seaHorizon = 0.7931;      // the horizon's v in the world (tools/cut_layers.py)
[[visible]]
void seaLive(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    half3 pxTint = half3(params.material_constants().emissive_color());
    float2 pxSize = float2(params.textures().base_color().get_width(), params.textures().base_color().get_height());
    uv = s2pixelUV(uv, pxTint, pxSize);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float hour = params.material_constants().metallic_scale() * 24.0;
    float sunU = params.material_constants().specular_scale();
    float ratio = max(0.05, params.material_constants().clearcoat_scale());
    float wind = params.material_constants().roughness_scale();
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);
    float near = saturate((seaHorizon - uv.y) / seaHorizon);      // 0 at the horizon, 1 at the bottom of the world
    float persp = 0.08 + 0.92 * near * near;

    // Waves rolling in: two copies of the water, each sliding toward us and fading in and out in turn (a flow map),
    // with the phase broken up by noise so no pulse is ever visible.
    float jitter = s2noise(uv * float2(9.0, 22.0)) * 0.6;
    // A constant speed: multiplying time by a changing number would make the waves jump. Wind adds wobble instead.
    float p0 = fract(t * 0.25 + jitter), p1 = fract(t * 0.25 + jitter + 0.5);
    float2 dir = float2(0.18, 1.0) * 0.010 * persp;                   // down the screen = toward the shore
    float2 wob = float2(s2noise(float2(uv.x * 30.0, uv.y * 80.0 - t * 0.6)) - 0.5, 0.0) * (0.004 + 0.002 * wind) * persp;
    half4 c0 = params.textures().base_color().sample(s, tuv - dir * (p0 - 0.5) + wob);
    half4 c1 = params.textures().base_color().sample(s, tuv - dir * (p1 - 0.5) + wob);
    float w0 = 1.0 - abs(2.0 * p0 - 1.0);
    half4 col = c0 * half(w0) + c1 * half(1.0 - w0);
    col.a = params.textures().base_color().sample(s, tuv).a;
    float3 rgb = s2look(params.textures().emissive_color(), float3(col.rgb), 0.0, s2moods(hour));   // as painted for this hour
    // At night the painted sun path on the water goes too (the moon's glints come below).
    rgb = mix(rgb, float3(dot(rgb, float3(0.299, 0.587, 0.114))) * float3(0.5, 0.68, 1.05) * 0.8, s2night(hour) * 0.85);

    // Swell bands travelling in (spaced by perspective: crowded at the horizon, wide near us).
    float z = 1.0 / (0.06 + near);
    float swell = sin(z * 2.2 - t * 0.9 + s2noise(float2(uv.x * 3.0, t * 0.05)) * 2.5);
    rgb *= 1.0 + swell * 0.05 * (0.3 + near);
    // Glitter: concentrated on the sun's path, twinkling; scattered and blue-white under the moon.
    float night = s2night(hour);
    float path = exp(-pow((uv.x - sunU) / (0.012 + 0.05 * near), 2.0));
    float g = s2noise(float2(uv.x * 420.0 + sin(t * 0.3) * 4.0, uv.y * 900.0 * (1.2 - near) - t * 2.4));
    float glit = smoothstep(0.86, 1.0, g) * (0.5 + 0.5 * sin(t * 7.0 + uv.x * 300.0 + uv.y * 500.0));
    float3 glitCol = mix(float3(1.0, 0.85, 0.6), float3(0.8, 0.88, 1.0), night);
    rgb += glitCol * glit * (0.15 + 0.85 * path) * (0.9 - 0.4 * night);

    rgb = s2hourLight(rgb, uv, 0.0, 1.0, hour, sunU, ratio, t, params.textures().emissive_color(), 0.0);
    rgb = s2hush(rgb, uv, c.x, t);
    params.surface().set_base_color(half3(0));
    if (s2isPixel(pxTint)) rgb = float3(col.rgb);           // pixel art: its own colours
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(col.a);
}

// ---------- The Spark: the first Flame, a pure spirit of fire (decision 125) ----------
// Its flame tip sways and licks upward, its body breathes; the face stays still and crisp.
// custom: x mood, y brightness, zw follow-through drag (from its motion).
[[visible]]
void sparkLive(realitykit::geometry_parameters params)
{
    float2 uv = params.geometry().uv0();
    float3 p = params.geometry().model_position();
    float4 c = params.uniforms().custom_parameter();
    float t = params.uniforms().time();
    float energy = 0.6 + 0.6 * c.x;
    float tip = smoothstep(0.42, 1.0, uv.y);
    float body = 1.0 - tip;
    float sway = (sin(t * 2.1 + uv.y * 6.0) * 0.011 + sin(t * 5.3 + uv.y * 13.0) * 0.004) * tip * tip * energy;
    float lick = (sin(t * 3.4 + uv.x * 9.0) * 0.5 + 0.5) * 0.008 * tip * tip * tip * energy;
    float breath = sin(t * 1.6) * 0.016;
    float2 drag = c.zw * tip * tip;
    params.geometry().set_model_position_offset(float3(sway + p.x * breath * 0.7 * body + drag.x,
                                                       lick + p.y * breath * 0.45 * body + drag.y, 0));
}

// Its fire: flames flow upward through it (the face stays crisp), a warm pulse inside, and the light of the hour
// on it so it belongs to the world: a sunset rim on the sun's side at dusk, a cooler daylight, at night its own glow
// with a touch of moonlight. Its edge is a little soft, like the painting. metallic_scale = hour / 24.
[[visible]]
void sparkFire(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    half3 pxTint = half3(params.material_constants().emissive_color());
    float2 pxSize = float2(params.textures().base_color().get_width(), params.textures().base_color().get_height());
    uv = s2pixelUV(uv, pxTint, pxSize);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float energy = 0.6 + 0.6 * c.x;
    float hour = params.material_constants().metallic_scale() * 24.0;
    float face = 1.0 - smoothstep(0.55, 1.0, length((uv - float2(0.5, 0.3)) / float2(0.33, 0.15)));
    float flame = (0.35 + 0.65 * smoothstep(0.35, 0.8, uv.y)) * (1.0 - face);
    float w1 = sin(uv.y * 24.0 - t * 4.0 + sin(uv.x * 9.0 + t * 0.7) * 2.0);
    float w2 = sin(uv.y * 45.0 - t * 6.6 + uv.x * 19.0);
    float2 d = float2(w1 * 0.004 + w2 * 0.0016, -abs(w2) * 0.003) * flame * energy;
    constexpr sampler s(address::clamp_to_edge, filter::linear, mip_filter::linear);
    float2 suv = float2(uv.x, 1.0 - uv.y) + d;
    half4 col = params.textures().base_color().sample(s, suv);
    // A soft edge: the outline's alpha comes from a slightly blurred read (the painting has no razor edges).
    float aSoft = float(params.textures().base_color().sample(s, suv, bias(1.2)).a);
    float a = mix(float(col.a), aSoft, 0.6);
    float3 rgb = float3(col.rgb);
    // Your ember's color (SparkTint): the fire's hue turns (YIQ rotation keeps its brightness), the eyes stay as painted.
    {
        float turn = params.material_constants().roughness_scale() * 6.2831853;
        float satK = params.material_constants().clearcoat_scale() * 2.0;
        float Y = dot(rgb, float3(0.299, 0.587, 0.114));
        float k = smoothstep(0.12, 0.32, Y);              // only the darkest strokes (pupils, lashes) keep their paint
        float I = dot(rgb, float3(0.596, -0.274, -0.322));
        float Q = dot(rgb, float3(0.211, -0.523, 0.312));
        float cs = cos(turn), sn = -sin(turn);          // the same direction as Core Image's hue adjust (the pictures)
        float I2 = (I * cs - Q * sn) * satK, Q2 = (I * sn + Q * cs) * satK;
        float3 tinted = float3(Y + 0.956 * I2 + 0.621 * Q2, Y - 0.272 * I2 - 0.647 * Q2, Y - 1.106 * I2 + 1.703 * Q2);
        float strength = params.material_constants().specular_scale();      // subtle: the painted fire shows through
        // Only hints (Mathis): the heart of the fire keeps its painted color; the ember's color lives at the rim
        // and in the flame's tips, fading in toward the outside.
        float aWide = float(params.textures().base_color().sample(s, suv, bias(4.0)).a);
        float rimW = saturate((1.0 - aWide) * 2.2);
        float tips = smoothstep(0.55, 0.92, uv.y);
        float hint = saturate(max(rimW, tips * 0.85)) * (1.0 - smoothstep(0.78, 0.97, Y));   // the bright heart stays
        rgb = mix(rgb, max(tinted, 0.0), k * hint * strength * step(0.0001, abs(turn) + abs(satK - 1.0)));
    }
    // A warm pulse in its lower body, like a heartbeat.
    float core = 1.0 - smoothstep(0.0, 0.22, length((uv - float2(0.5, 0.24)) / float2(1.0, 0.8)));
    float beat = pow(0.5 + 0.5 * sin(t * 2.3), 8.0) + 0.35 * pow(0.5 + 0.5 * sin(t * 2.3 - 0.6), 12.0);
    rgb += float3(0.35, 0.22, 0.06) * core * beat * 0.5 * energy;
    rgb *= 1.0 + 0.06 * w1 * flame;
    // The light of the hour.
    float night = s2night(hour);
    float morning = smoothstep(5.0, 7.0, hour) * (1.0 - smoothstep(9.5, 11.5, hour));
    float day = smoothstep(9.5, 11.5, hour) * (1.0 - smoothstep(16.0, 18.0, hour));
    float dusk = saturate(1.0 - night - morning - day);
    float aSun = float(params.textures().base_color().sample(s, suv + float2(0.04, -0.01)).a);   // the sun is to the right
    float rim = saturate((float(col.a) - aSun) * 1.6);
    rgb += float3(1.0, 0.62, 0.38) * rim * (0.55 * dusk + 0.35 * morning + 0.15 * day);
    rgb = mix(rgb, rgb * float3(0.97, 0.99, 1.03), day * 0.6);
    float aMoon = float(params.textures().base_color().sample(s, suv + float2(-0.03, -0.015)).a);
    rgb += float3(0.35, 0.45, 0.8) * saturate((float(col.a) - aMoon) * 1.6) * night * 0.35;
    rgb *= 1.0 + night * 0.08;
    params.surface().set_base_color(half3(0));
    // (pixel art: its own colours; no palette cut)
    params.surface().set_emissive_color(half3(rgb * c.y));
    params.surface().set_opacity(half(a));
}


// Decision 169: high-fidelity painted volume with an animated crown and independently phased outer flames.
// The central face remains rigid; no second pixel grid or palette reduction.
[[visible]]
void depthLive(realitykit::geometry_parameters params) {
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float crown = smoothstep(0.70, 1.0, uv.y);
    float side = smoothstep(0.22, 0.43, abs(uv.x - 0.5)) * smoothstep(0.08, 0.25, uv.y);
    float move = max(crown, side * 0.7);
    float wave = sin(t * 2.2 + uv.y * 9.0 + uv.x * 7.0) + 0.35 * sin(t * 4.3 - uv.y * 14.0);
    params.geometry().set_model_position_offset(float3(
        wave * 0.004 * move + c.z * crown * 0.45,
        sin(t * 2.8 + uv.x * 11.0) * 0.0025 * move + c.w * crown * 0.4,
        sin(t * 1.7 + uv.x * 9.0) * 0.0015 * side));
}

[[visible]]
void depthFire(realitykit::surface_parameters params) {
    float2 uv = params.geometry().uv0();
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    constexpr sampler s(address::clamp_to_edge, filter::linear, mip_filter::linear);
    half4 col = params.textures().base_color().sample(s, float2(uv.x, 1.0 - uv.y));
    float faceY = params.material_constants().roughness_scale();
    float face = 1.0 - smoothstep(0.7, 1.0, length((uv - float2(0.52, faceY)) / float2(0.32, 0.16)));
    float edge = smoothstep(0.2, 0.46, abs(uv.x - 0.5));
    float fire = max(smoothstep(0.72, 1.0, uv.y), edge) * (1.0 - face);
    float pulse = 1.0 + 0.025 * sin(t * 2.3) + 0.018 * sin(t * 5.1 + uv.y * 15.0) * fire;
    float3 rgb = float3(col.rgb) * pulse * clamp(c.y, 0.7, 1.03);
    float night = s2night(params.material_constants().metallic_scale() * 24.0);
    rgb *= mix(float3(1.0), float3(0.98, 0.98, 1.025), night * edge * 0.4);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(col.a);
}

[[visible]]
void depthContact(realitykit::surface_parameters params) {
    float2 d = (params.geometry().uv0() - 0.5) * 2.0;
    float a = exp(-dot(d, d) * 4.0) * 0.52 * (1.0 - smoothstep(0.7, 1.0, length(d)));
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(0.085, 0.035, 0.018));
    params.surface().set_opacity(half(a));
}

// The composed Sanctuary keeps the approved painting's palette and perspective intact.
[[visible]]
void stageWorld(realitykit::surface_parameters params) {
    float2 uv = params.geometry().uv0();
    float2 tuv = float2(uv.x, 1.0 - uv.y);
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    constexpr sampler s(address::clamp_to_edge, filter::linear, mip_filter::linear);
    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float core = smoothstep(-0.05, 0.08, edge);
    bool expanded = params.material_constants().clearcoat_roughness_scale() > 0.5;
    float4 mask = float4(params.textures().custom().sample(s, tuv)) * (expanded ? core : 1.0);
    float2 flow = float2(sin(tuv.y * 190.0 - t * 1.4) * 0.0007, sin(t * 1.7 + tuv.x * 90.0) * 0.0004) * mask.r;
    float3 rgb = float3(params.textures().base_color().sample(s, tuv + flow).rgb);
    if (expanded && core < 1.0) {
        // The original painting remains untouched at home. Its continuation uses the same mesh and lighting.
        // Registered against the delivered outpaint; its actual inset differs from the requested canvas.
        float2 outerUV = (tuv - 0.5) * float2(0.547633, 0.723277) + float2(0.503511, 0.508919);
        float3 outer = float3(params.textures().emissive_color().sample(s, outerUV).rgb);
        rgb = mix(outer, rgb, core);
    }
    rgb *= 1.0 + mask.b * (0.025 * sin(t * 3.1) + 0.015 * sin(t * 6.7));
    float night = s2night(params.material_constants().metallic_scale() * 24.0);
    rgb *= mix(float3(1.0), float3(0.76, 0.8, 0.96), night * 0.55);
    rgb = depthStoneLight(rgb, uv, c.yz, c.w * 0.45, t);
    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(1.0);
}
