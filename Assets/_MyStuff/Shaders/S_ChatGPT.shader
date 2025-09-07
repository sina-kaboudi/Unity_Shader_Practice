Shader "Custom/S_ChatGPT"
{
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        // Forward color pass
        Pass
        {
            Name "ForwardColor"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vert(Attributes IN)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return o;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return half4(1, 0, 0, 1); // solid red
            }
            ENDHLSL
        }

        // DepthNormals pass
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            ColorMask RG // URP writes normals into RG channels
        }
    }
}