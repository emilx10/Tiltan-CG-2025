// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE 2 — "Find the Surface"
// Starting point: Direct Volume Rendering with a 3D texture
//
// Your task: convert this DVR shader into a shaded Isosurface renderer
//
//   Part A  (7 min) — First-Hit Isosurface
//   Part B  (8 min) — Gradient Normal
//   Part C  (5 min) — Diffuse Lighting
//
// Full instructions are in the checklist at the bottom of this file.
// ═══════════════════════════════════════════════════════════════════════════

Shader "VolumeRendering/VolumeRendering_IsoStarter"
{
    Properties
    {
        [Header(Rendering)]
        _Volume    ("Volume",    3D)             = "" {}
        _Color     ("Color",     Color)          = (1, 1, 1, 1)
        _Iteration ("Iteration", Int)            = 64
        _Intensity ("Intensity", Range(0.0,1.0)) = 0.1

        // ─── TODO Part A: add your threshold property here ───────────────
        // _IsoThreshold ("Iso Threshold", Range(0,1)) = 0.5
        // ─────────────────────────────────────────────────────────────────

        [Header(Ranges)]
        _MinX ("MinX", Range(0,1)) = 0.0
        _MaxX ("MaxX", Range(0,1)) = 1.0
        _MinY ("MinY", Range(0,1)) = 0.0
        _MaxY ("MaxY", Range(0,1)) = 1.0
        _MinZ ("MinZ", Range(0,1)) = 0.0
        _MaxZ ("MaxZ", Range(0,1)) = 1.0
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
    };

    struct v2f
    {
        float4 vertex   : SV_POSITION;
        float4 localPos : TEXCOORD0;
        float4 worldPos : TEXCOORD1;
    };

    // ── Declared uniforms ─────────────────────────────────────────────────
    sampler3D _Volume;
    fixed4    _Color;
    int       _Iteration;
    fixed     _Intensity;
    fixed     _MinX, _MaxX, _MinY, _MaxY, _MinZ, _MaxZ;

    // ─── TODO Part A: declare your threshold uniform and use it in frag shader..
    // fixed _IsoThreshold;
    
    
    fixed sample(float3 pos)
    {
        fixed x = step(pos.x, _MaxX) * step(_MinX, pos.x);
        fixed y = step(pos.y, _MaxY) * step(_MinY, pos.y);
        fixed z = step(pos.z, _MaxZ) * step(_MinZ, pos.z);
        return tex3D(_Volume, pos).a * x * y * z;
    }

    
    

    // ── Vertex shader ─────────────────────────────────────────────────────
    v2f vert(appdata v)
    {
        v2f o;
        o.vertex   = UnityObjectToClipPos(v.vertex);
        o.localPos = v.vertex;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        return o;
    }

    // ── Fragment shader ───────────────────────────────────────────────────
    fixed4 frag(v2f i) : SV_Target
    {
        // Build the ray in object (local) space
        float3 wdir  = i.worldPos - _WorldSpaceCameraPos;
        float3 ldir  = normalize(mul(unity_WorldToObject, wdir));
        float3 lstep = ldir / _Iteration;
        float3 lpos  = i.localPos;

        // ── CURRENT BEHAVIOUR: Direct Volume Rendering (DVR) ─────────────
        // Accumulates density along the entire ray.
        // This makes the whole volume translucent — no hard surface.
        fixed output = 0.0;

        [loop]
        for (int step = 0; step < _Iteration; ++step)
        {
            fixed a     = sample(lpos + 0.5);
            
            output += (1 - output) * a * _Intensity;   

            lpos += lstep;

            // Exit when we leave the bounding box or reach full opacity
            if (!all(max(0.5 - abs(lpos), 0.0)) || output > 0.99) break;
        }

        // ─── TODO Part B: inside the isosurface branch, compute a normal ─
        //   float3 normal = getGradient(lpos + 0.5); create such function
        //   Debug: return float4(normal * 0.5 + 0.5, 1.0);
        // ─────────────────────────────────────────────────────────────────

        // ─── TODO Part C: replace the return with diffuse-shaded colour ──
        

        return _Color * output;
    }

    ENDCG

    SubShader
    {
        Tags
        {
            "Queue"      = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Cull     Back
            ZWrite   Off
            ZTest    LEqual
            Blend    SrcAlpha OneMinusSrcAlpha
            Lighting Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
