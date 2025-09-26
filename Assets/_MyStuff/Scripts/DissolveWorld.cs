using UnityEngine;

public class DissolveWorld : MonoBehaviour
{
    [SerializeField] private Renderer m_renderer;
    private Material m_material;

    private void Start()
    {
        m_material = m_renderer.material;
    }

    private void Update()
    {
        m_material.SetVector("_PlaneOrigin", transform.position);
        m_material.SetVector("_PlaneNormal", transform.up);
    }
}