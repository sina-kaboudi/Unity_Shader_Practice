Shader "Custom/BlinnPhong"
{
	Properties
	{
		_Diffuse ("Texture", 2D) = "white" {}
		_Normal ("Normal", 2D) = "blue" {}
		_Specular ("Specular", 2D) = "black" {}
		_Environment ("Environment", Cube) = "white" {}
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }	

		Pass
		{
			Tags {"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct vIN
			{
				 float4 vertex : POSITION;
				 float4 normal : NORMAL;
				 float4 tangent : TANGENT;
				 float2 uv : TEXCOORD0;
			};

			struct vOUT
			{
				float4 pos : SV_POSITION;
				float3x3 tbn : TEXCOORD0;
				float2 uv : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
			};

			vOUT vert(vIN v)
			{
				vOUT o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.uv;

				float3 worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
				float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
				float3 worldBitan = cross(worldNormal, worldTangent);

				o.worldPos = TransformObjectToWorld(v.vertex.xyz);
				o.tbn = float3x3(worldTangent, worldBitan, worldNormal);
				return o;
			}

			TEXTURE2D(_Diffuse);
			SAMPLER(sampler_Diffuse);

			TEXTURE2D(_Normal);
			SAMPLER(sampler_Normal);

			TEXTURE2D(_Specular);
			SAMPLER(sampler_Specular);

			TEXTURECUBE(_Environment);
			SAMPLER(sampler_Environment);

			float4 frag(vOUT i) : SV_Target
			{
				Light mainLight = GetMainLight();

				//common vectors
				float3 unpackNormal = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Diffuse, i.uv));
				float3 nrm = normalize(mul(transpose(i.tbn), unpackNormal));
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfVec = normalize(viewDir + _MainLightPosition.xyz);
				float3 env = SAMPLE_TEXTURECUBE(_Environment, sampler_Environment, reflect(-viewDir, nrm)).rgb;
				float3 sceneLight = lerp(mainLight.color, env + mainLight.color * 0.5, 0.5);
				//float3 sceneLight = lerp(_MainLightColor.xyz, env + _MainLightColor.xyz * 0.5, 0.5);

				//light amounts
				float diffAmt = max(dot(nrm, _MainLightPosition.xyz), 0.0);
				float specAmt = max(0.0, dot(halfVec, nrm));
				specAmt = pow(specAmt, 4.0);
				//sample maps
				float4 tex = SAMPLE_TEXTURE2D(_Diffuse, sampler_Diffuse, i.uv);
				float4 specMask = SAMPLE_TEXTURE2D(_Specular, sampler_Specular, i.uv);
				//compute specular color
				float3 specCol = specMask.rgb * specAmt;
				//incorporate data aboout light color and ambient
				float3 finalDiffuse = sceneLight * diffAmt * tex.rgb;
				float3 finalSpec = specCol * sceneLight;
				//float3 finalAmbient = UNITY_LIGHTMODEL_AMBIENT.rgb * tex.rgb; //this seems to give 0 in urp
				float3 finalAmbient = SampleSH(nrm) * tex.rgb;

				return float4( finalDiffuse + finalSpec + finalAmbient, 1.0);
			}

			ENDHLSL
		}
	}
}