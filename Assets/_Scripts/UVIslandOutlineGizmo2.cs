using UnityEngine;
using System.Collections.Generic;

public class UVIslandOutlineGizmo2 : MonoBehaviour
{
    public float gizmoScale = 1f;           // Scale of UV layout in world space
    public Vector3 offset = Vector3.zero;   // Offset in world space
    public Color outlineColor = Color.yellow;

    void OnDrawGizmos()
    {
        Mesh mesh = null;

        // Try MeshFilter first
        MeshFilter mf = GetComponent<MeshFilter>();
        if (mf != null) mesh = mf.sharedMesh;

        // If no MeshFilter or no mesh, try SkinnedMeshRenderer
        if (mesh == null)
        {
            SkinnedMeshRenderer smr = GetComponent<SkinnedMeshRenderer>();
            if (smr != null)
            {
                mesh = new Mesh();
                smr.BakeMesh(mesh); // get current pose
            }
        }

        if (mesh == null || mesh.uv == null || mesh.uv.Length == 0)
        {
            Debug.LogWarning("Mesh or UVs not found on " + name);
            return;
        }

        Vector2[] uvs = mesh.uv;
        List<EdgeInfo> edges = new List<EdgeInfo>();

        // Loop through all submeshes
        for (int s = 0; s < mesh.subMeshCount; s++)
        {
            int[] triangles = mesh.GetTriangles(s);
            for (int i = 0; i < triangles.Length; i += 3)
            {
                AddEdge(edges, triangles[i], triangles[i + 1], i);
                AddEdge(edges, triangles[i + 1], triangles[i + 2], i);
                AddEdge(edges, triangles[i + 2], triangles[i], i);
            }
        }

        // Draw UV island outlines
        Gizmos.color = outlineColor;
        foreach (var edge in edges)
        {
            if (edge.triangleCount == 1 || edge.uvSeam)
            {
                Vector2 uv0 = uvs[edge.v0];
                Vector2 uv1 = uvs[edge.v1];
                Gizmos.DrawLine(UVToWorld(uv0), UVToWorld(uv1));
            }
        }
    }

    void AddEdge(List<EdgeInfo> edges, int v0, int v1, int triangleIndex)
    {
        // Order vertices consistently
        int a = Mathf.Min(v0, v1);
        int b = Mathf.Max(v0, v1);

        // Find existing edge
        EdgeInfo existing = edges.Find(e => e.v0 == a && e.v1 == b);

        if (existing != null)
        {
            existing.triangleCount++;
            if (existing.triangleIndices == null) existing.triangleIndices = new List<int>();
            existing.triangleIndices.Add(triangleIndex);
            existing.uvSeam = true; // Optional: refine seam detection later
        }
        else
        {
            EdgeInfo e = new EdgeInfo
            {
                v0 = a,
                v1 = b,
                triangleCount = 1,
                triangleIndices = new List<int> { triangleIndex },
                uvSeam = false
            };
            edges.Add(e);
        }
    }

    Vector3 UVToWorld(Vector2 uv)
    {
        return transform.position + offset + new Vector3(uv.x, uv.y, 0) * gizmoScale;
    }

    // Edge info class
    class EdgeInfo
    {
        public int v0;
        public int v1;
        public int triangleCount;
        public List<int> triangleIndices;
        public bool uvSeam;
    }
}
