using UnityEngine;
using UnityEngine.Rendering.Universal;

public class RayTracingRendererFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        [Tooltip("Leave empty to auto-find RayTracingSphereManagerSimple in the scene")]
        public RayTracingSphereManagerSimple rayTracingManager;
    }

    public Settings settings = new Settings();
    private RayTracingRenderPass rayTracingPass;

    public override void Create()
    {
        rayTracingPass = new RayTracingRenderPass("RayTracingPass");
        rayTracingPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // Auto-find manager if not assigned
        if (settings.rayTracingManager == null)
        {
            settings.rayTracingManager = Object.FindFirstObjectByType<RayTracingSphereManagerSimple>();
        }

        if (settings.rayTracingManager == null) return;

        rayTracingPass.Setup(settings.rayTracingManager);
        renderer.EnqueuePass(rayTracingPass);
    }
}