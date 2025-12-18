using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class UVGizmoDebugger : MonoBehaviour
{
    public float gizmoScale = 1.0f;
    public Vector3 offset = Vector3.zero;
    public Color lineColor = Color.white;
    private Mesh bakedMesh;
    void OnDrawGizmos()
    {
        SkinnedMeshRenderer smr = GetComponent<SkinnedMeshRenderer>();
        if (smr == null)
            return;

        if (bakedMesh == null)
            bakedMesh = new Mesh();

        smr.BakeMesh(bakedMesh);

        if (bakedMesh.uv == null || bakedMesh.uv.Length == 0)
            return;

        Vector2[] uvs = bakedMesh.uv;
        int[] tris = bakedMesh.triangles;

        Gizmos.color = lineColor;

        for (int i = 0; i < tris.Length; i += 3)
        {
            Vector3 a = UVToWorld(uvs[tris[i]]);
            Vector3 b = UVToWorld(uvs[tris[i + 1]]);
            Vector3 c = UVToWorld(uvs[tris[i + 2]]);

            Gizmos.DrawLine(a, b);
            Gizmos.DrawLine(b, c);
            Gizmos.DrawLine(c, a);
        }
    }


    Vector3 UVToWorld(Vector2 uv)
    {
        return transform.position
               + offset
               + new Vector3(uv.x, uv.y, 0f) * gizmoScale;
    }
}
