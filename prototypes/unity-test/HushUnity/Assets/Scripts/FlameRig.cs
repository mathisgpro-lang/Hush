// Your Flame in Unity: Codex's painted parts assembled live, on spring physics (the C# port of FluidBody).
// Breathing, drifting, hops with gravity, squash and stretch, the tongues swaying and trailing, blinking, looking,
// smiling, babbling. The Flame is also a real light (FlameLight) that lights the painted world.
using UnityEngine;
using System.Collections;

public class FlameRig : MonoBehaviour
{
    public Transform body;            // feet pivot: squash, stretch, lean
    public Transform face;            // eyes, brows, mouth (shifts when looking)
    public Transform[] tongues;
    public SpriteRenderer eyeL, eyeR, mouth;
    public Sprite eyeOpenL, eyeOpenR, eyeClosedL, eyeClosedR, eyeUp, eyeDown;
    public Sprite mouthSmile, mouthJoy, mouthO, mouthTalk, mouthFlat;
    public float wanderRange = 0.35f;

    float t, vy, y, x, vx, rollV, roll, sq = 1, sqV;
    float hairX, hairXV;
    float biasX, extraRoll, stretchTarget = 1;
    Vector2 look, lookTarget;
    float[] tongueRest;
    bool eyesHeld;
    float talkUntil;
    float seed;

    void Start()
    {
        seed = Random.value * 100;
        tongueRest = new float[tongues.Length];
        for (int i = 0; i < tongues.Length; i++) tongueRest[i] = tongues[i].localEulerAngles.z;
        StartCoroutine(Blinking());
        StartCoroutine(Idles());
    }

    static float Noise(float v) => Mathf.PerlinNoise(v, 0.37f) * 2 - 1;

    void Spring(ref float val, ref float vel, float target, float k, float d, float dt)
    {
        vel += (k * (target - val) - d * vel) * dt;
        val += vel * dt;
    }

    void Update()
    {
        float dt = Mathf.Min(Time.deltaTime, 1f / 30);
        t += dt;
        // Drift along a smooth endless path, plus any behavior's bias.
        float target = Mathf.Clamp(Noise(t * 0.08f + seed) * wanderRange + biasX, -wanderRange * 1.3f, wanderRange * 1.3f);
        float oldX = x;
        Spring(ref x, ref vx, target, 14, 5.5f, dt);
        float speedX = (x - oldX) / Mathf.Max(dt, 1e-4f);
        // Hops with gravity; landing squashes.
        vy -= 2.6f * dt; y += vy * dt;
        if (y <= 0) { if (vy < -0.2f) sqV -= Mathf.Min(6, -vy * 7); y = 0; vy = 0; }
        float breath = Mathf.Sin(t * 1.7f) * 0.014f;
        Spring(ref sq, ref sqV, stretchTarget + Mathf.Clamp(vy * 0.3f, -0.08f, 0.1f) + breath, 140, 7, dt);
        float sway = Noise(t * 0.33f + seed + 9) * 3f;
        Spring(ref roll, ref rollV, -speedX * 40 + sway + extraRoll, 40, 6, dt);
        Spring(ref hairX, ref hairXV, -speedX * 0.25f, 30, 4, dt);

        body.localPosition = new Vector3(x, y, 0);
        body.localScale = new Vector3(1 / Mathf.Sqrt(Mathf.Max(0.6f, sq)), sq, 1);
        body.localRotation = Quaternion.Euler(0, 0, roll);

        look = Vector2.Lerp(look, lookTarget, 1 - Mathf.Exp(-dt * 10));
        face.localPosition = new Vector3(look.x * 0.05f, look.y * 0.03f, 0);
        for (int i = 0; i < tongues.Length; i++)
        {
            float outer = i == 2 ? 1f : 1.3f;
            float wave = Mathf.Sin(t * 2.6f + i * 1.37f) * 4f + Mathf.Sin(t * 6.1f + i * 2.1f) * 1.5f;
            tongues[i].localRotation = Quaternion.Euler(0, 0, tongueRest[i] + wave - hairX * 60 * outer);
            float s = 1 + Mathf.Sin(t * 3.7f + i) * 0.04f;
            tongues[i].localScale = new Vector3(1, s, 1);
        }
        if (!eyesHeld)
        {
            var mode = look.y > 0.45f ? 1 : look.y < -0.45f ? -1 : 0;
            if (mode == 1) SetEyes(eyeUp, eyeUp); else if (mode == -1) SetEyes(eyeDown, eyeDown);
        }
        if (Time.time < talkUntil)
        {
            float o = 0.5f + 0.5f * Mathf.Sin(t * 17) * Mathf.Sin(t * 6.3f);
            mouth.sprite = o > 0.7f ? mouthJoy : o > 0.4f ? mouthTalk : o > 0.15f ? mouthO : mouthSmile;
        }
    }

    void SetEyes(Sprite l, Sprite r) { eyeL.sprite = l; eyeR.sprite = r; }

    IEnumerator Blinking()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(2f, 5.5f));
            if (eyesHeld) continue;
            SetEyes(eyeClosedL, eyeClosedR);
            yield return new WaitForSeconds(0.12f);
            if (!eyesHeld) SetEyes(eyeOpenL, eyeOpenR);
        }
    }

    IEnumerator Idles()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(2.5f, 6f));
            switch (Random.Range(0, 6))
            {
                case 0: lookTarget = new Vector2(-0.8f, 0.1f); extraRoll = 5; yield return new WaitForSeconds(1.3f); break;
                case 1: lookTarget = new Vector2(0.8f, 0.1f); extraRoll = -5; yield return new WaitForSeconds(1.3f); break;
                case 2: lookTarget = new Vector2(0.2f, 0.8f); yield return new WaitForSeconds(1.2f); break;
                case 3: Hop(0.22f); break;
                case 4: biasX = Random.Range(-0.3f, 0.3f); yield return new WaitForSeconds(2.5f); biasX = 0; break;
                case 5: Talk(1.4f); break;
            }
            lookTarget = Vector2.zero; extraRoll = 0;
        }
    }

    public void Hop(float h) { if (y < 0.01f) { sqV -= 2.5f; vy = Mathf.Sqrt(2 * 2.6f * h); } }
    public void Talk(float s) { talkUntil = Time.time + s; StartCoroutine(After(s + 0.05f, () => mouth.sprite = mouthSmile)); SoundSynth.I?.Babble(4); }
    public void Look(Vector2? p) { lookTarget = p ?? Vector2.zero; biasX = (p?.x ?? 0) * 0.2f; }

    public void Giggle()
    {
        StartCoroutine(Squint(0.6f)); mouth.sprite = mouthJoy; Hop(0.15f);
        StartCoroutine(After(0.6f, () => mouth.sprite = mouthSmile));
        Haptics.Heartbeat(); SoundSynth.I?.Babble(2);
    }

    public void Cheer()
    {
        StartCoroutine(Squint(1f)); mouth.sprite = mouthJoy; Hop(0.45f);
        StartCoroutine(After(0.9f, () => mouth.sprite = mouthSmile));
    }

    IEnumerator Squint(float s)
    {
        eyesHeld = true; SetEyes(eyeClosedL, eyeClosedR);
        yield return new WaitForSeconds(s);
        eyesHeld = false; SetEyes(eyeOpenL, eyeOpenR);
    }

    IEnumerator After(float s, System.Action a) { yield return new WaitForSeconds(s); a(); }
}
