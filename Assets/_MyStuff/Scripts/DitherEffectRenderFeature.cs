using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class DitherEffectRenderFeature : ScriptableRendererFeature
{
    public Material Material;

    DitherEffectRenderFeaturePass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new DitherEffectRenderFeaturePass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (Material == null)
        {
            Debug.LogWarning($"DitherEffectRenderFeature material is null and will be skipped.");
            return;
        }

        m_ScriptablePass.Setup(Material);
        renderer.EnqueuePass(m_ScriptablePass);
    }

    class DitherEffectRenderFeaturePass : ScriptableRenderPass
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
                Debug.LogError($"Skipping pass {m_passName}. This effect requires an intermediate texture");
                return;
            }

            TextureHandle source = resourceData.activeColorTexture;
            TextureDesc destinationDesc = source.GetDescriptor(renderGraph);
            destinationDesc.name = $"CameraColor-{m_passName}";
            destinationDesc.clearBuffer = false;

            TextureHandle destination = renderGraph.CreateTexture(destinationDesc);

            RenderGraphUtils.BlitMaterialParameters param = new(source, destination, m_blitMaterial, 0);
            renderGraph.AddBlitPass(param, passName: m_passName);

            resourceData.cameraColor = destination;
        }
    }
}