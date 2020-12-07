Shader "Custom/CubeMapShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _Cube ("CubeMap", Cube) = ""{}
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

            #pragma shader_feature _NORMALMAP
            
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

            TEXTURECUBE(_Cube);
            SAMPLER(sampler_Cube);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            float4 _NormalMap_ST;
            
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
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
                float3 worldRefl : TEXCOORD5;
                half4 normalWS : TEXCOORD6;
                half4 tangentWS : TEXCOORD7;
                half4 bitangentWS : TEXCOORD8;
                float2 normalCoord : TEXCOORD9;
            };

            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);

                o.vertex = vertexInput.positionCS;
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalCoord = TRANSFORM_TEX(v.texcoord, _NormalMap);
                o.worldPos = vertexInput.positionWS;
                o.viewDir = GetCameraPositionWS() - o.worldPos;
                
                o.normal = normalInput.normalWS;

                o.normalWS = half4(normalInput.normalWS, o.viewDir.x);
                o.tangentWS = half4(normalInput.tangentWS, o.viewDir.y);
                o.bitangentWS = half4(normalInput.bitangentWS, o.viewDir.z);
                
                o.fogCoord = ComputeFogFactor(o.vertex.z);
                
                o.shadowCoord = TransformWorldToShadowCoord(o.worldPos);
                
                o.worldRefl = reflect(-o.viewDir, o.normal);
                
                return o;
            }

            half4 frag (v2f i) : SV_TARGET
            {
                Light mainLight = GetMainLight(i.shadowCoord);
                
                // i.normal = normalize(i.normal);
                i.normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.normalCoord));

                //Diffuse
                float3 lambert = LightingLambert(mainLight.color, mainLight.direction, i.normal);
                float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                float4 re = SAMPLE_TEXTURECUBE(_Cube, sampler_Cube, i.worldRefl);
                //Specular
                float3 specular = LightingSpecular(mainLight.color, mainLight.direction, i.normal, i.viewDir, 1, 1);

                //GI
                half3 ambient = SampleSH(i.normal);

                //combine
                // c.rgb *= lambert * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                // c.rgb += ambient + specular;

                //Rim
                c.rgb *= (lambert * 0.5) + (re.rgb * 0.5);

                //fog
                //c.rgb = MixFog(c.rgb, i.fogCoord);
                
                return c;
            }
            ENDHLSL
        }
    }
}
