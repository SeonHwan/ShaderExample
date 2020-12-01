Shader "Custom/Shader_Rim"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
        _RimFactor ("RimFactor", float) = 3
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
            Name "MyRimShader"
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
            float4 _RimColor;
            float _RimFactor;
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

            half4 frag (v2f i) : SV_TARGET
            {
                Light mainLight = GetMainLight(i.shadowCoord);
                i.normal = normalize(i.normal);

                //Diffuse
                float3 lambert = LightingLambert(mainLight.color, mainLight.direction, i.normal);
                float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                //Specular
                float3 specular = LightingSpecular(mainLight.color, mainLight.direction, i.normal, i.viewDir, 1, 1);

                //GI
                half3 ambient = SampleSH(i.normal);

                //combine
                // c.rgb *= lambert * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                // c.rgb += ambient + specular;

                //Rim
                c.rgb += pow(1 - dot(i.normal, i.viewDir), _RimFactor) * _RimColor;

                //fog
                //c.rgb = MixFog(c.rgb, i.fogCoord);
                
                return c;
            }
            ENDHLSL
        }
    }
}
