using UnityEngine;

[ExecuteAlways]
public class RainController : MonoBehaviour
{
    [Range(0f, 1f)]
    public float rainIntensity = 0.5f;

    void Update()
    {
        Shader.SetGlobalFloat("_GlobalRainIntensity", rainIntensity);
    }
}