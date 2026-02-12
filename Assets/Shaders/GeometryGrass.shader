Shader "Custom/GeometryGrass"
{
     Properties
    {
        _GrassColor ("Grass Color", Color) = (0.2, 0.8, 0.2, 1)
        _BladeHeight ("Blade Height", Float) = 0.2
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

            // ============================================================
            // Structs
            // ============================================================

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

            // ============================================================
            // Properties
            // ============================================================

            float4 _GrassColor;
            float _BladeHeight;

            // ============================================================
            // Vertex Shader
            // ============================================================

            v2g Vert (appdata v)
            {
                v2g o;

                // World position (needed for grass placement)
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // Clip position (required for rendering)
                o.clipPos = UnityObjectToClipPos(v.vertex);

                // World normal
                o.normal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            // ============================================================
            // Geometry Shader – Grass Generation
            // ============================================================

            // Each blade = 3 triangles = 9 vertices
            [maxvertexcount(9)]
        void Geo(
        triangle v2g input[3],
        inout TriangleStream<g2f> triStream
)
        {
            // --------------------------------------------------------
            // Step 1: Calculate center and up vector
            // --------------------------------------------------------

            float3 centerWorld =
                (input[0].worldPos +
                 input[1].worldPos +
                 input[2].worldPos) / 3.0;

            float3 up = normalize(
                input[0].normal +
                input[1].normal +
                input[2].normal
            );

            float3 tip = centerWorld + up * _BladeHeight;

            g2f o;

            // --------------------------------------------------------
            // Triangle 1: Edge 0-1
            // --------------------------------------------------------

            o.clipPos = UnityWorldToClipPos(input[0].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(input[1].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(tip);
            triStream.Append(o);

            triStream.RestartStrip();

            // --------------------------------------------------------
            // Triangle 2: Edge 1-2
            // --------------------------------------------------------

            o.clipPos = UnityWorldToClipPos(input[1].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(input[2].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(tip);
            triStream.Append(o);

            triStream.RestartStrip();

            // --------------------------------------------------------
            // Triangle 3: Edge 2-0
            // --------------------------------------------------------

            o.clipPos = UnityWorldToClipPos(input[2].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(input[0].worldPos);
            triStream.Append(o);

            o.clipPos = UnityWorldToClipPos(tip);
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