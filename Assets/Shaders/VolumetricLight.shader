Shader "Custom/VolumetricLight"
{
    Properties
    {
        _Color ("Light Color", Color) = (1,1,1,1)
        _Density ("Density", Range(0,5)) = 1
        _Steps ("Steps", Range(1,64)) = 32
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            float4 _Color;
            float _Density;
            int _Steps;

            Varyings vert (Attributes v)
            {
                Varyings o;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                o.positionCS = TransformWorldToHClip(o.positionWS);

                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                // Camera position
                float3 rayOrigin = _WorldSpaceCameraPos;

                // Direction from camera to pixel
                float3 rayDir = normalize(i.positionWS - rayOrigin);

                float lightAccumulation = 0;

                float stepSize = 1.0 / _Steps;

                // Raymarch loop
                for(int step = 0; step < _Steps; step++)
                {
                    float t = step * stepSize;

                    float3 samplePos = rayOrigin + rayDir * t;

                    // Simple density function
                    float densitySample = _Density;

                    lightAccumulation += densitySample * stepSize;
                }

                return float4(_Color.rgb, lightAccumulation);
            }

            ENDHLSL
        }
    }
}
