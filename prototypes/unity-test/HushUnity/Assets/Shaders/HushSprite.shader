// Unlit sprite for the 3D world (the Flame's parts, glows): uses the SpriteRenderer's texture and color. _Additive = 1 for glows.
Shader "Hush/Sprite"
{
    Properties { _MainTex ("Sprite", 2D) = "white" {} _Tint ("Tint", Color) = (1,1,1,1) [Enum(Alpha,10,Additive,1)] _DstBlend ("Blend", Float) = 10 }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" }
        Blend SrcAlpha [_DstBlend] ZWrite Off Cull Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial) float4 _MainTex_ST; half4 _Tint; float _DstBlend; CBUFFER_END
            struct A { float4 pos : POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; };
            struct V { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; float fog : TEXCOORD1; };
            V vert (A i) { V o; o.pos = TransformObjectToHClip(i.pos.xyz); o.uv = i.uv; o.color = i.color * _Tint; o.fog = ComputeFogFactor(o.pos.z); return o; }
            half4 frag (V i) : SV_Target
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * i.color;
                c.rgb = MixFog(c.rgb, i.fog * 0.35);       // the Flame stays clear and warm, a touch of the scene's haze
                return c;
            }
            ENDHLSL
        }
    }
}
