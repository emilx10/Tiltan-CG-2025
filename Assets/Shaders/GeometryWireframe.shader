Shader "Custom/GeometryWireframe"
{
   
    Properties
    {
        _WireColor ("Wireframe Color", Color) = (0,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            // Draw lines instead of triangles
            Cull Off
            ZWrite On

            HLSLPROGRAM

            // ============================================================
            // Shader stages
            // ============================================================
            #pragma vertex Vert
            #pragma geometry Geo
            #pragma fragment Frag
            #pragma target 4.0

            #include "UnityCG.cginc"

            // ============================================================
            // Structs
            // ============================================================

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2g
            {
                float4 clipPos : SV_POSITION;
            };

            struct g2f
            {
                float4 clipPos : SV_POSITION;
            };

            // ============================================================
            // Properties
            // ============================================================

            float4 _WireColor;

            // ============================================================
            // Vertex Shader
            // ============================================================

            v2g Vert (appdata v)
            {
                v2g o;

                // Keep object space position

                // Standard object → clip space transform
                o.clipPos = UnityObjectToClipPos(v.vertex);

                return o;
            }

            // ============================================================
            // Geometry Shader – Wireframe (Object Space)
            // ============================================================

            // We output LINES, not triangles
            // Each triangle → 3 edges → 6 vertices
            [maxvertexcount(6)]
            void Geo(
                triangle v2g input[3],
                inout LineStream<g2f> lineStream
            )
            {
                g2f o;

                // Edge 0: v0 → v1
                o.clipPos = input[0].clipPos;
                lineStream.Append(o);

                o.clipPos = input[1].clipPos;
                lineStream.Append(o);

                lineStream.RestartStrip();

                // Edge 1: v1 → v2
                o.clipPos = input[1].clipPos;
                lineStream.Append(o);

                o.clipPos = input[2].clipPos;
                lineStream.Append(o);

                lineStream.RestartStrip();

                // Edge 2: v2 → v0
                o.clipPos = input[2].clipPos;
                lineStream.Append(o);

                o.clipPos = input[0].clipPos;
                lineStream.Append(o);

                lineStream.RestartStrip();
            }

            // ============================================================
            // Fragment Shader
            // ============================================================

            float4 Frag (g2f i) : SV_Target
            {
                return _WireColor;
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
