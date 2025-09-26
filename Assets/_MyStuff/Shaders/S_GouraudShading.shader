Shader "Custom/S_GouraudShading"
{
	Properties
	{
		_BaseTexture("Base Texture", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_GlossPower("Gloss Power", Float) = 400
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
			Name "Gouraud Shading"
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
				float4 diffuseLighting : TEXCOORD1;
				float4 specularLighting : TEXCOORD2;
			};

			TEXTURE2D(_BaseTexture);
			SAMPLER(sampler_BaseTexture);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
				float _GlossPower;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);

				float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
				float3 positionWS = TransformObjectToWorld(i.positionOS);
				float3 viewWS = GetWorldSpaceNormalizeViewDir(positionWS);

				Light mainLight = GetMainLight();
				float3 ambient = SampleSHVertex(normalWS);
				float3 diffuse = mainLight.color * max(0, dot(normalWS, mainLight.direction));
				float3 halfVector = normalize(mainLight.direction + viewWS);
				float3 specular = max(0, dot(normalWS, halfVector));
				specular = pow(specular, _GlossPower);
				float3 specularColor = mainLight.color * specular;

				o.diffuseLighting = float4(ambient + diffuse, 1.0);
				o.specularLighting = float4(specularColor, 1.0);

				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float4 sampleColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				return sampleColor * _BaseColor * i.diffuseLighting + i.specularLighting;
			}
			ENDHLSL
		}
	}
}