// The dusk sky: a gradient from a warm horizon to a violet zenith, a low sun with a wide glow, faint high clouds.
Shader "Hush/Sky"
{
    Properties
    {
        _Zenith ("Zenith", Color) = (0.22,0.18,0.38,1) _Mid ("Mid", Color) = (0.85,0.48,0.42,1) _Horizon ("Horizon", Color) = (1,0.72,0.42,1)
        _SunDir ("Sun direction", Vector) = (0,0.08,1,0) _SunColor ("Sun", Color) = (1,0.85,0.6,1)
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" "RenderPipeline"="UniversalPipeline" }
        Cull Off ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial) half4 _Zenith, _Mid, _Horizon, _SunColor; float4 _SunDir; CBUFFER_END
            struct A { float4 pos : POSITION; };
            struct V { float4 pos : SV_POSITION; float3 dir : TEXCOORD0; };
            V vert (A i) { V o; o.pos = TransformObjectToHClip(i.pos.xyz); o.dir = i.pos.xyz; return o; }
            float hash(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }
            float noise(float2 p) { float2 i = floor(p), f = frac(p); float2 u = f*f*(3-2*f);
                return lerp(lerp(hash(i), hash(i+float2(1,0)), u.x), lerp(hash(i+float2(0,1)), hash(i+float2(1,1)), u.x), u.y); }
            half4 frag (V i) : SV_Target
            {
                float3 d = normalize(i.dir);
                float h = d.y;
                half3 c = h > 0 ? lerp(lerp(_Horizon.rgb, _Mid.rgb, saturate(h * 4)), _Zenith.rgb, saturate((h - 0.15) * 1.6)) : _Horizon.rgb * 0.9;
                float3 sd = normalize(_SunDir.xyz);
                float s = saturate(dot(d, sd));
                c += _SunColor.rgb * (pow(s, 1200) * 6 + pow(s, 40) * 0.6 + pow(s, 6) * 0.25);
                // Faint high clouds catching the sunset.
                float2 cp = d.xz / max(d.y + 0.25, 0.05) * 1.5 + _Time.y * 0.004;
                float cl = saturate((noise(cp) * 0.6 + noise(cp * 2.3) * 0.3 + noise(cp * 5.1) * 0.1 - 0.55) * 3) * saturate(h * 6);
                c = lerp(c, lerp(_Mid.rgb, _SunColor.rgb, pow(s, 3)) * 1.15, cl * 0.6);
                return half4(c, 1);
            }
            ENDHLSL
        }
    }
}
