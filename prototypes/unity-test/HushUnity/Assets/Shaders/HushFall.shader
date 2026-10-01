// A waterfall: a ribbon of streaks falling and brightening at the bottom (additive mist).
Shader "Hush/Waterfall"
{
    Properties { _Color ("Color", Color) = (0.9,0.95,1,0.8) _Speed ("Speed", Float) = 1.4 }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha ZWrite Off Cull Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial) half4 _Color; float _Speed; CBUFFER_END
            struct A { float4 pos : POSITION; float2 uv : TEXCOORD0; };
            struct V { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; float fog : TEXCOORD1; };
            V vert (A i) { V o; o.pos = TransformObjectToHClip(i.pos.xyz); o.uv = i.uv; o.fog = ComputeFogFactor(o.pos.z); return o; }
            float hash(float n) { return frac(sin(n) * 43758.5453); }
            half4 frag (V i) : SV_Target
            {
                float col = floor(i.uv.x * 24);
                float streak = frac(i.uv.y * (1.2 + hash(col) * 0.8) + _Time.y * _Speed * (0.8 + hash(col + 7) * 0.5));
                float s = smoothstep(0.0, 0.5, streak) * (0.55 + 0.45 * hash(col + 3));
                float edge = smoothstep(0, 0.15, i.uv.x) * smoothstep(1, 0.85, i.uv.x);
                float bottom = 1 + smoothstep(0.25, 0, i.uv.y) * 1.5;
                half3 c = MixFog(_Color.rgb * bottom, i.fog);
                return half4(c, _Color.a * s * edge * min(1, bottom));
            }
            ENDHLSL
        }
    }
}
