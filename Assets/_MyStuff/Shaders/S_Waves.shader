Shader "Custom/S_Waves"
{
	Properties
	{
		_BaseCol("Base Color", Color) = (1,1,1,1)
		_BaseTex("Base Texture", 2D) = "white" {}
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
			#pragma target 4.6

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct tessControlPoint
			{
				float4 positionOS : INTERNALTESSPOS;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct tessFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			TEXTURE2D(_BaseTex);
			SAMPLER(sampler_BaseTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseCol;
				float4 _BaseTex_ST;
				float _WaveStrength;
				float _WaveSpeed;
				float _TessAmount;
			CBUFFER_END

			tessControlPoint vert(Attributes i)
			{
				tessControlPoint o;
				o.positionOS = i.positionOS;
				o.uv = i.uv;
				return o;
			}

			Varyings tessVert(Attributes v)
			{
				Varyings o;
				float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
				float height = sin(_Time.y * _WaveSpeed + positionWS.x + positionWS.z);

				positionWS.y += height * _WaveStrength;

				o.positionCS = TransformWorldToHClip(positionWS);
				o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
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
				  Attributes i;
				  i.positionOS = patch[0].positionOS * bcCoords.x +
						patch[1].positionOS * bcCoords.y +
						patch[2].positionOS * bcCoords.z;

				  i.uv = patch[0].uv * bcCoords.x +
						patch[1].uv * bcCoords.y +
						patch[2].uv * bcCoords.z;

				  return tessVert(i);
			}

			float4 frag(Varyings i) : SV_TARGET
			{
				float4 texSample = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv);
				return texSample * _BaseCol;
			}
			ENDHLSL
		}
	}
}