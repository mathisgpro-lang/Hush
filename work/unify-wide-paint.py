from pathlib import Path
p=Path('prototypes/p2-spikes/SpikeLab/Shaders.metal');s=p.read_text()
start=s.index('void groveRestoreImpl(');end=s.index('// The light strand',start)
a=s[start:end]
a=a.replace('params.textures().base_color().sample(s, tuv)', 'worldPaint(params, tuv, registration)')
a=a.replace('params.textures().base_color().sample(s, s2snap(tuv + ripple * (1.0 - paleW) + sway + flow + breeze + cloud + lick, pxTint))', 'worldPaint(params, s2snap(tuv + ripple * (1.0 - paleW) + sway + flow + breeze + cloud + lick, pxTint), registration)')
a=a.replace('params.textures().base_color().sample(s, s2snap(tuv + drift + cloud, pxTint))', 'worldPaint(params, s2snap(tuv + drift + cloud, pxTint), registration)')
cut=a.index('    float2 surroundUV =');stop=a.index('    float3 anchor =',cut);a=a[:cut]+a[stop:]
helper='''// A finished outpaint is one continuous color surface. Never crossfade different architecture at its old border.
half4 worldPaint(realitykit::surface_parameters params, float2 uv, float4 registration) {
    constexpr sampler s(address::clamp_to_edge, filter::linear, mip_filter::linear);
    return registration.x > 0.0
        ? params.textures().ambient_occlusion().sample(s, (uv - 0.5) * registration.xy + registration.zw)
        : params.textures().base_color().sample(s, uv);
}
'''
s=s[:start]+helper+a+s[end:]
s=s.replace('float3 rgb = float3(params.textures().base_color().sample(s, tuv + flow).rgb);\n    if (expanded && core < 1.0)', 'float3 rgb = float3(worldPaint(params, tuv + flow, registration).rgb);\n    if (!registered && expanded && core < 1.0)')
p.write_text(s)
