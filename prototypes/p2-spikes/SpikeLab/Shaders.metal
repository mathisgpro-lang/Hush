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

    // Water moves again from restoration level ~1.
    float water = 1.0 - smoothstep(0.12, 0.2, uv.y);
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

    // The Hushed Grove: grey, cool and dim; color returns with restoration, and early around lit lanterns.
    float localLight = lit * pool;
    float sat = max(0.1 + 0.9 * smoothstep(0.0, 0.9, r), localLight * 0.85);
    float3 graded = mix(float3(lum) * float3(0.82, 0.88, 1.02), rgb, sat);
    graded *= max(0.42 + 0.58 * smoothstep(0.0, 0.8, r), 0.42 + 0.5 * localLight);
    // Unlit lanterns dim their own painted glow; lit ones shine (flickering, flaring right after relighting).
    float3 dark = float3(lum * 0.22) * float3(0.8, 0.85, 1.0);
    float3 shining = rgb * flicker * 1.12 + float3(1.0, 0.8, 0.45) * flare * 1.4;
    graded = mix(graded, mix(dark, shining, lit), core);
    graded += float3(1.0, 0.7, 0.35) * pool * lit * 0.06 * flicker + float3(1.0, 0.75, 0.4) * pool * flare * 0.35;
    float m0 = 0.0;

    // Mist: thick when Hushed, lifting with restoration; vitality thickens or thins it day to day.
    float mistAmount = (1.0 - smoothstep(0.0, 0.85, r)) * 0.55 + (1.0 - vitality) * 0.25;
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
    // Clouds billow: a slow drifting warp in the sky only.
    float2 cw = float2(s2noise(float2(uv.x * 3.0 + t * 0.03, uv.y * 4.0)) - 0.5, s2noise(float2(uv.x * 2.0 - t * 0.02, uv.y * 3.0 + 5.0)) - 0.5);
    float2 cloud = (cw * 0.012 + float2(sin(t * 0.05 + uv.y * 6.0) * 0.004, 0)) * skyM;

    float2 ripple = float2(sin(uv.y * 220.0 - t * 1.3 + sin(uv.x * 14.0 + t * 0.4)) * 0.0016,
                           sin(uv.x * 90.0 + t * 0.9) * 0.0008) * water;
    float2 flow = float2((s2noise(float2(uv.x * 70.0, uv.y * 30.0 + t * 4.0)) - 0.5) * 0.0015,
                         (s2noise(float2(uv.x * 50.0, uv.y * 25.0 + t * 3.2)) - 0.5) * 0.006) * fall;
    half4 base0 = params.textures().base_color().sample(s, tuv);
    float wind = params.material_constants().roughness_scale();
    float green = smoothstep(0.02, 0.12, float(base0.g) - max(float(base0.r) * 0.85, float(base0.b)));
    float2 sway = float2(sin(t * 2.0 + uv.y * 30.0 + uv.x * 8.0) * 0.003 * wind * green * (0.3 + uv.y), 0);
    half4 col = params.textures().base_color().sample(s, tuv + ripple + flow + sway + cloud);
    float3 rgb = float3(col.rgb);

    // ---- Time of day (metallic_scale = hour / 24): night, morning, day, dusk (the painting is dusk). ----
    float hour = params.material_constants().metallic_scale() * 24.0;
    float night = 1.0 - smoothstep(5.0, 7.0, hour) + smoothstep(20.5, 22.5, hour);
    night = saturate(night);
    float morning = smoothstep(5.0, 7.0, hour) * (1.0 - smoothstep(9.5, 11.5, hour));
    float day = smoothstep(9.5, 11.5, hour) * (1.0 - smoothstep(16.0, 18.0, hour));
    float dusk = saturate(1.0 - night - morning - day);

    // ---- Water that moves: rolling swell bands, shimmering glints, foam where waterfalls land. ----
    float swell = sin(uv.y * 140.0 - t * 1.1 + sin(uv.x * 9.0 + t * 0.3) * 2.0) * 0.5 + 0.5;
    float swell2 = sin(uv.y * 260.0 + uv.x * 40.0 - t * 2.0) * 0.5 + 0.5;
    rgb *= 1.0 + water * ((swell - 0.5) * 0.10 + (swell2 - 0.5) * 0.05);
    float glint = smoothstep(0.93, 1.0, s2noise(float2(uv.x * 160.0 + sin(t * 0.25) * 3.0, uv.y * 420.0 - t * 1.6)));
    float3 glintCol = mix(float3(1.0, 0.86, 0.62), float3(0.75, 0.85, 1.0), night);
    rgb += glintCol * glint * water * (0.5 + 0.5 * sin(t * 6.0 + uv.x * 40.0)) * (0.9 - 0.5 * night);
    // Waterfalls: bright streaks racing down, and churning foam at their feet.
    float col2 = floor(uv.x * 260.0);
    float streak = fract(uv.y * 18.0 + t * (1.6 + fract(sin(col2 * 12.9) * 43758.5) * 0.8));
    rgb += float3(0.95, 0.97, 1.0) * fall * smoothstep(0.75, 1.0, streak) * 0.35;
    float foamN = s2noise(float2(uv.x * 120.0 + t * 1.5, uv.y * 120.0 - t * 2.0));
    rgb += float3(0.9) * fall * water * smoothstep(0.55, 0.9, foamN) * 0.4;

    // ---- Braziers that burn: flames lick upward, flicker, and throw a warm halo around them. ----
    float halo = 0.0;
    for (int k = 0; k < 8; k++) {
        float a = float(k) * 0.785398;
        halo += float(params.textures().custom().sample(s, tuv + float2(cos(a) * 0.022, sin(a) * 0.012)).b);
    }
    halo /= 8.0;
    float flick = 0.75 + 0.45 * s2noise(float2(t * 7.0, uv.x * 30.0 + uv.y * 20.0)) + 0.15 * sin(t * 13.0 + uv.x * 50.0);
    float lick = s2noise(float2(uv.x * 80.0, uv.y * 40.0 - t * 5.0));
    rgb = mix(rgb, rgb * flick * 1.15 + float3(0.25, 0.1, 0.0) * lick, fire);
    float glowK = 0.35 + 0.9 * night + 0.2 * dusk;
    rgb += float3(1.0, 0.55, 0.18) * halo * flick * glowK;

    // ---- The light of the hour. ----
    float g0 = dot(rgb, float3(0.299, 0.587, 0.114));
    // Day: brighter, cooler, the sky turns blue.
    float3 dayRGB = mix(rgb, float3(g0) * float3(0.95, 1.0, 1.05), 0.25) * 1.12 + float3(0.0, 0.02, 0.05);
    float3 daySky = mix(float3(0.45, 0.66, 0.92), float3(0.85, 0.92, 1.0), saturate(uv.y * 1.3 - 0.4)) * (0.85 + 0.25 * g0);
    dayRGB = mix(dayRGB, daySky + (rgb - g0) * 0.15, skyM * 0.85);
    // Morning: soft pink-gold, gentle haze.
    float3 mornRGB = mix(rgb, float3(g0) * float3(1.05, 0.95, 1.0), 0.3) * 1.05 + float3(0.04, 0.02, 0.05);
    // Night: deep blue, the world falls asleep; stars and a moon glow; fires and the Flame shine.
    float3 nightRGB = float3(g0) * float3(0.32, 0.40, 0.66) * 0.62 + rgb * 0.08;
    float star = smoothstep(0.985, 1.0, s2hash(floor(uv * float2(220.0, 470.0)))) * (0.6 + 0.4 * sin(t * 3.0 + uv.x * 90.0));
    float3 nightSky = mix(float3(0.05, 0.07, 0.18), float3(0.16, 0.2, 0.38), saturate(1.0 - (uv.y - 0.7) * 3.0));
    // The moon crosses the sky through the night (20:00 → 06:00).
    float moonT = saturate(fmod(hour - 20.0 + 24.0, 24.0) / 10.0);
    float2 moonP = float2(mix(0.95, 0.55, moonT), 0.8 + 0.09 * sin(moonT * 3.14159));
    float2 moonD = float2((uv.x - moonP.x) * 0.46, uv.y - moonP.y);
    nightSky += float3(0.95, 0.95, 1.0) * (smoothstep(0.018, 0.014, length(moonD)) + exp(-length(moonD) * 18.0) * 0.25);
    nightRGB = mix(nightRGB, nightSky + star, skyM);
    rgb = rgb * dusk + dayRGB * day + mornRGB * morning + nightRGB * night;

    // Sun rays (low sun at dusk and morning, softer at midday, none at night).
    float2 sunP = float2(0.88, 0.82);
    float2 dv = uv - sunP; dv.x *= 0.46;
    float ang = atan2(dv.y, dv.x);
    float shafts = s2noise(float2(ang * 9.0 + t * 0.06, 1.7)) * 0.65 + s2noise(float2(ang * 23.0 - t * 0.04, 4.2)) * 0.35;
    shafts = smoothstep(0.45, 1.0, shafts);
    float fall2 = exp(-length(dv) * 2.6);
    rgb += float3(1.0, 0.78, 0.5) * shafts * fall2 * (0.14 + 0.04 * sin(t * 0.7)) * (dusk + morning * 0.8 + day * 0.35);

    // The Flame lights the circle around it (A1); at night its light carries much further.
    float2 fd = float2((uv.x - c.y) * 0.46, uv.y - c.z);
    float reach = 0.006 + 0.02 * night;
    float light = (c.w + night * 0.9) * exp(-dot(fd, fd) / reach) * (fd.y < 0.0 ? 1.2 : 0.8);
    rgb += mix(rgb, float3(0.4, 0.22, 0.08), night) * float3(1.0, 0.62, 0.28) * light;

    // The Hush (vitality).
    float hush = 1.0 - c.x;
    float g = dot(rgb, float3(0.299, 0.587, 0.114));
    rgb = mix(rgb, float3(g) * float3(0.85, 0.9, 1.05), hush * 0.75);
    rgb = mix(rgb, float3(0.62, 0.65, 0.72), s2fbm(uv * float2(3.0, 6.0) + float2(t * 0.02, 0)) * hush * 0.45);
    rgb *= 1.0 - hush * 0.35;

    params.surface().set_base_color(half3(0));
    params.surface().set_emissive_color(half3(rgb));
    params.surface().set_opacity(1.0);
}
