Shader "Custom/S_SimpleTexture"
{
    Properties
    {
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTexture("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Name "Normal Pass"
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
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

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTexture;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainColor;
                float4 _MainTexture_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return _MainColor * (tex2D(_MainTexture, IN.uv));
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            ColorMask 0
        }
    }
}