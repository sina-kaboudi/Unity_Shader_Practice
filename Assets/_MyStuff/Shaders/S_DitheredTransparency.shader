Shader "Custom/S_DitheredTransparency"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "AlphaTest"
		}

		Pass
		{
			Name "ForwardUnlit"
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			ZWrite on
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 positionSS : TEXCOORD1;
			};

			TEXTURE2D(_BaseTexture);
			SAMPLER(sampler_BaseTexture);

            CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
            CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
				o.positionSS = ComputeScreenPos(o.positionCS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float4 samplerColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				float4 finalColor = samplerColor * _BaseColor;

				float2 screenUVs = i.positionSS.xy / i.positionSS.w * _ScreenParams.xy;
				float ditherThresholds[16] =
				{
					  16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0,
					  4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
					  13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
					  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0
				};

				uint index = (uint(screenUVs.x)%4)*4 + uint(screenUVs.y)%4;
				float threshold = ditherThresholds[index];

				if (finalColor.a < threshold) discard;
				return finalColor;
			}
			ENDHLSL
		}
	}
}