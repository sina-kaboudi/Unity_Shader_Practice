Shader "Cutsom/S_SceneIntersection"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (0,0,0,1)
		_IntersectionColor("Intersection Color", Color) = (1,1,1,1)
		_Strength("Strength", Range(0.1, 100)) = 1
	}

	Subshader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Geometry"
			"Queue" = "Transparent"
		}

		Pass
		{
			Name "ForwardColor"
			Tags
			{
				"LightModel" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			struct attributes
			{
				float4 positionOS : POSITION;
			};

			struct varryings
			{
				float4 positionCS : SV_POSITION;
				float4 positionSS : TEXCOORD0;
			};

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _IntersectionColor;
				float _Strength;
			CBUFFER_END

			varryings vert(attributes i)
			{
				varryings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionSS = ComputeScreenPos(o.positionCS);
				return o;
			}

			float4 frag(varryings i) : SV_TARGET
			{
				float2 screenUV = i.positionSS.xy / i.positionSS.w;
				float rawDepth = SampleSceneDepth(screenUV);
				float eyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
				float screenPosW = i.positionSS.w;

				float intersectAmount = eyeDepth - screenPosW;
				intersectAmount = saturate(1.0 - intersectAmount);
				intersectAmount = pow(intersectAmount, _Strength);

				float4 finalColor = lerp(_BaseColor, _IntersectionColor, intersectAmount);
				return finalColor;
			}
			ENDHLSL
		}

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            ColorMask RG // URP writes normals into RG channels
        }
	}
}