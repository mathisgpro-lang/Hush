// Interaction sounds synthesized in code, in one key (D major pentatonic), the same as the Swift version.
using UnityEngine;

public class SoundSynth : MonoBehaviour
{
    public static SoundSynth I;
    AudioSource src, chargeSrc;
    static readonly float[] Penta = { 293.66f, 329.63f, 369.99f, 440f, 493.88f, 587.33f, 659.25f, 739.99f, 880f };
    const int Rate = 44100;

    void Awake()
    {
        I = this;
        src = gameObject.AddComponent<AudioSource>();
        chargeSrc = gameObject.AddComponent<AudioSource>();
    }

    AudioClip Make(float seconds, System.Func<float, float> f)
    {
        int n = (int)(seconds * Rate);
        var data = new float[n];
        for (int i = 0; i < n; i++) data[i] = f((float)i / Rate);
        var c = AudioClip.Create("s", n, 1, Rate, false);
        c.SetData(data, 0);
        return c;
    }

    static float Bell(float f, float t, float decay = 3f)
    {
        if (t < 0) return 0;
        float env = Mathf.Exp(-t * decay) * Mathf.Min(1, t * 200);
        return env * (Mathf.Sin(2 * Mathf.PI * f * t) * 0.6f + Mathf.Sin(2 * Mathf.PI * f * 2f * t) * 0.25f + Mathf.Sin(2 * Mathf.PI * f * 3.01f * t) * 0.1f);
    }

    public void StartCharge(float seconds)
    {
        float baseF = Penta[2], phase = 0;
        chargeSrc.clip = Make(seconds, t =>
        {
            float k = t / seconds, f = baseF * Mathf.Pow(2, k);
            phase += 2 * Mathf.PI * f / Rate;
            float env = Mathf.Min(1, t * 8) * (0.18f + 0.32f * k);
            return env * (Mathf.Sin(phase) * 0.7f + Mathf.Sin(phase * 2) * 0.15f) + (Random.value * 2 - 1) * 0.04f * k;
        });
        chargeSrc.Play();
    }
    public void StopCharge() { chargeSrc.Stop(); }

    public void Ignite()
    {
        float lp = 0;
        src.PlayOneShot(Make(1.6f, t =>
        {
            lp += ((Random.value * 2 - 1) - lp) * 0.08f;
            float fire = lp * Mathf.Exp(-t * 6) * 0.5f;
            float bells = Bell(Penta[2], t, 2.4f) + Bell(Penta[4], t - 0.05f, 2.4f) + Bell(Penta[6], t - 0.1f, 2.4f);
            return fire + bells * 0.28f;
        }));
    }

    public void Catch() { src.PlayOneShot(Make(0.6f, t => Bell(1174.66f, t, 7) * 0.25f + Bell(1479.98f, t - 0.08f, 7) * 0.2f)); }

    public void Sweep()
    {
        float phase = 0;
        src.PlayOneShot(Make(0.9f, t => { phase += 2 * Mathf.PI * (900 + 1400 * t) / Rate; return Mathf.Sin(Mathf.PI * t / 0.9f) * Mathf.Sin(phase) * 0.05f; }));
    }

    public void Babble(int syllables)
    {
        var notes = new float[syllables];
        for (int i = 0; i < syllables; i++) notes[i] = Penta[Random.Range(3, 9)];
        src.PlayOneShot(Make(syllables * 0.13f, t =>
        {
            int i = Mathf.Min(syllables - 1, (int)(t / 0.13f));
            float local = t - i * 0.13f, env = Mathf.Sin(Mathf.PI * Mathf.Min(1, local / 0.12f));
            float f = notes[i] * (1 + 0.04f * Mathf.Sin(local * 40));
            return env * (Mathf.Sin(2 * Mathf.PI * f * t) * 0.6f + Mathf.Sin(2 * Mathf.PI * f * 2 * t) * 0.3f) * 0.12f;
        }));
    }

    public void Rise()
    {
        float lp = 0;
        src.PlayOneShot(Make(1.8f, t =>
        {
            float a = 0.02f + 0.05f * Mathf.Sin(Mathf.PI * t / 1.8f);
            lp += ((Random.value * 2 - 1) - lp) * a;
            return lp * Mathf.Sin(Mathf.PI * t / 1.8f) * 1.4f;
        }));
    }
}
