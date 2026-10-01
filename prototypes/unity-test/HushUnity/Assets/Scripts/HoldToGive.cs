// A task object on the circle (P2.5 spec A.5): tap to open, hold ~1 s to give light. While holding, light flows from
// the finger into it (glow + rising haptic + tone); at full charge it ignites, the light arcs to your Flame, the Flame
// flares its real light and cheers, and the object fades to a glowing rune.
using UnityEngine;
using System.Collections;

public class HoldToGive : MonoBehaviour
{
    public SpriteRenderer art, glow;
    public FlameRig flame;
    public MonoBehaviour flameLight;    // FlameLight (2D) or FlameLight3D: anything with a Flare() method
    public Transform flameChest;
    public Transform orb;               // the flying light
    public ParticleSystem burst;
    public System.Action onCompleted;
    public float holdSeconds = 1.0f;

    float charge; bool holding, done;
    Vector3 baseScale;

    void Start() { baseScale = transform.localScale; orb.gameObject.SetActive(false); }

    void Update()
    {
        if (done) return;
        bool down = Input.GetMouseButton(0);
        if (Input.GetMouseButtonDown(0) && HitMe()) BeginHold();
        if (holding && !down) CancelHold();
        if (holding)
        {
            charge += Time.deltaTime / holdSeconds;
            if (charge >= 1) StartCoroutine(Ignite());
        }
        else charge = Mathf.MoveTowards(charge, 0, Time.deltaTime * 2);
        float breath = 1 + Mathf.Sin(Time.time * 2.2f) * 0.02f;
        transform.localScale = baseScale * (breath + charge * 0.12f);
        var c = glow.color; c.a = 0.25f + 0.25f * Mathf.Sin(Time.time * 2.2f) * 0.5f + charge * 0.75f; glow.color = c;
        glow.transform.localScale = Vector3.one * (1.2f + charge * 0.8f);
    }

    bool HitMe()
    {
        var col = GetComponent<Collider>();
        if (col != null) return col.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out _, 200f);
        var w = Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, Mathf.Abs(Camera.main.transform.position.z - transform.position.z)));
        return Vector2.Distance(w, transform.position) < 0.55f * transform.lossyScale.x * 2.2f;
    }

    void BeginHold()
    {
        holding = true; charge = 0;
        Haptics.StartCharge(holdSeconds); SoundSynth.I?.StartCharge(holdSeconds);
        flame.Look(new Vector2(0.4f, -0.6f));
    }

    void CancelHold()
    {
        holding = false;
        Haptics.StopCharge(); SoundSynth.I?.StopCharge();
        flame.Look(null);
    }

    IEnumerator Ignite()
    {
        holding = false; done = true;
        Haptics.StopCharge(); SoundSynth.I?.StopCharge();
        Haptics.Ignite(); SoundSynth.I?.Ignite();
        burst.Play();
        // The light arcs from the object to your Flame.
        orb.gameObject.SetActive(true);
        Vector3 a = transform.position + Vector3.up * 0.2f, b = flameChest.position;
        SoundSynth.I?.Sweep();
        for (float t = 0; t < 1; t += Time.deltaTime / 0.9f)
        {
            float e = t * t * (3 - 2 * t);
            orb.position = Vector3.Lerp(a, b, e) + Vector3.up * Mathf.Sin(t * Mathf.PI) * 1.2f;
            orb.localScale = Vector3.one * (0.6f + Mathf.Sin(t * Mathf.PI) * 0.4f);
            art.color = new Color(1, 1, 1, 1 - t * 0.85f);
            yield return null;
        }
        orb.gameObject.SetActive(false);
        Haptics.Catch(); SoundSynth.I?.Catch();
        flameLight.SendMessage("Flare", SendMessageOptions.DontRequireReceiver); flame.Cheer();
        onCompleted?.Invoke();
        // Leave a small glowing rune.
        for (float t = 0; t < 1; t += Time.deltaTime / 0.6f) { transform.localScale = Vector3.Lerp(baseScale, baseScale * 0.35f, t); yield return null; }
    }
}
