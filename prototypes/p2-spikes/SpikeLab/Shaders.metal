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
    float t = params.uniforms().time();
    float4 c = params.uniforms().custom_parameter();
    float r = c.x, vitality = c.y;
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 tuv = float2(uv.x, 1.0 - uv.y);

    // Water moves again from restoration level ~1. New realms carry their water mask in the lights map's alpha
    // (metallic_scale = 1); the Grove's older map has none, so its water is the bottom band.
    float water = params.material_constants().metallic_scale() > 0.5
        ? float(params.textures().custom().sample(s, tuv).a)
        : 1.0 - smoothstep(0.12, 0.2, uv.y);
    float flowing = smoothstep(0.15, 0.4, r);
    float2 ripple = float2(sin(uv.y * 150.0 - t * 1.4 + sin(uv.x * 10.0 + t * 0.5)) * 0.002,
                           sin(uv.x * 60.0 + t * 1.0) * 0.001) * water * flowing;
    half4 base0 = params.textures().base_color().sample(s, tuv);
    float wind = params.material_constants().roughness_scale();
    float green = smoothstep(0.02, 0.12, float(base0.g) - max(float(base0.r) * 0.85, float(base0.b)));
    float2 sway = float2(sin(t * 2.0 + uv.y * 28.0 + uv.x * 7.0) * 0.003 * wind * green * (0.4 + uv.y), 0);
    half4 col = params.textures().base_color().sample(s, tuv + ripple + sway);
    float3 rgb = float3(col.rgb);

    // Lanterns (custom texture: R = order of the nearest lantern, G = the lantern itself, B = its pool of light).
    // R (order) must not be interpolated between lanterns or at its edge, so it's read with nearest filtering.
    constexpr sampler sn(address::clamp_to_edge, filter::nearest);
    half4 lm = params.textures().custom().sample(s, tuv);
    float order = float(params.textures().custom().sample(sn, tuv).r), core = float(lm.g), pool = float(lm.b);
    float lit = step(0.001, order) * smoothstep(order - 0.004, order, r);
    float lum = dot(rgb, float3(0.299, 0.587, 0.114));
    float flicker = 0.92 + 0.08 * sin(t * 9.0 + order * 300.0) * sin(t * 3.7 + order * 91.0);
    float flare = (1.0 - smoothstep(0.0, 0.006, abs(order - c.z))) * exp(-c.w * 2.5);

    // The Grove is always vivid (Mathis: never grey); while it sleeps, it is only a little dimmer and cooler, and
    // its lanterns are dark. Restoring it warms it up and lights them one by one.
    float localLight = lit * pool;
    float sat = max(0.8 + 0.25 * smoothstep(0.0, 0.9, r), localLight);
    float3 graded = mix(float3(lum), rgb, sat);
    graded *= mix(float3(0.86, 0.9, 1.0), float3(1.04, 1.02, 0.98), smoothstep(0.0, 0.8, r));
    graded *= max(0.8 + 0.25 * smoothstep(0.0, 0.8, r), 0.8 + 0.3 * localLight);
    // Unlit lanterns dim their own painted glow; lit ones shine (flickering, flaring right after relighting).
    float3 dark = rgb * float3(0.32, 0.3, 0.34);          // an unlit lantern: its own colors, just without fire
    float3 shining = rgb * flicker * 1.12 + float3(1.0, 0.8, 0.45) * flare * 1.4;
    graded = mix(graded, mix(dark, shining, lit), core);
    graded += float3(1.0, 0.7, 0.35) * pool * lit * 0.06 * flicker + float3(1.0, 0.75, 0.4) * pool * flare * 0.35;
    float m0 = 0.0;

    // Mist: thick when Hushed, lifting with restoration; vitality thickens or thins it day to day.
    float mistAmount = (1.0 - smoothstep(0.0, 0.85, r)) * 0.14 + (1.0 - vitality) * 0.25;   // a light veil, never a fog
    float m = s2fbm(uv * float2(3.0, 5.0) + float2(t * 0.015, 0)) * mistAmount * (1.0 - localLight * 0.8) + m0;
    graded = mix(graded, float3(0.6, 0.63, 0.7), m);

    params.surface().set_base_color(half3(0));
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

