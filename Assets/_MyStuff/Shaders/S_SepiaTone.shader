Shader "Custom/S_SepiaTone"
{
	Properties
	{
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			ZWrite off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

			struct attributes
			{
				float4 positionOS : POSITION;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float4 positionSS : TEXCOORD0;
			};

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionSS = ComputeScreenPos(o.positionCS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				const float3x3 sepia = float3x3
				(
					0.393f, 0.349f, 0.272f,   // Red.
					0.769f, 0.686f, 0.534f,   // Green.
					0.189f, 0.168f, 0.131f    // Blue.
				);

				float2 screenUVs = i.positionSS.xy / i.positionSS.w;
				float3 sceneColor = SampleSceneColor(screenUVs);

				float3 outputColor = mul(sceneColor, sepia);
				return float4(outputColor, 1.0f);
			}

			ENDHLSL
		}
	}
}