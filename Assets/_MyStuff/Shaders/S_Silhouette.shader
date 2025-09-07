Shader "Custom/S_Silhouette"
{
	Properties
	{
		_ForegroundColor("Foreground Color", Color) = (1,1,1,1)
		_BackgroundColor("Background Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Geometry"
			"Queue" = "Geometry+1"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			ZWrite on
			Blend One Zero

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
				float4 _ForegroundColor;
				float4 _BackgroundColor;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionSS = ComputeScreenPos(o.positionCS);
				return o;
			}

			float4 frag (varryings i) : SV_TARGET
			{
				float2 screenUVs = i.positionSS.xy / i.positionSS.w;
				float rawDepth = SampleSceneDepth(screenUVs);
				float linear01 = Linear01Depth(rawDepth, _ZBufferParams);

				float4 finalColor = lerp(_ForegroundColor, _BackgroundColor, linear01);

				return finalColor;
			}

			ENDHLSL
		}
	}
}