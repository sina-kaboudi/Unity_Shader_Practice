Shader "Custom/S_ParticleFlipbook"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 3D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"RenderPipeline" = "UniversalRenderer"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

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
			};

			sampler3D _BaseTexture;

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float3 newUV = float3(i.uv, _Time.y);
				float4 sampleColor = tex3D(_BaseTexture, newUV);
				return _BaseColor * sampleColor;
			}

			ENDHLSL
		}
	}
}