using UnityEngine;

public class UVGizmoDebugger : MonoBehaviour
{
    public float gizmoScale = 1.0f;
    public Vector3 offset = Vector3.zero;
    public Color lineColor = Color.white;

    void OnDrawGizmos()
    {
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        if (mesh == null)
            mesh = GetComponent<SkinnedMeshRenderer>().sharedMesh;
        
        if (mesh == null)
        {
            Debug.LogWarning("Mesh has no uvs assigned");
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