Shader "Custom/S_PhongShading"
{
	Properties
	{
		_BaseTexture("Base Texture", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_GlossPower("Gloss Power", Float) = 400
		_FresnalPower("Fresnal Power", Float) = 5
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
			Name "PhongShading"
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
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float3 viewWS : TEXCOORD2;
			};

			TEXTURE2D(_BaseTexture);
			SAMPLER(sampler_BaseTexture);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
				float _GlossPower;
				float _FresnalPower;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
				o.normalWS = TransformObjectToWorldNormal(i.normalOS);

				float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
				o.viewWS = GetWorldSpaceViewDir(positionWS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float3 normal = normalize(i.normalWS);
				float3 view = normalize(i.viewWS);

				float3 ambient = SampleSH(normal);

				Light mainLight = GetMainLight();

				float3 diffuse = mainLight.color * max(0, dot(normal, mainLight.direction));

				float3 halfVector = normalize(view + mainLight.direction);
				float specular = max(0, dot(normal, halfVector));
				specular = pow(specular, _GlossPower);
				float3 specularColor = mainLight.color * specular;

				float4 diffuseLighting = float4(ambient + diffuse, 1.0);
				float4 specularLighting = float4(specularColor, 1.0);

				float4 sampleColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				return sampleColor * _BaseColor * diffuseLighting + specularLighting;
			}
			ENDHLSL
		}
	}
}