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
