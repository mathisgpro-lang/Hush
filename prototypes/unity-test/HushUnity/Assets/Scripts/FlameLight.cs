// The Flame as a real light source (URP 2D lights): it lights the painted stones around it and flickers with its fire.
// A brief flare when it catches light.
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class FlameLight : MonoBehaviour
{
    public Light2D glow;            // the warm light on the world
    public Light2D core;            // a tighter, brighter light at the feet
    public float baseIntensity = 1.1f;
    float flare;

    void Update()
    {
        float t = Time.time;
        float flicker = 0.88f + 0.08f * (Mathf.PerlinNoise(t * 6.5f, 0.2f) * 2 - 1) + 0.04f * Mathf.Sin(t * 23f);
        flare = Mathf.MoveTowards(flare, 0, Time.deltaTime * 1.4f);
        glow.intensity = baseIntensity * flicker + flare * 1.2f;
        glow.pointLightOuterRadius = 3.2f + flare * 1.2f + Mathf.Sin(t * 1.7f) * 0.08f;
        if (core) core.intensity = (baseIntensity * 0.9f) * flicker + flare;
    }

    public void Flare() { flare = 1; }
}
