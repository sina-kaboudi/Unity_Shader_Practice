using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class BlurRendererFeature : ScriptableRendererFeature
{
    [SerializeField] BlurSettings settings;
    [SerializeField] private Shader shader;
    private Material material;
    private BlurRenderPass blurRenderPass;

    public override void Create()
    {
        if (shader == null)
        {
            return;
        }
        material = new Material(shader);
        blurRenderPass = new BlurRenderPass(settings, material);

        blurRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (blurRenderPass == null)
        {
            return;
        }
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(blurRenderPass);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (Application.isPlaying)
        {
            Destroy(material);
        }
        else
        {
            DestroyImmediate(material);
        }
    }

    [Serializable]
    public class BlurSettings
    {
        [Range(0, 0.4f)] public float horizontalBlur;
        [Range(0, 0.4f)] public float verticalBlur;
    }

    class BlurRenderPass : ScriptableRenderPass
    {
        private BlurSettings defaultSettings;
        private Material material;
        private TextureDesc blurTextureDescriptor;

        private static readonly int horizontalBlurId = Shader.PropertyToID("_HorizontalBlur");
        private static readonly int verticalBlurId = Shader.PropertyToID("_VerticalBlur");
        private const string k_BlurTextureName = "_BlurTexture";
        private const string k_VerticalPassName = "VerticalBlurRenderPass";
        private const string k_HorizontalPassName = "HorizontalBlurRenderPass";

        public BlurRenderPass(BlurSettings settings, Material material)
        {
            this.defaultSettings = settings;
            this.material = material;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            TextureHandle srcCamColor = resourceData.activeColorTexture;
            blurTextureDescriptor = srcCamColor.GetDescriptor(renderGraph);
            blurTextureDescriptor.name = k_BlurTextureName;
            blurTextureDescriptor.depthBufferBits = 0;
            TextureHandle dst = renderGraph.CreateTexture(blurTextureDescriptor);

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

            if (resourceData.isActiveTargetBackBuffer)
                return;

            // Update the blur settings in the material
            UpdateBlurSettings();

            // This check is to avoid an error from the material preview in the scene
            if (!srcCamColor.IsValid() || !dst.IsValid())
                return;

            // The AddBlitPass method adds a vertical blur render graph pass that blits from the source texture (camera color in this case) to the destination texture using the first shader pass (the shader pass is defined in the last parameter).
            RenderGraphUtils.BlitMaterialParameters paraVertical = new(srcCamColor, dst, material, 0);
            renderGraph.AddBlitPass(paraVertical, k_VerticalPassName);

            // The AddBlitPass method adds a horizontal blur render graph pass that blits from the texture written by the vertical blur pass to the camera color texture. The method uses the second shader pass.
            RenderGraphUtils.BlitMaterialParameters paraHorizontal = new(dst, srcCamColor, material, 1);
            renderGraph.AddBlitPass(paraHorizontal, k_HorizontalPassName);
        }

        private void UpdateBlurSettings()
        {
            if (material == null) return;

            // Use the Volume settings or the default settings if no Volume is set.
            var volumeComponent = VolumeManager.instance.stack.GetComponent<BlurVolumeComponent>();
            float horizontalBlur = volumeComponent.horizontalBlur.overrideState ?
                volumeComponent.horizontalBlur.value : defaultSettings.horizontalBlur;
            float verticalBlur = volumeComponent.verticalBlur.overrideState ?
                volumeComponent.verticalBlur.value : defaultSettings.verticalBlur;

            material.SetFloat(horizontalBlurId, horizontalBlur);
            material.SetFloat(verticalBlurId, verticalBlur);
        }
    }
}
