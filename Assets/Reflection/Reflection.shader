Shader "Custom/Reflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
            "Queue" = "Geometry+0"
        }
        LOD 100
        
        Pass
        {
            Name "Reflection"
            Tags{"LightMode" = "UniversalForward"}
            Cull Back
            
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                // float fogCoord : TEXCOORD1;
                // float4 shadowCoord : TEXCOORD2;
                // float3 worldPos : TEXCOORD3;
                // float3 viewDir : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                
                return o;
            }

            half4 frag (v2f i) : SV_TARGET
            {
                Light mainLight = GetMainLight();
                i.normal = normalize(i.normal);
                
                float3 lambert = LightingLambert(mainLight.color, mainLight.direction, i.normal);
                float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                c.rgb *= lambert;

                return c;
            }
            ENDHLSL
        }
    }
}
