// A brazier's fire light.
using UnityEngine;
public class Flicker : MonoBehaviour
{
    public float baseIntensity = 1.6f; Light l; float seed;
    void Start() { l = GetComponent<Light>(); seed = Random.value * 50; }
    void Update() { float t = Time.time + seed; l.intensity = baseIntensity * (0.82f + 0.12f * Mathf.PerlinNoise(t * 7, 0.3f) + 0.06f * Mathf.Sin(t * 19)); }
}
