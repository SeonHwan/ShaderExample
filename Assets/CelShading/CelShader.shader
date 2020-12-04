Shader "Custom/CelShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
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
            Name "Forward"
            Tags{"LightMode" = "UniversalForward"}
            Cull Back
            
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

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
                float fogCoord : TEXCOORD1;
                float4 shadowCoord : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 viewDir : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.fogCoord = ComputeFogFactor(o.vertex.z);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.shadowCoord = TransformWorldToShadowCoord(o.worldPos);
                o.viewDir = GetCameraPositionWS() - o.worldPos;
                
                return o;
            }

            float LightingToon(float lightCol, float3 lightDir, float3 normal)
            {
                float ndotl = dot(lightDir, normal) * 0.5 + 0.5;
                if(ndotl > 0.6)
                    ndotl = 1;
                else
                    ndotl = 0.3;

                return ndotl * lightCol;
            }
            
            half4 frag (v2f i) : SV_TARGET
            {
                Light mainLight = GetMainLight();
                i.normal = normalize(i.normal);

                // float halfLambert = LightingLambert(mainLight.color, mainLight.direction, i.normal);
                float halfLambert =LightingToon(mainLight.color, mainLight.direction, i.normal);
                float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                
                //combine
                c.rgb *= halfLambert * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                
                return c;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Off
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
            
        }
    }
}
