using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using static UnityEngine.Mathf;


public class RayTracingSphereManagerSimple : MonoBehaviour
{
    [Header("References")]
    [SerializeField] Shader rayTracingShader;
    [SerializeField] Shader accumulateShader;

    [Header("Info")]
    [SerializeField] int numRenderedFrames;
    [SerializeField] int numSpheres;

    // Materials and render textures
    Material rayTracingMaterial;
    Material accumulateMaterial;
    RenderTexture resultTexture;

    // Buffers
    ComputeBuffer sphereBuffer;
	
    // Track if data needs updating
    private int lastSphereCount = -1;
    private bool needsDataUpdate = true;

    void Start()
    {
        numRenderedFrames = 0;
        needsDataUpdate = true;
    }

    void LateUpdate()
    {
        // Update camera parameters every frame
        if (Camera.current != null)
        {
            UpdateCameraParams(Camera.current);
        }
		
        // Check if spheres in scene have changed
        RayTracedSphereSimple[] sphereObjects = FindObjectsByType<RayTracedSphereSimple>(FindObjectsSortMode.None);
        if (sphereObjects.Length != lastSphereCount)
        {
            needsDataUpdate = true;
            lastSphereCount = sphereObjects.Length;
        }
    }
 
    
    // New method that will work with reander feature and URP
    public void ExecuteRayTracing(CommandBuffer cmd, RTHandle source, RTHandle destination, int width, int height)
    {
        InitFrame(width, height);

        // Create temporary render textures
        int prevFrameID = Shader.PropertyToID("_PrevFrameCopy");
        int currentFrameID = Shader.PropertyToID("_CurrentFrame");

        cmd.GetTemporaryRT(prevFrameID, width, height, 0, FilterMode.Bilinear, ShaderHelper.RGBA_SFloat);
        cmd.GetTemporaryRT(currentFrameID, width, height, 0, FilterMode.Bilinear, ShaderHelper.RGBA_SFloat);

        // Create copy of prev frame
        cmd.Blit(resultTexture, prevFrameID);

        // Run the ray tracing shader
        rayTracingMaterial.SetInt("Frame", numRenderedFrames);
        cmd.Blit(BuiltinRenderTextureType.None, currentFrameID, rayTracingMaterial);

        // Accumulate
        cmd.SetGlobalTexture("_PrevFrame", prevFrameID);
        accumulateMaterial.SetInt("_Frame", numRenderedFrames);
        cmd.Blit(currentFrameID, resultTexture, accumulateMaterial);

        // Draw result to screen
        cmd.Blit(resultTexture, destination);

        // Release temporary render textures
        cmd.ReleaseTemporaryRT(prevFrameID);
        cmd.ReleaseTemporaryRT(currentFrameID);

        numRenderedFrames += Application.isPlaying ? 1 : 0;
    }

    void InitFrame(int width, int height)
    {
        // Create materials used in blits
        ShaderHelper.InitMaterial(rayTracingShader, ref rayTracingMaterial);
        ShaderHelper.InitMaterial(accumulateShader, ref accumulateMaterial);
        // Create result render texture
        ShaderHelper.CreateRenderTexture(ref resultTexture, width, height, FilterMode.Bilinear, ShaderHelper.RGBA_SFloat, "Result");

        // Update data only if needed
        if (needsDataUpdate)
        {
            CreateSpheres();
            needsDataUpdate = false;
        }
    }

    void UpdateCameraParams(Camera cam)
    {
        if (cam == null) return;
		
        float planeHeight = Tan(cam.fieldOfView * 0.5f * Deg2Rad) * 2;
        float planeWidth = planeHeight * cam.aspect;
		
        // Send data to shader
        if (rayTracingMaterial != null)
        {
            rayTracingMaterial.SetVector("ViewParams", new Vector2(planeWidth, planeWidth));
            rayTracingMaterial.SetMatrix("CamLocalToWorldMatrix", cam.transform.localToWorldMatrix);
        }
    }

    void CreateSpheres()
    {
        // Create sphere data from the sphere objects in the scene
        RayTracedSphereSimple[] sphereObjects = FindObjectsByType<RayTracedSphereSimple>(FindObjectsSortMode.None);
		
        SphereSimple[] spheres;
		
        if (sphereObjects.Length == 0)
        {
            // If no spheres, create a dummy sphere to avoid empty buffer
            spheres = new SphereSimple[1];
            spheres[0] = new SphereSimple()
            {
                position = Vector3.zero,
                radius = 0f,
                material = GetDefaultMaterial()
            };
        }
        else
        {
            spheres = new SphereSimple[sphereObjects.Length];
            for (int i = 0; i < sphereObjects.Length; i++)
            {
                RayTracingMaterialSimple mat = sphereObjects[i].material;
                // If material is null, use default material
				
                spheres[i] = new SphereSimple()
                {
                    position = sphereObjects[i].transform.position,
                    radius = sphereObjects[i].transform.localScale.x * 0.5f,
                    material = mat
                };
            }
        }

        // Create buffer containing all sphere data, and send it to the shader
        ShaderHelper.CreateStructuredBuffer(ref sphereBuffer, spheres);
        if (rayTracingMaterial != null)
        {
            rayTracingMaterial.SetBuffer("Spheres", sphereBuffer);
            rayTracingMaterial.SetInt("NumSpheres", sphereObjects.Length);
        }

        numSpheres = sphereObjects.Length;
    }
    
    RayTracingMaterialSimple GetDefaultMaterial()
    {
        return new RayTracingMaterialSimple()
        {
            colour = Color.white
        };
    }

    void OnDisable()
    {
        ShaderHelper.Release(sphereBuffer);
        ShaderHelper.Release(resultTexture);
    }
}
