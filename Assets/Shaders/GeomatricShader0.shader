Shader "Custom/GeometryGrass"
{
    Properties
    {
        _Color ("Grass Color", Color) = (0.2, 0.8, 0.2, 1)

        _BladeHeight ("Blade Height", Float) = 0.5
        _BladeWidth  ("Blade Width", Float) = 0.05
        _BladeCount  ("Blades Per Triangle", Int) = 3
        _WindStrength ("Wind Strength", Float) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                float3 objPos : TEXCOORD0;
            };

            struct g2f
            {
                float4 clipPos : SV_POSITION;
                float heightLerp : TEXCOORD0;
            };

            float4 _Color;
            float _BladeHeight;
            float _BladeWidth;
            int _BladeCount;
            float _WindStrength;

            // Pseudo random
            float rand(float3 co)
            {
                return frac(sin(dot(co, float3(12.9898,78.233,45.5432))) * 43758.5453);
            }

            v2g Vert(appdata v)
            {
                v2g o;
                o.objPos = v.vertex.xyz;
                return o;
            }

            // Each blade = 2 triangles = 6 vertices
            // Allow up to 4 blades safely
            [maxvertexcount(24)]
            void Geo(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                float3 p0 = input[0].objPos;
                float3 p1 = input[1].objPos;
                float3 p2 = input[2].objPos;

                float3 triCenter = (p0 + p1 + p2) / 3.0;

                for (int b = 0; b < _BladeCount; b++)
                {
                    float r1 = rand(triCenter + b);
                    float r2 = rand(triCenter + b * 2.17);

                    // Random point inside triangle
                    float3 pos = lerp(lerp(p0, p1, r1), p2, r2);

                    // Wind sway
                    float wind = sin(_Time.y * 2 + pos.x * 3) * _WindStrength;

                    float3 up = float3(0,1,0);
                    float3 side = float3(_BladeWidth, 0, 0);

                    float3 tip = pos + up * _BladeHeight + float3(wind,0,0);

                    float3 v0 = pos - side;
                    float3 v1 = pos + side;
                    float3 v2 = tip - side * 0.5;
                    float3 v3 = tip + side * 0.5;

                    g2f o;

                    // Bottom vertices darker
                    o.heightLerp = 0;
                    o.clipPos = UnityObjectToClipPos(float4(v0,1)); triStream.Append(o);
                    o.clipPos = UnityObjectToClipPos(float4(v1,1)); triStream.Append(o);

                    // Tip vertices lighter
                    o.heightLerp = 1;
                    o.clipPos = UnityObjectToClipPos(float4(v2,1)); triStream.Append(o);

                    triStream.RestartStrip();

                    o.heightLerp = 0;
                    o.clipPos = UnityObjectToClipPos(float4(v1,1)); triStream.Append(o);

                    o.heightLerp = 1;
                    o.clipPos = UnityObjectToClipPos(float4(v3,1)); triStream.Append(o);
                    o.clipPos = UnityObjectToClipPos(float4(v2,1)); triStream.Append(o);

                    triStream.RestartStrip();
                }
            }

            float4 Frag(g2f i) : SV_Target
            {
                float4 bottom = _Color * 0.5;
                float4 top = _Color;
                return lerp(bottom, top, i.heightLerp);
            }

            ENDHLSL
        }
    }
}
