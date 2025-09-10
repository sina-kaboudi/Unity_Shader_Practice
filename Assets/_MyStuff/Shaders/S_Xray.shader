Shader "Custom/S_Xray"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0,0,1,1)
        _BaseTex("Base Texture", 2D) = "white" {}
        _XrayColor("Xray Color", Color) = (1,0,0,1)
        _XrayTex("Xray Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            ZTest LEqual
            ZWrite on

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

            sampler2D _BaseTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseTex_ST;
            CBUFFER_END

            v2f vert (appdata v)
            {
                  v2f o;
                  o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                  o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                  return o;
            }
            float4 frag (v2f i) : SV_TARGET
            {
                  float4 textureSample = tex2D(_BaseTex, i.uv);
                  return textureSample * _BaseColor;
            }

            ENDHLSL
        }

        Pass
        {
            ZTest Greater
            ZWrite Off

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

            sampler2D _XrayTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _XrayColor;
                float4 _XrayTex_ST;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _XrayTex);
                return o;
            }

            float4 frag (v2f i) : SV_TARGET
            {
                float4 textureSample = tex2D(_XrayTex, i.uv);
                return _XrayColor * textureSample;
            }
            ENDHLSL
        }
    }
}
