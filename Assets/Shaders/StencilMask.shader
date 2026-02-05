Shader "Custom/StencilMask"
{
    Properties
    {
        [IntRange] _StencilID ("Stencil ID", Range(0, 255)) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-1" "RenderPipeline" = "UniversalPipeline"}

        Pass 
        {
            Blend Zero One
           

            Stencil
            {
                Ref [_StencilID]
                Comp Always
                Pass Replace
                Fail Keep
            }
            
            ColorMask 0
            ZWrite Off
        }
    }
}