Shader "Custom/S_Triplaner"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_XTexture("X Texture", 2D) = "white" {}
		_YTexture("Y Texture", 2D) = "white" {}
		_ZTexture("Z Texture", 2D) = "white" {}
		_Tile("Texture Tiling", Float) = 1
		_BlendPower("Triplanar Blending", Float) = 10
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
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXDOORD0;
				float3 positionWS : TEXDOORD1;
			};

			sampler2D _XTexture;
			sampler2D _YTexture;
			sampler2D _ZTexture;

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float _Tile;
				float _BlendPower;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
				o.normalWS = TransformObjectToWorldNormal(i.normalOS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float2 xAxisUV = i.normalWS.yz * _Tile;
				float2 yAxisUV = i.normalWS.xz * _Tile;
				float2 zAxisUV = i.normalWS.xy * _Tile;

				float4 xSample = tex2D(_XTexture, xAxisUV);
				float4 ySample = tex2D(_YTexture, yAxisUV);
				float4 zSample = tex2D(_ZTexture, zAxisUV);

				float3 weights = pow(abs(i.normalWS), _BlendPower);
				weights /= (weights.x + weights.y + weights.z);

				float4 finalSampleColor = xSample * weights.x + ySample * weights.y + zSample * weights.z;
				return _BaseColor * finalSampleColor;
			}

			ENDHLSL
		}
	}
}