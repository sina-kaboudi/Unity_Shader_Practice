Shader "Custom/S_UVRotation"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_BaseTexture("Base Texture", 2D) = "white" {}
		_Rotation("Rotation", Float) = 0.0
		_Center("Rotation Center", Vector) = (0, 0, 0, 0)
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

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _BaseTexture;

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _BaseTexture_ST;
				float _Rotation;
				float2 _Center;
			CBUFFER_END

			v2f vert(Attributes i)
			{
				float c = cos(_Rotation);
				float s = sin(_Rotation);
				float2x2 rotMatrix = float2x2
				(
					c, -s,
					s, c
				);

				v2f o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
				o.uv -= _Center;
				o.uv = mul(o.uv, rotMatrix);
				o.uv += _Center;

				return o;
			}

			float4 frag(v2f i) : SV_TARGET
			{
				float4 sampleTexture = tex2D(_BaseTexture, i.uv);
				return sampleTexture * _BaseColor;
			}

			ENDHLSL
		}
	}
}