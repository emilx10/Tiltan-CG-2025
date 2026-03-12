Shader "Custom/TriangleExplosionGPU"
{
    Properties
    {
        _Color ("Color", Color) = (1,0.5,0,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct TriangleData
            {
                 float3 offset;
                 float3 velocity;
                 float lifetime;
            };

            StructuredBuffer<TriangleData> triangleBuffer;

            float4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2g
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
            };

            // Vertex shader
            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.vertex;
                o.normal = v.normal;
                return o;
            }

            // Geometry shader
            [maxvertexcount(3)]
            void geom(triangle v2g input[3],
                      uint primID : SV_PrimitiveID,
                      inout TriangleStream<g2f> triStream)
            {
                TriangleData tri = triangleBuffer[primID];

                // if triangle lifetime finished skip rendering
                if(tri.lifetime <= 0)
                    return;

                float3 offset = tri.offset;

                for(int i=0;i<3;i++)
                {
                    g2f o;

                    float4 pos = input[i].pos;
                    pos.xyz += offset;

                    o.pos = UnityObjectToClipPos(pos);

                    triStream.Append(o);
                }
            }

            // Fragment shader
            fixed4 frag(g2f i) : SV_Target
            {
                return _Color;
            }

            ENDCG
        }
    }
}