float3 s2hourLight(float3 rgb, float2 uv, float skyM, float seaM, float hour, float sunU, float ratio, float t)
{
    float asp = 0.4615 / ratio;
    float night = saturate(1.0 - smoothstep(5.0, 7.0, hour) + smoothstep(20.5, 22.5, hour));
    float morning = smoothstep(5.0, 7.0, hour) * (1.0 - smoothstep(9.5, 11.5, hour));
    float day = smoothstep(9.5, 11.5, hour) * (1.0 - smoothstep(16.0, 18.0, hour));
    float dusk = saturate(1.0 - night - morning - day);
    // ---- The light of the hour. Day and morning are clear and vivid, never grey (Mathis, 2026-10-02). ----
    // Each mood is only computed when its hour is on (most of the day only one is): every pixel of three
    // full-screen layers runs this, so skipping the hidden ones is what keeps the phone at 60 frames a second.
    float g0 = dot(rgb, float3(0.299, 0.587, 0.114));
    float3 outRGB = rgb * dusk;
    float3 daySky = float3(0), seaDay = float3(0);
    float seaAmt = 0.0;
    if (day + morning > 0.001) {
        // Day sky: a clear blue with the painted clouds turned white (in the sunset plate the clouds are lavender
        // and the gaps orange, so "how little red over blue" finds the clouds).
        if (skyM > 0.001) {
            float cloud = 1.0 - smoothstep(0.2, 0.42, rgb.r - rgb.b);
            float3 blue = mix(float3(0.62, 0.80, 0.98), float3(0.24, 0.52, 0.93), smoothstep(0.78, 1.0, uv.y));
            float3 cloudCol = mix(float3(0.80, 0.84, 0.94), float3(1.0, 0.99, 0.97), smoothstep(0.36, 0.62, g0));
            daySky = mix(blue, cloudCol, cloud * 0.9);
        }
        // Day sea: blue and turquoise, keeping the painted waves' light and shade.
        if (seaM > 0.001) {
            float3 seaBase = mix(float3(0.06, 0.64, 0.74), float3(0.16, 0.44, 0.80), smoothstep(0.3, 0.79, uv.y));
            seaDay = seaBase * (0.55 + 0.9 * g0) + float3(1.0) * smoothstep(0.82, 0.96, g0) * 0.5;
            seaAmt = seaM * (0.35 + 0.55 * smoothstep(0.3, 0.75, uv.y));
        }
    }
    if (day > 0.001) {
        // Day land: the dusk's orange balanced toward neutral, a touch more saturated and brighter.
        float3 dayRGB = s2sat(rgb * float3(0.92, 1.0, 1.09), 1.15) * 1.07;
        dayRGB = mix(dayRGB, daySky, skyM);
        dayRGB = mix(dayRGB, seaDay, seaAmt);
        outRGB += dayRGB * day;
    }
    if (morning > 0.001) {
        // Morning: soft and pastel, pink and gold; a sky between dawn and blue.
        float3 mornRGB = s2sat(rgb * float3(1.0, 0.97, 1.04), 1.05) * 1.04 + float3(0.03, 0.01, 0.03);
        mornRGB = mix(mornRGB, mix(rgb, daySky, 0.45) * 1.05, skyM);
        mornRGB = mix(mornRGB, mix(mornRGB, seaDay, 0.5), seaAmt);
        outRGB += mornRGB * morning;
    }
    if (night > 0.001) {
        // Night: deep blue, the world falls asleep; stars and a moon glow; fires and the Flame shine.
        float3 nightRGB = float3(g0) * float3(0.32, 0.40, 0.66) * 0.62 + rgb * 0.08;
        if (skyM > 0.001) {
            float star = smoothstep(0.988, 1.0, s2hash(floor(uv * float2(470.0 / ratio * 0.4615, 470.0)))) * (0.6 + 0.4 * sin(t * 3.0 + uv.x * 90.0));   // square cells: dots, not dashes
            float3 nightSky = mix(float3(0.05, 0.07, 0.18), float3(0.16, 0.2, 0.38), saturate(1.0 - (uv.y - 0.7) * 3.0));
            // The moon crosses the sky through the night (20:00 → 06:00).
            float moonT = saturate(fmod(hour - 20.0 + 24.0, 24.0) / 10.0);
            float2 moonP = float2(sunU + mix(0.07, -0.33, moonT) * ratio, 0.8 + 0.09 * sin(moonT * 3.14159));
            float2 moonD = float2((uv.x - moonP.x) * asp, uv.y - moonP.y);
            nightSky += float3(0.95, 0.95, 1.0) * (smoothstep(0.018, 0.014, length(moonD)) + exp(-length(moonD) * 18.0) * 0.25);
            nightRGB = mix(nightRGB, nightSky + star, skyM);
        }
        outRGB += nightRGB * night;
    }
    rgb = outRGB;

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
    half4 col = params.textures().base_color().sample(s, tuv + ripple + flow + sway + cloud);
    float3 rgb = float3(col.rgb);

    // ---- Time of day (metallic_scale = hour / 24): night, morning, day, dusk (the painting is dusk). ----
    float hour = params.material_constants().metallic_scale() * 24.0;
    float sunU = params.material_constants().specular_scale();
    float ratio = max(0.05, params.material_constants().clearcoat_scale());
    float asp = 0.4615 / ratio;          // width ÷ height of what this texture shows
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
        float amount = (day + morning * 0.7 + dusk * 0.25) * misty * 0.38;
        float3 A = float3(0.92, 0.9, 0.93);
        float tr = 1.0 - amount;
        rgb = max((rgb - A * amount) / tr, 0.0);
    }

    rgb = s2hourLight(rgb, uv, skyM, 0.0, hour, sunU, ratio, t);

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

    rgb = s2hourLight(rgb, uv, 1.0, 0.0, hour, sunU, ratio, t);
    rgb = s2hush(rgb, uv, c.x, t);
    params.surface().set_base_color(half3(0));
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
    float3 rgb = float3(col.rgb);

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

    rgb = s2hourLight(rgb, uv, 0.0, 1.0, hour, sunU, ratio, t);
    rgb = s2hush(rgb, uv, c.x, t);
    params.surface().set_base_color(half3(0));
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
        rgb = mix(rgb, max(tinted, 0.0), k * strength * step(0.0001, abs(turn) + abs(satK - 1.0)));
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
    params.surface().set_emissive_color(half3(rgb * c.y));
    params.surface().set_opacity(half(a));
}
