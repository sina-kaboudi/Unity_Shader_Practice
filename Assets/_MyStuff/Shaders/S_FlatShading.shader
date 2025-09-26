Shader "Custom/S_FlatShading"
{
	Properties
	{
		_BaseTexture("Base Texture", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass
		{
			Name "FlatShading"

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
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				nointerpolation float4 flatLighting : TEXCOORD1;
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
				float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
				float3 ambient = SampleSHVertex(normalWS);
				Light mainLight = GetMainLight();
				float3 diffuse = mainLight.color * max(0, dot(normalWS, mainLight.direction));
				o.flatLighting = float4(ambient + diffuse, 1.0f);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float4 sampleColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				return sampleColor * _BaseColor * i.flatLighting;
			}
			ENDHLSL
		}
	}
}