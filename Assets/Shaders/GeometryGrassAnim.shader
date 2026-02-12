Shader "Custom/GeometryGrassAnim"
{
     Properties
    {
        _GrassColor ("Grass Color", Color) = (0.2, 0.8, 0.2, 1)
        _BladeHeight ("Blade Height", Float) = 0.2
        _BladeWidth ("Blade Width", Float) = 0.05
        _WindDirection ("Wind Direction", Vector) = (1,0,0)
        _WindStrength ("Wind Strength", Float) = 0.1
        _WindSpeed ("Wind Speed", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Off
            ZWrite On

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma geometry Geo
            #pragma fragment Frag
            #pragma target 4.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2g
            {
                float4 clipPos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct g2f
            {
                float4 clipPos : SV_POSITION;
            };

            float4 _GrassColor;
            float _BladeHeight;
            float _BladeWidth;
            float3 _WindDirection;
            float _WindStrength;
            float _WindSpeed;

            // ============================================================
            // Vertex Shader
            // ============================================================
            v2g Vert (appdata v)
            {
                v2g o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            // ============================================================
            // Geometry Shader – Grass Generation (Tip Only Animation)
            // ============================================================

            [maxvertexcount(6)]
            void Geo(
                triangle v2g input[3],
                inout TriangleStream<g2f> triStream
            )
            {
                // 1. Triangle center and up vector
                float3 centerWorld =
                    (input[0].worldPos +
                     input[1].worldPos +
                     input[2].worldPos) / 3.0;

                float3 up = normalize(
                    input[0].normal +
                    input[1].normal +
                    input[2].normal
                );

                // 2. Compute base vertices (grounded)
                // float3 right = normalize(cross(up, float3(0,1,0)));
                // this is to ensure right is not zero vector - if up is (0,1,0) - cross product of two parallel vectors (0,1,0) x (0,1,0) is zero!
                float3 arbitrary = (abs(up.y) > 0.99) ? float3(1,0,0) : float3(0,1,0);
                // alternative:
                // up += 0.001 * float3(0,0,1); // tiny tilt
                // up = normalize(up);
                // float3 right = normalize(cross(up, float3(0,1,0)));
                
                float3 right = normalize(cross(up, arbitrary));
                
                float3 baseLeft  = centerWorld - right * _BladeWidth;
                float3 baseRight = centerWorld + right * _BladeWidth;

                // 3. Compute animated tip
                // Only the tip moves!
                float t = _Time.y * _WindSpeed;

                // Use a combination of sin and cos to make natural swaying
                float windOffsetX = sin(t + centerWorld.x * 2.0) * _WindStrength;
                float windOffsetZ = cos(t + centerWorld.z * 2.0) * _WindStrength;

                float3 tip = centerWorld + up * _BladeHeight + (_WindDirection * windOffsetX) + (_WindDirection.zxy * windOffsetZ);

                g2f o;

                // --------------------------------------------------------
                // Triangle 1
                // --------------------------------------------------------
                o.clipPos = UnityWorldToClipPos(baseLeft);
                triStream.Append(o);

                o.clipPos = UnityWorldToClipPos(tip);
                triStream.Append(o);

                o.clipPos = UnityWorldToClipPos(baseRight);
                triStream.Append(o);

                triStream.RestartStrip();

                // --------------------------------------------------------
                // Triangle 2 (back face)
                // --------------------------------------------------------
                o.clipPos = UnityWorldToClipPos(baseRight);
                triStream.Append(o);

                o.clipPos = UnityWorldToClipPos(tip);
                triStream.Append(o);

                o.clipPos = UnityWorldToClipPos(baseLeft);
                triStream.Append(o);

                triStream.RestartStrip();
            }

            // ============================================================
            // Fragment Shader
            // ============================================================

            float4 Frag (g2f i) : SV_Target
            {
                return _GrassColor;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}