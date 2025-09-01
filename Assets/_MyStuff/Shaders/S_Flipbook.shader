Shader "Custom/S_Flipbook"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_BaseTexture("Base Texture", 2D) = "white" {}
		_FlipbookSize("Flipbook Size", Vector) = (1,1,0,0)
		_Speed("Flipbook Speed", Float) = 1.0
	}

	Subshader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
			"RenderPipleine" = "UniversalPipeline"
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

			struct appdata
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
				float2 _FlipbookSize;
				float _Speed;
			CBUFFER_END

			v2f vert(appdata i)
			{
				v2f o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

				float2 tileSize = float2(1.0f, 1.0f) / _FlipbookSize;
				float width = _FlipbookSize.x;
				float height = _FlipbookSize.y;
				float tileCount = width * height;
				float tileID = floor((_Time.y * _Speed) % tileCount);

				float tileX = (tileID % width) * tileSize.x;
				float tileY = (floor(tileID / width)) * tileSize.y;

				o.uv = float2
				(
					(i.uv.x * tileSize.x) + tileX,
					(i.uv.y * tileSize.y) + tileY
				);

				return o;
			}

			float4 frag(v2f i) : SV_TARGET
			{
				float4 sampleColor = tex2D(_BaseTexture, i.uv);
				return _BaseColor * sampleColor;
			}

			ENDHLSL
		}
	}
}