Shader "Custom/S_StencilMask"
{
	Properties
	{
		[IntRange] _StencilRef("Stencil Ref", Range(0, 255)) = 1
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Geometry"
			"Queue" = "Geometry-1"
		}

		Pass
		{
			Stencil
			{
				Ref[_StencilRef]
				Comp Always
				Pass Replace
			}

			ZWrite off
		}
	}
}