Shader "Custom/S_Xray"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0,0,1,1)
        _XrayColor("Xray Color", Color) = (1,0,0,1)
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

            float4 _BaseColor;
            sampler2D _BaseTex;
            float4 _BaseTex_ST;

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

            struct appdata2
            {
                float4 positionOS : POSITION;
            };
            struct v2f2
            {
                float4 positionCS : SV_POSITION;
            };

            float4 _XrayColor;

            v2f2 vert (appdata2 v)
            {
                v2f2 o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            float4 frag (v2f2 i) : SV_TARGET
            {
                return _XrayColor;
            }
            ENDHLSL
        }
    }
}
