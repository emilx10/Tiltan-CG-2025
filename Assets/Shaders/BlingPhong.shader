Shader "Universal Render Pipeline/BlinnPhong"
{
    Properties
    {
        [MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor ("Color", Color) = (1,1,1,1)

        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(1,256)) = 32
        _SpecStrength ("Specular Strength", Range(0,1)) = 1

        [Toggle(_ALPHATEST_ON)] _AlphaClip ("Alpha Clip", Float) = 0
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma shader_feature_local _ALPHATEST_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
                float fogCoord    : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _SpecColor;
                float _Shininess;
                float _SpecStrength;
                float _Cutoff;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.uv = v.uv;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            float3 BlinnPhongSpecular(
                float3 normalWS,
                float3 viewDirWS,
                float3 lightDirWS,
                float shininess,
                float strength
            )
            {
                float3 H = normalize(lightDirWS + viewDirWS);
                float NdotH = saturate(dot(normalWS, H));
                return pow(NdotH, shininess) * strength;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;

                #if defined(_ALPHATEST_ON)
                    clip(albedo.a - _Cutoff);
                #endif

                float3 normalWS = normalize(i.normalWS);
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(i.positionWS));

                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);

                float NdotL = saturate(dot(normalWS, lightDir));
                float3 diffuse = albedo.rgb * mainLight.color * NdotL;

                float3 spec = BlinnPhongSpecular(
                    normalWS,
                    viewDirWS,
                    lightDir,
                    _Shininess,
                    _SpecStrength
                ) * _SpecColor.rgb * mainLight.color;

                float3 color = diffuse + spec;

                #if defined(_ADDITIONAL_LIGHTS)
                uint lightCount = GetAdditionalLightsCount();
                for (uint li = 0; li < lightCount; li++)
                {
                    Light light = GetAdditionalLight(li, i.positionWS);
                    float3 ldir = normalize(light.direction);

                    float ndotl = saturate(dot(normalWS, ldir));
                    float3 diff = albedo.rgb * light.color * ndotl;

                    float3 s = BlinnPhongSpecular(
                        normalWS,
                        viewDirWS,
                        ldir,
                        _Shininess,
                        _SpecStrength
                    ) * _SpecColor.rgb * light.color;

                    color += diff + s;
                }
                #endif

                color = MixFog(color, i.fogCoord);
                return float4(color, albedo.a);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
