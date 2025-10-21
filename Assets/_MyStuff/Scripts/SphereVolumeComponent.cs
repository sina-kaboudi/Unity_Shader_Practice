using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Custom/SphereVolumeComponent")]
public class SphereVolumeComponent : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter intensity = new ClampedFloatParameter(value: 0.0f, min: 0.0f, max: 1.0f, overrideState: true);

    public bool IsActive() => intensity.value > 0.0f;
}