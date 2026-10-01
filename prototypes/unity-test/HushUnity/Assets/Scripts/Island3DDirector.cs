// The 3D Sanctuary's camera and touch: at home the camera drifts slowly around the circle (never still); tap the
// Flame → it giggles; "The World" → the camera rises above the island, through a cloud layer, until the Sanctuary is a
// small island in a vast misty sea with the realms glowing far away; "Home" → it dives back.
using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using Unity.Cinemachine;

public class Island3DDirector : MonoBehaviour
{
    public CinemachineCamera homeCam, riseCam, worldCam;
    public Transform focus;                      // the circle's center
    public FlameRig flame;
    public Collider flameHit;
    public CanvasGroup clouds; public RectTransform[] cloudPieces;
    public Button worldButton, homeButton;
    public float orbitRadius = 13f, orbitHeight = 8.2f;
    bool busy, onWorld; float angle = 200;

    void Start()
    {
        Application.targetFrameRate = 60;
        worldButton.onClick.AddListener(() => { if (!busy && !onWorld) StartCoroutine(Rise()); });
        homeButton.onClick.AddListener(() => { if (!busy && onWorld) StartCoroutine(Dive()); });
        homeButton.gameObject.SetActive(false); clouds.alpha = 0;
        Set(homeCam);
    }

    void Set(CinemachineCamera c) { foreach (var x in new[] { homeCam, riseCam, worldCam }) x.Priority = x == c ? 10 : 0; }

    void Update()
    {
        // The haze thins as the camera rises, so the far realms show from high up (and stay soft at home).
        float alt = Mathf.InverseLerp(9, 90, Camera.main.transform.position.y);
        RenderSettings.fogStartDistance = Mathf.Lerp(40, 140, alt);
        RenderSettings.fogEndDistance = Mathf.Lerp(420, 1100, alt);
        // The home camera drifts slowly around the circle, breathing up and down.
        float t = Time.time;
        float a = (angle + Mathf.Sin(t * 0.05f) * 14) * Mathf.Deg2Rad;
        var pos = focus.position + new Vector3(Mathf.Sin(a) * orbitRadius, orbitHeight + Mathf.Sin(t * 0.13f) * 0.35f, Mathf.Cos(a) * orbitRadius);
        homeCam.transform.position = pos;
        homeCam.transform.rotation = Quaternion.LookRotation(focus.position + Vector3.up * 0.6f - pos);

        if (Input.GetMouseButtonDown(0) && !busy && !onWorld && flameHit.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out _, 100))
            flame.Giggle();
        if (Input.touchCount == 2 && !busy)
        {
            var p = Input.GetTouch(0); var q = Input.GetTouch(1);
            float prev = Vector2.Distance(p.position - p.deltaPosition, q.position - q.deltaPosition), now = Vector2.Distance(p.position, q.position);
            if (!onWorld && now < prev - 12) StartCoroutine(Rise());
            if (onWorld && now > prev + 12) StartCoroutine(Dive());
        }
    }

    IEnumerator Clouds(float from, float to, float seconds, float drift)
    {
        for (float t = 0; t < 1; t += Time.deltaTime / seconds)
        {
            float e = t * t * (3 - 2 * t); clouds.alpha = Mathf.Lerp(from, to, e);
            for (int i = 0; i < cloudPieces.Length; i++) cloudPieces[i].anchoredPosition += new Vector2((i % 2 == 0 ? 1 : -1) * 50, -drift * (1 + i * 0.3f)) * Time.deltaTime;
            yield return null;
        }
        clouds.alpha = to;
    }

    IEnumerator Rise()
    {
        busy = true; worldButton.gameObject.SetActive(false);
        Haptics.Rise(); SoundSynth.I?.Rise(); flame.Look(new Vector2(0, 0.9f));
        var brain = Camera.main.GetComponent<CinemachineBrain>();
        brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.EaseInOut, 2.2f);
        Set(riseCam);                                   // lift above the island
        yield return new WaitForSeconds(1.4f);
        StartCoroutine(Clouds(0, 0.85f, 0.7f, 380));     // through the cloud layer
        yield return new WaitForSeconds(0.7f);
        brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.EaseInOut, 2.6f);
        Set(worldCam);                                  // high above the sea: the Emberlands
        yield return Clouds(0.85f, 0, 1.2f, 300);
        yield return new WaitForSeconds(1.2f);
        Haptics.Arrive(); onWorld = true; busy = false; homeButton.gameObject.SetActive(true);
    }

    IEnumerator Dive()
    {
        busy = true; homeButton.gameObject.SetActive(false);
        Haptics.Rise(); SoundSynth.I?.Rise();
        var brain = Camera.main.GetComponent<CinemachineBrain>();
        brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.EaseInOut, 2.2f);
        Set(riseCam);
        StartCoroutine(Clouds(0, 0.8f, 0.8f, -380));
        yield return new WaitForSeconds(1.0f);
        StartCoroutine(Clouds(0.8f, 0, 1.0f, -300));
        brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.EaseInOut, 2.0f);
        Set(homeCam);
        yield return new WaitForSeconds(2.2f);
        Haptics.Arrive(); flame.Look(null); flame.Giggle();
        onWorld = false; busy = false; worldButton.gameObject.SetActive(true);
    }
}
