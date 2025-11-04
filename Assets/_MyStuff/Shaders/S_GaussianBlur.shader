Shader "CustomEffects/S_GaussianBlur"
{
    HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        float _VerticalBlur;
        float _HorizontalBlur;

        // Adjustable blur spread (sigma)
        // Controls how "wide" the Gaussian curve is.
        // Higher = softer blur, Lower = sharper blur.
        static const float SIGMA = 10.0;

        // Number of samples on each side of the center
        static const int HALF_KERNEL = 8; // total = 17 samples (center + 8 each side)

        // ---------------------------------------------------------------------
        // Helper function: compute Gaussian weight
        // (precomputing could be done on CPU, but this is simple enough here)
        // ---------------------------------------------------------------------
        float GaussianWeight(int i, float sigma)
        {
            float x = i;
            return exp(-0.5 * (x * x) / (sigma * sigma));
        }

        // ---------------------------------------------------------------------
        // Vertical Gaussian Blur
        // ---------------------------------------------------------------------
        float4 BlurVertical(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float3 color = 0;
            float totalWeight = 0;

            float texelSizeY = _BlitTexture_TexelSize.w;
            float blurPixels = _VerticalBlur * _ScreenParams.y;

            // Center sample
            float centerWeight = GaussianWeight(0, SIGMA);
            color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord).rgb * centerWeight;
            totalWeight += centerWeight;

            // Sample pairs above and below center
            [unroll]
            for (int i = 1; i <= HALF_KERNEL; i++)
            {
                float weight = GaussianWeight(i, SIGMA);
                float2 offset = float2(0, (blurPixels / texelSizeY) * (i / (float)HALF_KERNEL));

                // Top and bottom
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord + offset).rgb * weight;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord - offset).rgb * weight;

                totalWeight += 2.0 * weight;
            }

            return float4(color / totalWeight, 1);
        }

        // ---------------------------------------------------------------------
        // Horizontal Gaussian Blur
        // ---------------------------------------------------------------------
        float4 BlurHorizontal(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float3 color = 0;
            float totalWeight = 0;

            float texelSizeX = _BlitTexture_TexelSize.z;
            float blurPixels = _HorizontalBlur * _ScreenParams.x;

            // Center sample
            float centerWeight = GaussianWeight(0, SIGMA);
            color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord).rgb * centerWeight;
            totalWeight += centerWeight;

            // Sample pairs left and right
            [unroll]
            for (int i = 1; i <= HALF_KERNEL; i++)
            {
                float weight = GaussianWeight(i, SIGMA);
                float2 offset = float2((blurPixels / texelSizeX) * (i / (float)HALF_KERNEL), 0);

                // Left and right
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord + offset).rgb * weight;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord - offset).rgb * weight;

                totalWeight += 2.0 * weight;
            }

            return float4(color / totalWeight, 1);
        }

    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off Cull Off

        // Vertical pass
        Pass
        {
            Name "GaussianVertical"
            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment BlurVertical
            ENDHLSL
        }

        // Horizontal pass
        Pass
        {
            Name "GaussianHorizontal"
            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment BlurHorizontal
            ENDHLSL
        }
    }
}
