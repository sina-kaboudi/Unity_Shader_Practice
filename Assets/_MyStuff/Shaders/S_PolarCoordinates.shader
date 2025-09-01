Shader "Custom/S_PolarCoordinates"
{
    Properties
    {
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTexture("Main Texture", 2D) = "white" {}
        _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Float) = 1
        _LengthScale("Length Scale", Float) = 1
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

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTexture;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainColor;
                float4 _MainTexture_ST;
                float2 _Center;
                float _RadialScale;
                float _LengthScale;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);
                return OUT;
            }

            float2 CartesianToPolar(float2 cartUV)
            {
                float2 offset = cartUV - _Center;
                float radius = length(offset) * 2;
                float angle = atan2(offset.x, offset.y) / (2.0f * PI);

                return float2(angle, radius);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 radialUV = CartesianToPolar(IN.uv);
                radialUV.x *= _RadialScale;
                radialUV.y *= _LengthScale;

                float4 textureSample = tex2D(_MainTexture, radialUV);
                return _MainColor * textureSample;
            }
            ENDHLSL
        }
    }
}
