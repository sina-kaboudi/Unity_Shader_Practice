Shader "Custom/S_PBR"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 2D) = "white" {}
		_MetallicTex("Metallic Texture", 2D) = "whtie" {}
		_MetallicStrength("Metallic Strength", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_NormalTex("Normal Map", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		[Toggle(USE_EMISSION_ON)] _EmissionOn("Use Emission?", Float) = 0
		_EmissionTex("Emission Texture", 2D) = "white" {}
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0,0)
		_AOTex("Ambient Occlusion Map", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Pass
		{
			Name "PBR"
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct attributes
			{
				float4 positoinOS : POSITION;
				float3 normalOS : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			TEXTURE2D(_BaseTexture);
			TEXTURE2D(_MetallicTex);
			TEXTURE2D(_NormalTex);
			TEXTURE2D(_EmissionTex);
			TEXTURE2D(_AOTex);
			SAMPLER(sampler_BaseTexture);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
				float _MetallicStrength;
				float _NormalStrength;
				float _NormalStrength;
				float4 _EmissionColor;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positoinOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
				return o;
			}

			SurfaceData createSurfaceData()
			{
			}
			
			InputData createInputData()
			{
			}


			float4 frag(varryings i) : SV_TARGET
			{
				float4 sampleTexture = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				return sampleTexture * _BaseColor;
			}
			ENDHLSL
		}
	}
}