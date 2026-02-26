Shader "Custom/VolumetricFogWithLight"
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

            // Declared uniforms — must match Properties block above
            float4 _Color;
            float  _Density;
            int    _Steps;

            

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                // Camera position in world space
                float3 rayOrigin = _WorldSpaceCameraPos;

                // Direction from camera toward this fragment's world position
                float3 rayDir = normalize(i.positionWS - rayOrigin);

                float lightAccumulation = 0;
                float stepSize = 1.0 / _Steps;

                
                Light mainLight = GetMainLight();
                

                // Raymarch loop — walks from 0 to 1 along the ray
                for (int step = 0; step < _Steps; step++)
                {
                    float  t         = step * stepSize;
                    float3 samplePos = rayOrigin + rayDir * t;

                    // ── TODO part A: replace this constant with a height-based formula ──
                    //
                    //    Current behaviour: every sample has the same density regardless
                    //    of where in the world it sits.
                    //
                    //    Goal: density should be highest at _FogFloor and fall off
                    //    exponentially as samplePos.y rises above it.
                    //
                    //    Hint: exp( -max(samplePos.y - _FogFloor, 0.0) * _FogFalloff )
                    //
                    float densitySample = _Density;     // ← REPLACE THIS LINE
                    // ──────────────────────────────────────────────────────────────────

                    lightAccumulation += densitySample * stepSize;
                }

                // ─── TODO Part B: multiply _Color by the light's colour ──
                
                return float4(_Color.rgb, lightAccumulation);
                // ─────────────────────────────────────────────────────────
            }

            ENDHLSL
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE  CHECKLIST
// ═══════════════════════════════════════════════════════════════════════════
//
//  Part A  — Height Fog                                           
//  ───────────────────────────────────────────────────────────────────────
//  1. Uncomment the two Properties: _FogFloor and _FogFalloff
//  2. Uncomment their float declarations above vert()
//  3. Replace the densitySample line with the height-based formula
//  4. In the Inspector: _FogFloor = 0,  _FogFalloff = 0.3
//     → fog should pool at ground level and thin toward the sky
//
//  Part B  — Directional Light Tint                               
//  ───────────────────────────────────────────────────────────────────────
//  1. Uncomment the Lighting.hlsl include at the top
//  2. Uncomment   Light mainLight = GetMainLight();   before the loop
//  3. Change the return line to multiply _Color.rgb by mainLight.color.rgb
//  4. In the Editor: rotate the Directional Light
//     → fog colour should shift as the light changes
//
//  Part C  — Observe Step Artifacts                                
//  ───────────────────────────────────────────────────────────────────────
//  1. Set _Steps = 4 in the Inspector  → look for concentric banding rings
//  2. Set _Steps = 64                  → banding disappears
//  3. Write a comment below this block: what did you observe?
//     What is the tradeoff between a low and a high step count?
//
// ═══════════════════════════════════════════════════════════════════════════
