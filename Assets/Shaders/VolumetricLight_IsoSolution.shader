// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE 2 — SOLUTION
// Isosurface Rendering with Gradient Normal and Diffuse Lighting
// ═══════════════════════════════════════════════════════════════════════════

Shader "VolumeRendering/VolumeRendering_IsoSolution"
{
    Properties
    {
        [Header(Rendering)]
        _Volume       ("Volume",        3D)             = "" {}
        _Color        ("Color",         Color)          = (1, 1, 1, 1)
        _Iteration    ("Iteration",     Int)            = 64

        // Part A: threshold — controls which density contour is rendered
        _IsoThreshold ("Iso Threshold", Range(0,1))     = 0.5

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

    sampler3D _Volume;
    fixed4    _Color;
    int       _Iteration;
    fixed     _IsoThreshold;
    fixed     _MinX, _MaxX, _MinY, _MaxY, _MinZ, _MaxZ;

    // ── sample() ─────────────────────────────────────────────────────────
    // Reads the volume texture at pos (UV space 0–1) with range masking.
    // Samples outside the _MinX/_MaxX (etc.) sliders return 0.
    // This lets the instructor slice the dataset live without changing data.
    fixed sample(float3 pos)
    {
        fixed x = step(pos.x, _MaxX) * step(_MinX, pos.x);
        fixed y = step(pos.y, _MaxY) * step(_MinY, pos.y);
        fixed z = step(pos.z, _MaxZ) * step(_MinZ, pos.z);
        return tex3D(_Volume, pos).a * x * y * z;
    }

    // ── getGradient() — Part B ────────────────────────────────────────────
    // Central-difference approximation of the density gradient at pos.
    // Each axis: sample one step forward, one step back, take the difference.
    // The resulting float3 points in the direction of steepest density rise
    // — i.e., perpendicular to the isosurface, pointing outward.
    //
    // Why d = 0.01?
    //   Too small → numerical noise in the texture lookup dominates.
    //   Too large → gradient smears across features; normals look blocky.
    //   0.01 ≈ 1% of the texture dimension. Works well for most volumes.
    float3 getGradient(float3 pos)
    {
        float d  = 0.01;
        float dx = sample(pos + float3(d,0,0)) - sample(pos - float3(d,0,0));
        float dy = sample(pos + float3(0,d,0)) - sample(pos - float3(0,d,0));
        float dz = sample(pos + float3(0,0,d)) - sample(pos - float3(0,0,d));
        return normalize(float3(dx, dy, dz));
    }

    v2f vert(appdata v)
    {
        v2f o;
        o.vertex   = UnityObjectToClipPos(v.vertex);
        o.localPos = v.vertex;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        return o;
    }

    fixed4 frag(v2f i) : SV_Target
    {
        // Build the march ray in object (local) space.
        // We work in local space because the volume texture is defined
        // in local space — no need to transform it at every step.
        float3 wdir  = i.worldPos - _WorldSpaceCameraPos;
        float3 ldir  = normalize(mul(unity_WorldToObject, wdir));
        float3 lstep = ldir / _Iteration;
        float3 lpos  = i.localPos;

        [loop]
        for (int step = 0; step < _Iteration; ++step)
        {
            // ── Part A: First-hit isosurface test ─────────────────────────
            // We no longer accumulate opacity — we stop at the FIRST voxel
            // above the threshold. This gives us a hard surface.
            //
            // lpos is in [-0.5, 0.5] local space; adding 0.5 maps it to
            // the [0, 1] UV space that tex3D() expects.
            float density = sample(lpos + 0.5);

            if (density > _IsoThreshold)
            {
                // ── Part B: Gradient normal ───────────────────────────────
                // Central differences on the density field.
                // Note: we also pass lpos + 0.5 because sample() needs
                // UV-space coordinates.
                float3 normal = getGradient(lpos + 0.5);

                // ── Part C: Diffuse lighting ──────────────────────────────
                // _WorldSpaceLightPos0 is Unity's built-in directional
                // light direction (world space, pointing toward the light).
                // We transform it to object space to match our normal,
                // which was computed in object-space UV coordinates.
                //
                // Why -lightDir?
                //   _WorldSpaceLightPos0 points *toward* the light source.
                //   dot(normal, lightDir) would give 1 when the surface
                //   faces away from the light. We negate to get the
                //   conventional "light comes from this direction" dot product.
                //
                // Why 0.3 as the ambient floor?
                //   Clamping to 0 would leave the dark side pitch-black.
                //   0.3 is a simple ambient term — the minimum brightness
                //   regardless of light angle. Detail stays visible.
                float3 lightDir = normalize(
                    mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);
                float diffuse = max(dot(normal, -lightDir), 0.3);

                return _Color * diffuse;
            }

            lpos += lstep;

            // Exit when the ray leaves the bounding box
            if (!all(max(0.5 - abs(lpos), 0.0))) break;
        }

        // Ray exited the volume without hitting the isosurface — transparent
        return fixed4(0, 0, 0, 0);
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

// ═══════════════════════════════════════════════════════════════════════════
// SOLUTION NOTES — what changed from the starter and why
// ═══════════════════════════════════════════════════════════════════════════
//
//  Part A — First-Hit vs. Accumulation
//  ─────────────────────────────────────────────────────────────────────────
//  The starter's DVR loop:
//      output += (1 - output) * a * _Intensity;
//  is a compositing formula — it blends every sample along the ray into
//  a single transparency value. The whole volume becomes semi-transparent.
//
//  The isosurface replacement is a simple conditional break:
//      if (density > _IsoThreshold) { return _Color; }
//  The loop now stops the moment it finds a surface. Everything before
//  that first hit is discarded. This is conceptually closer to ray casting
//  than to full ray marching — but it runs in the same loop structure.
//
//  Adjusting _IsoThreshold changes *which* density contour is shown:
//      low value  → render outer soft tissue (low density)
//      high value → render only bone (high density)
//  This is the simplest interactive tool for exploring a CT dataset.
//
//  Part B — Gradient as Surface Normal
//  ─────────────────────────────────────────────────────────────────────────
//  Triangles carry explicit normals baked into the mesh.
//  Volumes have no geometry — the normal must be derived from the data.
//
//  The gradient is the direction of steepest density increase.
//  At any surface boundary, density changes steeply → the gradient
//  is large and perpendicular to the surface → it IS the normal.
//
//  Central differences (forward minus backward on each axis) give a
//  numerically stable first-order approximation of the gradient.
//  Normalizing it gives a unit normal exactly as PBR lighting expects.
//
//  The debug visualisation float4(normal * 0.5 + 0.5, 1.0) remaps
//  normals from [-1,1] to [0,1] for display as RGB. This is the
//  standard technique used to author and debug normal maps.
//
//  Part C — Diffuse Lighting (Lambertian)
//  ─────────────────────────────────────────────────────────────────────────
//  Id = Kd · cos(θ) = Kd · dot(n, l)
//
//  This is the same formula used on every lit triangle in every game.
//  The only difference here is that n came from getGradient() rather
//  than a mesh attribute.
//
//  The _WorldSpaceLightPos0 → unity_WorldToObject transform is important:
//  the gradient normal is in object space (because sample() uses object-
//  space UV coordinates). The light direction must be in the same space.
//
//  Clamping to 0.3 instead of 0 provides a simple ambient term.
//  Production shaders would use a proper ambient probe or SH lighting;
//  for this exercise 0.3 is sufficient to keep the dark side readable.
//
// ═══════════════════════════════════════════════════════════════════════════
