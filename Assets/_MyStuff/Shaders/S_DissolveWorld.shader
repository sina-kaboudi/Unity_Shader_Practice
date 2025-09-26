Shader "Custom/S_DissolveWorld"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 2D) = "white" {}
		_NoiseScale("Noise Scale", Float) = 20
		_NoiseStrength("Noise Strength", Range(0.0, 1.0)) = 1
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
				float3 positionWS : TEXCOORD1;
			};

			TEXTURE2D(_BaseTexture);
			SAMPLER(sampler_BaseTexture);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
				float3 _PlaneOrigin;
				float3 _PlaneNormal;
				float _NoiseScale;
				float _NoiseStrength;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
				return o;
			}

			// Generate a grid corner random unit vector.
			float2 generateDir(float2 p)
			{
				  p = p % 289;
				  float x = (34 * p.x + 1) * p.x % 289 + p.y;
				  x = (34 * x + 1) * x % 289;
				  x = frac(x / 41) * 2 - 1;
				  return normalize(float2(x-floor(x+0.5), abs(x)-0.5));
			}

			float generateNoise(float2 p)
			{
				float2 ip = floor(p);
				float2 fp = frac(p);
				// Calculate the nearest four grid point vectors.
				float d00 = dot(generateDir(ip), fp);
				float d01 = dot(generateDir(ip + float2(0, 1)), fp - float2(0, 1));
				float d10 = dot(generateDir(ip + float2(1, 0)), fp - float2(1, 0));
				float d11 = dot(generateDir(ip + float2(1, 1)), fp - float2(1, 1));
				// Do 'smootherstep' between the dot products then bilinearly interpolate.
				fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
				return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
			}

			// This function outputs in the range [-1, 1].
			float gradientNoise(float2 UV, float Scale)
			{
				return generateNoise(UV * Scale);
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float noiseSample = gradientNoise(i.uv, _NoiseScale) * _NoiseStrength;
				float3 noiseYWorldPos = i.positionWS.xyz + _PlaneNormal * noiseSample;

				float3 offset = noiseYWorldPos - _PlaneOrigin;

				if (dot(offset, _PlaneNormal) > 0.0) discard;

				float4 sampleColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
				return sampleColor * _BaseColor;
			}

			ENDHLSL
		}
	}
}