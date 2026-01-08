using UnityEngine;

public class UVGizmoDebugger : MonoBehaviour
{
    public float gizmoScale = 1.0f;
    public Vector3 offset = Vector3.zero;
    public Color lineColor = Color.white;

    void OnDrawGizmos()
    {
        
        Mesh mesh = GetComponent<SkinnedMeshRenderer>().sharedMesh;
        
        if (mesh == null)
        {
            Debug.LogWarning("Mesh has no uvs assigned");
        }
        
        Vector2[] uvs = mesh.uv;
        int[] triangles = mesh.triangles;
        
        Gizmos.color = lineColor;
        for (int i = 0; i < triangles.Length; i += 3)
        {
            Vector3 a = UVToWorld(uvs[triangles[i]]);
            Vector3 b = UVToWorld(uvs[triangles[i + 1]]);
            Vector3 c = UVToWorld(uvs[triangles[i + 2]]);

            Gizmos.DrawLine(a, b);
            Gizmos.DrawLine(b, c);
            Gizmos.DrawLine(c, a);
        
        }
        
        
    }

    Vector3 UVToWorld(Vector2 uv)
    {
        // Map UV (0–1) into world space square
        return transform.position
               + offset
               + new Vector3(uv.x, uv.y, 0) * gizmoScale;
    }
}