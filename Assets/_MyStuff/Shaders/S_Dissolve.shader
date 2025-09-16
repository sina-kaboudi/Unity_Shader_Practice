Shader "Custom/S_Dissolve"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 2D) = "white" {}
		_Threshold("Cutoff Threshold", Range(-1, 1)) = -1
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
			Cull off

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
				float4 positionOS : TEXCOORD1;
			};

			TEXTURE2D(_BaseTexture);
			SAMPLER(sampler_BaseTexture);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float _Threshold;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionOS = i.positionOS;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float4 sampleColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				if (i.positionOS.y > _Threshold) discard;
				return i.positionOS;
			}

			ENDHLSL
		}
	}
}