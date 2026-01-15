Shader "Unlit/Diffuse_Light"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        
        // base pass is dealing with directional lights - need to create more passes for other light calclations
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // important to use world space - as the lights are in world space
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float3 N = i.normal;
                float3 L = _WorldSpaceLightPos0.xyz; // the 4 value of _WorldSpaceLightPos0 tells if its direction (0) or position light (1)
                float diffuseLight = saturate(dot(N,L));
                return float4(diffuseLight.xxx,1);
              
            }
            ENDCG
        }
    }
}
