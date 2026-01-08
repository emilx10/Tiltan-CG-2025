using UnityEngine;

/// <summary>
/// Controls material parameters on both MeshRenderer and SkinnedMeshRenderer.
/// This script automatically detects which renderer exists on the GameObject.
/// </summary>
public class MaterialParameterController : MonoBehaviour
{
    // Cached renderer references
    private MeshRenderer meshRenderer;
    private SkinnedMeshRenderer skinnedMeshRenderer;

    // The material instance we will manipulate
    private Material runtimeMaterial;

    void Awake()
    {
        // Try to get MeshRenderer
        meshRenderer = GetComponent<MeshRenderer>();

        // Try to get SkinnedMeshRenderer
        skinnedMeshRenderer = GetComponent<SkinnedMeshRenderer>();

        // Safety check
        if (meshRenderer == null && skinnedMeshRenderer == null)
        {
            Debug.LogError("No MeshRenderer or SkinnedMeshRenderer found on this GameObject.");
            return;
        }

        // IMPORTANT:
        // .material creates a unique material instance at runtime
        // This prevents changing the material for all objects using it
        if (meshRenderer != null)
            runtimeMaterial = meshRenderer.material;
        else
            runtimeMaterial = skinnedMeshRenderer.material;
    }

    /* ---------------------------------------------------------
     * MATERIAL PARAMETER SETTERS
     * --------------------------------------------------------- */

    /// <summary>
    /// Set a float parameter (e.g. "_Smoothness", "_Metallic")
    /// </summary>
    public void SetFloat(string parameterName, float value)
    {
        if (runtimeMaterial == null) return;

        runtimeMaterial.SetFloat(parameterName, value);
    }

    /// <summary>
    /// Set a color parameter (e.g. "_BaseColor", "_Color")
    /// </summary>
    public void SetColor(string parameterName, Color value)
    {
        if (runtimeMaterial == null) return;

        runtimeMaterial.SetColor(parameterName, value);
    }

    /// <summary>
    /// Set a vector parameter
    /// </summary>
    public void SetVector(string parameterName, Vector4 value)
    {
        if (runtimeMaterial == null) return;

        runtimeMaterial.SetVector(parameterName, value);
    }

    /// <summary>
    /// Set a texture parameter (e.g. "_BaseMap", "_MainTex")
    /// </summary>
    public void SetTexture(string parameterName, Texture value)
    {
        if (runtimeMaterial == null) return;

        runtimeMaterial.SetTexture(parameterName, value);
    }

    /* ---------------------------------------------------------
     * OPTIONAL: GETTERS
     * --------------------------------------------------------- */

    public float GetFloat(string parameterName)
    {
        if (runtimeMaterial == null) return 0f;

        return runtimeMaterial.GetFloat(parameterName);
    }

    public Color GetColor(string parameterName)
    {
        if (runtimeMaterial == null) return Color.white;

        return runtimeMaterial.GetColor(parameterName);
    }
}
