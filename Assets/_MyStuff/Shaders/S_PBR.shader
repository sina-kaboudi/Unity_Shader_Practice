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

			#pragma multi_compile_local USE_EMISSION_ON __
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING

			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON

			struct attributes
			{
				float4 positoinOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 staticLightmapUV : TEXCOORD1;
				float2 dynamicLightmapUV : TEXCOORD2;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float3 normalWS : TEXCOORD2;
				float4 tangentWS : TEXCOORD3;
				float3 viewDirWS : TEXCOORD4;
				float4 shadowCoord : TEXCOORD5;
				DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 6);
				#ifdef DYNAMICLIGHTMAP_ON
						float2  dynamicLightmapUV : TEXCOORD7;
				#endif
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
				float _Smoothness;
				float _NormalStrength;
				float4 _EmissionColor;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positoinOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);

				o.positionWS = vertexInput.positionWS;
				o.positionCS = vertexInput.positionCS;

				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);

				o.normalWS = normalInput.normalWS;

				float sign = i.tangentOS.w;
				o.tangentWS = float4(normalInput.tangentWS.xyz, sign);

				o.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
				o.shadowCoord = GetShadowCoord(vertexInput);

				OUTPUT_LIGHTMAP_UV(i.staticLightmapUV, unity_LightmapST, o.staticLightmapUV);

				#ifdef DYNAMICLIGHTMAP_ON
					i.dynamicLightmapUV = i.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
				return o;
			}

			SurfaceData createSurfaceData(varryings i)
			{
				SurfaceData surfaceData = (SurfaceData)0;

				//Albedo output
				float4 albedoSample = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				surfaceData.albedo = albedoSample.rgb * _BaseColor.rgb;

				//Metallic output
				float4 metallicSample = SAMPLE_TEXTURE2D(_MetallicTex, sampler_BaseTexture, i.uv);
				surfaceData.metallic = metallicSample.r * _MetallicStrength;

				//Smoothness output
				surfaceData.smoothness = _Smoothness;

				//Normal output
				float3 normalSample = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_BaseTexture, i.uv));
				normalSample.rb *= _NormalStrength;
				surfaceData.normalTS = normalSample;

				//Emission output
				#if USE_EMISSION_ON
					surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_BaseTexture, i.uv) * _EmissionColor;
				#endif

				//Ambient Occlusion output
				float4 aoSample = SAMPLE_TEXTURE2D(_AOTex, sampler_BaseTexture, i.uv);
				surfaceData.occlusion = aoSample.r;

				//Alpha output
				surfaceData.alpha = albedoSample.a * _BaseColor.a;

				return surfaceData;
			}
			
			InputData createInputData(varryings i, float3 normalTS)
			{
				InputData inputData = (InputData)0;

				//Position input
				inputData.positionWS = i.positionWS;

				//Normal input
				float3 bitangent = i.tangentWS.w * cross(i.normalWS, i.tangentWS.xyz);
				inputData.tangentToWorld = float3x3
				(
					i.tangentWS.xyz,
					bitangent,
					i.normalWS
				);
				inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentToWorld);
				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

				//View Direction input
				inputData.viewDirectionWS = SafeNormalize(i.viewDirWS);

				//Shadow coords
				inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);

				//Baked lightmaps
				#if defined(DYNAMICLIGHTMAP_ON)
					InputData.bakedGI = SAMPLE_GI(i.staticLightmapUV, i.dynamicLightmapUV, i.vertexSH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(i.staticLightmapUV, i.vertexSH, inputData.normalWS);
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
				inputData.shadowMask = SAMPLE_SHADOWMASK(i.staticLightmapUV);

				return inputData;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				SurfaceData surfaceData = createSurfaceData(i);
				InputData inputData = createInputData(i, surfaceData.normalTS);
				return UniversalFragmentPBR(inputData, surfaceData);
			}
			ENDHLSL
		}
	}
}