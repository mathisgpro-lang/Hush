// The Flame as a real 3D light: it warms the stones of the circle and the pillars, flickering with its fire; it flares
// when it catches light.
using UnityEngine;
public class FlameLight3D : MonoBehaviour
{
    public Light glow;
    public float baseIntensity = 2.2f, baseRange = 5.5f;
    float flare;
    void Update()
    {
        float t = Time.time;
        float flicker = 0.88f + 0.08f * (Mathf.PerlinNoise(t * 6.5f, 0.2f) * 2 - 1) + 0.04f * Mathf.Sin(t * 23f);
        flare = Mathf.MoveTowards(flare, 0, Time.deltaTime * 1.3f);
        glow.intensity = baseIntensity * flicker + flare * 3f;
        glow.range = baseRange + flare * 2.5f + Mathf.Sin(t * 1.7f) * 0.1f;
    }
    public void Flare() { flare = 1; }
}
