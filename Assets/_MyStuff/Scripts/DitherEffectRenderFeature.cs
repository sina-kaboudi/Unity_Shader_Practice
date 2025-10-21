using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class DitherEffectRenderFeature : ScriptableRendererFeature
{
    public RenderPassEvent InjectionPoint = RenderPassEvent.AfterRenderingPostProcessing;
    public Material Material;

    private DitherEffectPass m_scriptablePass;

    public override void Create()
    {
        m_scriptablePass = new DitherEffectPass();
        m_scriptablePass.renderPassEvent = InjectionPoint;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (Material == null)
        {
            Debug.LogWarning($"DitherEffectRenderFeature material is null and will be skipped.");
            return;
        }

        m_scriptablePass.Setup(Material);
        renderer.EnqueuePass(m_scriptablePass);
    }

    class DitherEffectPass : ScriptableRenderPass
    {
        private const string m_passName = "DitherEffectPass";
        private Material m_blitMaterial;

        public void Setup(Material mat)
        {
            m_blitMaterial = mat;
            requiresIntermediateTexture = true;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var stack = VolumeManager.instance.stack;
            var customEffect = stack.GetComponent<SphereVolumeComponent>();

            if (!customEffect.IsActive()) return;

            var resourceData = frameData.Get<UniversalResourceData>();
            if (resourceData.isActiveTargetBackBuffer)
            {
                Debug.LogError($"Skipping pass dither pass. This effect requires an intermediate texture");
                return;
            }

            var source = resourceData.activeColorTexture;

            var destinationDesc = renderGraph.GetTextureDesc(source);
            destinationDesc.name = $"CameraColor-{m_passName}";
            destinationDesc.clearBuffer = false;

            TextureHandle destination = renderGraph.CreateTexture(destinationDesc);

            RenderGraphUtils.BlitMaterialParameters param = new(source, destination, m_blitMaterial, 0);
            renderGraph.AddBlitPass(param, passName: m_passName);

            resourceData.cameraColor = destination;
        }
    }
}