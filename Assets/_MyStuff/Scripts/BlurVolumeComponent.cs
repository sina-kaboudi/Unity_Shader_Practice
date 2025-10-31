using System;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Custom/BlurVolumeComponent")]
public class BlurVolumeComponent : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter horizontalBlur = new ClampedFloatParameter(0.05f, 0, 0.5f);
    public ClampedFloatParameter verticalBlur = new ClampedFloatParameter(0.05f, 0, 0.5f);

    public bool IsActive()
    {
        return horizontalBlur.value > 0.0f || verticalBlur.value > 0.0f;
    }
}