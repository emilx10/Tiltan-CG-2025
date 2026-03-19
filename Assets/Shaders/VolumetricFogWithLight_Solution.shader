Shader "Custom/VolumetricFogWithLight"
{
    Properties
    {
        _Color      ("Light Color",   Color)        = (1,1,1,1)
        _Density    ("Density",       Range(0,5))   = 1
        _Steps      ("Steps",         Range(1,64))  = 32

        // Part A additions
        _FogFloor   ("Fog Floor Y",   Float)        = 0
        _FogFalloff ("Fog Falloff",   Range(0,1))   = 0.3
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "Queue"      = "Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Part B: Lighting include — gives us GetMainLight()
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
            float  _Density;
            int    _Steps;

            // Part A: new uniforms
            float _FogFloor;
            float _FogFalloff;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir    = normalize(i.positionWS - rayOrigin);

                float lightAccumulation = 0;
                float stepSize          = 1.0 / _Steps;

                // Part B: retrieve the main directional light once, before the loop
                Light mainLight = GetMainLight();

                
                for (int step = 0; step < _Steps; step++)
                {
                    float  t         = step * stepSize;
                    float3 samplePos = rayOrigin + rayDir * t;

                    // Part A: height-based density
                    // Density is maximum at _FogFloor and falls off exponentially
                    // as samplePos.y rises above it. Below _FogFloor the max()
                    // clamps to zero so the exponent stays at exp(0) = 1.0 — full
                    // density at and below the floor level.
                    float heightFade    = exp(-max(samplePos.y - _FogFloor, 0.0) * _FogFalloff);
                    float densitySample = _Density * heightFade;

                    lightAccumulation += densitySample * stepSize;
                }

                // Part B: tint the fog colour by the directional light's colour.
                // Rotating the light from noon-white to sunset-orange now shifts
                // the fog colour accordingly.
                float3 fogColor = _Color.rgb * mainLight.color.rgb;

                return float4(fogColor, lightAccumulation);
            }

            ENDHLSL
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SOLUTION NOTES  —  what each part actually changed and why
// ═══════════════════════════════════════════════════════════════════════════
//
//  Part A  — Height Fog
//  ───────────────────────────────────────────────────────────────────────
//  The only line that changed inside the loop was densitySample.
//  Everything else — the ray setup, the loop structure, the accumulation
//  formula, the output — is identical to the starter.
//  This is the key lesson: the entire character of a volumetric effect
//  lives in the density function. The march loop is just infrastructure.
//
//  exp(-max(y - floor, 0) * falloff) gives us:
//    y <  _FogFloor  →  max() = 0  →  exp(0)  = 1.0  (full density)
//    y == _FogFloor  →  max() = 0  →  exp(0)  = 1.0  (full density)
//    y >  _FogFloor  →  exp decays → density falls off toward zero
//  _FogFalloff controls how steep the falloff is:
//    0.1  = gentle gradient, fog fades slowly with height
//    0.8  = sharp cutoff, fog barely extends above the floor
//
//  Part B  — Directional Light Tint
//  ───────────────────────────────────────────────────────────────────────
//  GetMainLight() returns the scene's primary directional light as a
//  Light struct.  mainLight.color is its RGB colour.
//  Multiplying _Color by mainLight.color means the fog inherits the
//  light's tint — warm orange at sunset, cool blue at night.
//  Note: GetMainLight() is called ONCE before the loop, not inside it.
//  The light colour is uniform across all samples — calling it 64 times
//  per pixel would waste GPU cycles for identical results.

