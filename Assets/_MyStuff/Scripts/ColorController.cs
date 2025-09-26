using UnityEngine;

public class ColorController : MonoBehaviour
{
    [SerializeField] private Material m_material;

    private void Update()
    {
        var currentColor = m_material.GetColor("_MainColor");

        Color.RGBToHSV(currentColor, out var hue, out var sat, out var value);
        hue = (Time.time * 0.25f) % 1.0f;

        currentColor = Color.HSVToRGB(hue, sat, value);
        m_material.SetColor("_MainColor", currentColor);
    }
}