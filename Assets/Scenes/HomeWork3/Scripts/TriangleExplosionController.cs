using UnityEngine;

public class TriangleExplosionController : MonoBehaviour
{
    public ComputeShader computeShader;
    public MeshFilter meshFilter;
    public Material material;

    public struct TriangleData
    {
        public Vector3 offset;
        public Vector3 velocity;
        public float lifetime;
    }

    ComputeBuffer buffer;

    int triangleCount;
    int kernel;

    void Start()
    {
        Mesh mesh = meshFilter.mesh;

        triangleCount = mesh.triangles.Length / 3;

        buffer = new ComputeBuffer(triangleCount, sizeof(float) * 7);

        TriangleData[] data = new TriangleData[triangleCount];

        for (int i = 0; i < triangleCount; i++)
        {
            data[i].offset = Vector3.zero;

            data[i].velocity = UnityEngine.Random.onUnitSphere * 2f;

            data[i].lifetime = UnityEngine.Random.Range(2f, 5f);
        }

        buffer.SetData(data);

        kernel = computeShader.FindKernel("CSMain");

        computeShader.SetBuffer(kernel, "triangleBuffer", buffer);

        material.SetBuffer("triangleBuffer", buffer);
    }

    void Update()
    {
        computeShader.SetFloat("deltaTime", Time.deltaTime);

        computeShader.Dispatch(kernel, triangleCount / 64 + 1, 1, 1);
    }

    void OnDestroy()
    {
        if (buffer != null)
            buffer.Release();
    }
}