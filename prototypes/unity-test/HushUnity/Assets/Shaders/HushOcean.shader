// The ocean: gentle waves, sky-colored reflections by view angle (fresnel), a sun glitter path, foam around rocks
// (scene depth), and the scene's fog.
Shader "Hush/Ocean"
{
    Properties
    {
        _Deep ("Deep", Color) = (0.05,0.25,0.33,1) _Shallow ("Shallow", Color) = (0.15,0.65,0.68,1) _Sky ("Sky reflection", Color) = (0.95,0.62,0.48,1)
        _SunDir ("Sun direction", Vector) = (0,0.08,1,0) _SunColor ("Sun", Color) = (1,0.85,0.6,1) _Foam ("Foam distance", Float) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent-10" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            CBUFFER_START(UnityPerMaterial) half4 _Deep, _Shallow, _Sky, _SunColor; float4 _SunDir; float _Foam; CBUFFER_END
            struct A { float4 pos : POSITION; };
            struct V { float4 pos : SV_POSITION; float3 wpos : TEXCOORD0; float3 n : TEXCOORD1; float4 sp : TEXCOORD2; float fog : TEXCOORD3; };
            float3 wave(float3 p, out float3 n)
            {
                float t = _Time.y;
                float h = sin(p.x * 0.35 + t * 0.9) * 0.18 + sin(p.z * 0.27 + t * 0.7) * 0.22 + sin((p.x + p.z) * 0.9 + t * 1.6) * 0.06;
                float dx = cos(p.x * 0.35 + t * 0.9) * 0.063 + cos((p.x + p.z) * 0.9 + t * 1.6) * 0.054;
                float dz = cos(p.z * 0.27 + t * 0.7) * 0.059 + cos((p.x + p.z) * 0.9 + t * 1.6) * 0.054;
                n = normalize(float3(-dx, 1, -dz));
                return float3(p.x, p.y + h, p.z);
            }
            V vert (A i)
            {
                V o; float3 w = TransformObjectToWorld(i.pos.xyz); float3 n;
                w = wave(w, n);
                o.wpos = w; o.n = n; o.pos = TransformWorldToHClip(w); o.sp = ComputeScreenPos(o.pos); o.fog = ComputeFogFactor(o.pos.z);
                return o;
            }
            float hash(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }
            half4 frag (V i) : SV_Target
            {
                float3 v = normalize(GetCameraPositionWS() - i.wpos);
                float3 n = normalize(i.n + float3(sin(i.wpos.x * 3.1 + _Time.y * 2.3), 0, cos(i.wpos.z * 2.7 + _Time.y * 1.9)) * 0.06);
                float fres = pow(1 - saturate(dot(n, v)), 4);
                half3 c = lerp(lerp(_Deep.rgb, _Shallow.rgb, 0.35), _Sky.rgb, saturate(fres * 1.3));
                float3 sd = normalize(_SunDir.xyz);
                float3 r = reflect(-v, n);
                float glit = pow(saturate(dot(r, sd)), 220) * 3 + pow(saturate(dot(r, sd)), 18) * 0.25;
                c += _SunColor.rgb * glit;
                // Foam where the water meets rocks.
                float2 suv = i.sp.xy / i.sp.w;
                float sceneZ = LinearEyeDepth(SampleSceneDepth(suv), _ZBufferParams);
                float waterZ = LinearEyeDepth(i.pos.z, _ZBufferParams);
                float diff = sceneZ - waterZ;
                float foam = saturate(1 - diff / _Foam) * (0.6 + 0.4 * sin(_Time.y * 2 + i.wpos.x * 4 + i.wpos.z * 3));
                c = lerp(c, half3(1, 0.97, 0.92), saturate(foam));
                float a = saturate(0.85 + fres * 0.15);
                c = MixFog(c, i.fog);
                return half4(c, a);
            }
            ENDHLSL
        }
    }
}
