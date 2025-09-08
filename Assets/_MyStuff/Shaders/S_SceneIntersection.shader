Shader "Cutsom/S_SceneIntersection"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (0,0,0,1)
		_IntersectionColor("Intersection Color", Color) = (1,1,1,1)
		_Strength("Strength", Float) = 1
	}

	Subshader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
		}

		Pass
		{
			Name "ForwardColor"
			Tags
			{
				"LightModel" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			struct attributes
			{
				float4 positionOS : POSITION;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float4 positionSS : TEXCOORD0;
			};

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _IntersectionColor;
				float _Strength;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionSS = ComputeScreenPos(o.positionCS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				return _BaseColor;
			}

			ENDHLSL
		}
	}
}