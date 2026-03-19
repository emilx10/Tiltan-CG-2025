using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RayTracingRenderPass : ScriptableRenderPass
{
    private RayTracingSphereManagerSimple rayTracingManager;
    private string profilerTag;

    public RayTracingRenderPass(string profilerTag)
    {
        this.profilerTag = profilerTag;
        renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public void Setup(RayTracingSphereManagerSimple manager)
    {
        this.rayTracingManager = manager;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (rayTracingManager == null) return;

        // Get the render targets here, inside the render pass scope
        var renderer = renderingData.cameraData.renderer;
        var source = renderer.cameraColorTargetHandle;
        var destination = renderer.cameraColorTargetHandle;

        CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

        // Get the camera render texture dimensions
        var cameraData = renderingData.cameraData;
        int width = cameraData.camera.scaledPixelWidth;
        int height = cameraData.camera.scaledPixelHeight;

        // Execute the ray tracing logic
        rayTracingManager.ExecuteRayTracing(cmd, source, destination, width, height);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}