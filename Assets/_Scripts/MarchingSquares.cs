using UnityEngine;

public class MarchingSquares : MonoBehaviour
{
    public int width = 20;
    public int height = 20;
    public float threshold = 0.5f;

    float[,] values;

    void Start()
    {
        GenerateField();
    }

    void GenerateField()
    {
        values = new float[width, height];

        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                // Generate simple noise field
                values[x, y] = Mathf.PerlinNoise(x * 0.1f, y * 0.1f);
            }
        }
    }

    void OnDrawGizmos()
    {
        if (values == null) return;

        // Draw grid points
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                Gizmos.color = values[x, y] > threshold ? Color.white : Color.black;
                Gizmos.DrawSphere(new Vector3(x, y, 0), 0.1f);
            }
        }
    }
}