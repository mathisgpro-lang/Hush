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
    float bright = params.uniforms().custom_parameter().y;
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
