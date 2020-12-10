Shader "Custom/DitherShader"
{
    Properties
    {
        _BaseMap ("Albedo (RGB)", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 200
        
        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            CBUFFER_END

            struct appdata
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 uv : TEXCOORD0;
            };

            v2f vert(appdata i)
            {
                v2f o;

                o.vertex = TransformObjectToHClip(i.positionOS);
                o.normal = TransformObjectToWorldNormal(i.normalOS);
                o.uv = ComputeScreenPos(o.vertex);

                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                half2 uv =  i.uv.xy / i.uv.w;

                i.normal = SafeNormalize(i.normal);
                // uv.y * (_ScreenParams.y / _ScreenParams.x)
                // Dither 텍스처가 화면 해상도 기준으로 늘려지므로, 정방형으로 맞추기 위한 연산
                float4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, float2(uv.x, uv.y * (_ScreenParams.y / _ScreenParams.x)));

                return c;
            }
            ENDHLSL
        }
    }
}
