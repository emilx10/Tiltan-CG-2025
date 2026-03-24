using UnityEngine;

public class RainController : MonoBehaviour
{
    [Range(0, 1)]
    public float RainIntensity = 1f;

    void Update()
    {
        Shader.SetGlobalFloat("_RainIntensity", RainIntensity);
    }
}