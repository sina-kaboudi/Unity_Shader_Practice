Shader "Custom/S_Waves"
{
	Properties
	{
		_BaseCol("Base Color", Color) = (1,1,1,1)
		_BaseTex("Base Texture", 2D) = "white" {}
		_MetallicTex("Metallic Map", 2D) = "white" {}
		_MetallicStrength("Metallic Strength", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_NormalTex("Normal Map", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		[Toggle(USE_EMISSION_ON)] _EmissionOn("Use Emission?", Float) = 0
		_EmissionTex("Emission Map", 2D) = "white" {}

		_WaveStrength("Wave Strength", Range(0, 2)) = 0.1
		_WaveSpeed("Wave Speed", Range(0, 10)) = 1

		[Enum(UnityEngine.Rendering.BlendMode)]
		_SrcBlend("Source Blend Factor", Int) = 1

		[Enum(UnityEngine.Rendering.BlendMode)]
		_DstBlend("Destination Blend Factor", Int) = 1

		_TessAmount("Tesselation Amount", Range(1, 64)) = 2
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

			Blend [_SrcBlend][_DstBlend]

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma hull tessHull;
			#pragma domain tessDomain;

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

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 staticLightmapUV : TEXCOORD2;
				float2 dynamicLightmapUV : TEXCOORD3;
			};

			struct tessControlPoint
			{
				float4 positionOS : INTERNALTESSPOS;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 staticLightmapUV : TEXCOORD2;
				float2 dynamicLightmapUV : TEXCOORD3;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float3 normalWS : TEXCOORD3;
				float4 tangentWS : TEXCOORD4;
				float3 viewDirWS : TEXCOORD5;
				float4 shadowCoord : TEXCOORD6;
				DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
				#ifdef DYNAMICLIGHTMAP_ON
						float2  dynamicLightmapUV : TEXCOORD8;
				#endif
			};

			struct tessFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			TEXTURE2D(_BaseTex);
			TEXTURE2D(_MetallicTex);
			TEXTURE2D(_NormalTex);
			TEXTURE2D(_EmissionTex);
			TEXTURE2D(_AOTex);
			SAMPLER(sampler_BaseTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseCol;
				float4 _BaseTex_ST;
				float _MetallicStrength;
				float _Smoothness;
				float _NormalStrength;
				float4 _EmissionColor;

				float _WaveStrength;
				float _WaveSpeed;
				float _TessAmount;
			CBUFFER_END

			SurfaceData createSurfaceData(Varyings i)
			{
				SurfaceData surfaceData = (SurfaceData)0;

				//Albedo output
				float4 albedoSample = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv);
				surfaceData.albedo = albedoSample.rgb * _BaseCol.rgb;

				//Metallic output
				float4 metallicSample = SAMPLE_TEXTURE2D(_MetallicTex, sampler_BaseTex, i.uv);
				surfaceData.metallic = metallicSample.r * _MetallicStrength;

				//Smoothness output
				surfaceData.smoothness = _Smoothness;

				//Normal output
				float3 normalSample1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_BaseTex, i.uv));
				normalSample1.rb *= _NormalStrength;

				float3 normalSample2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_BaseTex, i.uv2));
				normalSample2.rb *= _NormalStrength;

				float3 finalNormalSample = normalize(normalSample1 + normalSample2);

				surfaceData.normalTS = finalNormalSample;

				//Emission output
				#if USE_EMISSION_ON
					surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_BaseTex, i.uv) * _EmissionColor;
				#endif

				//Ambient Occlusion output
				float4 aoSample = SAMPLE_TEXTURE2D(_AOTex, sampler_BaseTex, i.uv);
				surfaceData.occlusion = aoSample.r;

				//Alpha output
				surfaceData.alpha = albedoSample.a * _BaseCol.a;

				return surfaceData;
			}
			
			
			InputData createInputData(Varyings i, float3 normalTS)
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

			tessControlPoint vert(Attributes i)
			{
				tessControlPoint o;
				o.positionOS = i.positionOS;
				o.uv = i.uv;
				o.uv2 = i.uv2;
				o.normalOS = i.normalOS;
				o.tangentOS = i.tangentOS;
				o.staticLightmapUV = i.staticLightmapUV;
				o.dynamicLightmapUV = i.dynamicLightmapUV;
				return o;
			}

			Varyings tessVert(Attributes i)
			{
				Varyings o;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);

				o.positionWS = vertexInput.positionWS;
				o.positionCS = vertexInput.positionCS;

				o.uv = TRANSFORM_TEX(i.uv, _BaseTex);
				o.uv2 = TRANSFORM_TEX(i.uv2, _BaseTex);

				o.normalWS = normalInput.normalWS;

				float sign = i.tangentOS.w;
				o.tangentWS = float4(normalInput.tangentWS, sign);

				o.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
				o.shadowCoord = GetShadowCoord(vertexInput);

				OUTPUT_LIGHTMAP_UV(i.staticLightmapUV, unity_LightmapST, o.staticLightmapUV);

				#ifdef DYNAMICLIGHTMAP_ON
					i.dynamicLightmapUV = i.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				OUTPUT_SH(o.normalWS.xyz, o.vertexSH);

				float height = sin(_Time.y * _WaveSpeed + o.positionWS.x + o.positionWS.z);

				o.positionWS.y += height * _WaveStrength;
				float t1 = _Time.x * 0.5f;
				float t2 = _Time.x * 1.5f;
				o.uv = float2(o.uv.x + t1, o.uv.y + t1) * 1.5f;
				o.uv2 = float2(o.uv.x, o.uv.y + t2) * 2.0f;

				o.positionCS = TransformWorldToHClip(o.positionWS);
				return o;
			}

			[domain("tri")]
			[outputcontrolpoints(3)]
			[outputtopology("triangle_cw")]
			[partitioning("fractional_even")]
			[patchconstantfunc("patchConstantFunc")]
			tessControlPoint tessHull(InputPatch<tessControlPoint, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			tessFactors patchConstantFunc(InputPatch<tessControlPoint, 3> patch)
			{
				tessFactors f;
				f.edge[0] = f.edge[1] = f.edge[2] = _TessAmount;
				f.inside = _TessAmount;
				return f;
			}

			[domain("tri")]
			Varyings tessDomain(tessFactors factors, OutputPatch<tessControlPoint, 3> patch, float3 bcCoords : SV_DomainLocation)
			{
				Attributes i = (Attributes)0;
				i.positionOS = patch[0].positionOS * bcCoords.x +
					patch[1].positionOS * bcCoords.y +
					patch[2].positionOS * bcCoords.z;

				i.uv = patch[0].uv * bcCoords.x +
					patch[1].uv * bcCoords.y +
					patch[2].uv * bcCoords.z;

				i.uv2 = patch[0].uv2 * bcCoords.x +
					patch[1].uv2 * bcCoords.y +
					patch[2].uv2 * bcCoords.z;

				i.normalOS = patch[0].normalOS * bcCoords.x +
					patch[1].normalOS * bcCoords.y +
					patch[2].normalOS * bcCoords.z;

				i.tangentOS = patch[0].tangentOS * bcCoords.x +
					patch[1].tangentOS * bcCoords.y +
					patch[2].tangentOS * bcCoords.z;

				i.staticLightmapUV = patch[0].staticLightmapUV * bcCoords.x +
					patch[1].staticLightmapUV * bcCoords.y +
					patch[2].staticLightmapUV * bcCoords.z;

				i.dynamicLightmapUV = patch[0].dynamicLightmapUV * bcCoords.x +
					patch[1].dynamicLightmapUV * bcCoords.y +
					patch[2].dynamicLightmapUV * bcCoords.z;

				// i.normalOS = patch[0].normalOS;
				// i.tangentOS = patch[0].tangentOS;
				// i.staticLightmapUV = patch[0].staticLightmapUV;
				// i.dynamicLightmapUV = patch[0].dynamicLightmapUV;

				return tessVert(i);
			}

			float4 frag(Varyings i) : SV_TARGET
			{
				SurfaceData surfaceData = createSurfaceData(i);
				InputData inputData = createInputData(i, surfaceData.normalTS);
				return UniversalFragmentPBR(inputData, surfaceData);
			}
			ENDHLSL
		}
	}
}