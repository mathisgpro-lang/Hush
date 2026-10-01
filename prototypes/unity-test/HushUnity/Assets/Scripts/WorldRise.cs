// The cinematic rise (P2.5 spec B.1 step 7 / §6): from home, the camera rises and pulls back, clouds sweep past,
// and behind them the world map takes over: we arrive close on the Sanctuary's island and pull out to the Emberlands.
// The reverse dives back home. Cinemachine cameras with priority blends; clouds are a full-screen mask.
using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using Unity.Cinemachine;

public class WorldRise : MonoBehaviour
{
    public CinemachineCamera homeCam, homeHighCam, mapCloseCam, mapWideCam;
    public CanvasGroup clouds;
    public RectTransform[] cloudPieces;
    public GameObject homeWorld, mapWorld;
    public Button worldButton, homeButton;
    public FlameRig flame;
    bool busy, onMap;

    void Start()
    {
        worldButton.onClick.AddListener(() => { if (!busy && !onMap) StartCoroutine(Rise()); });
        homeButton.onClick.AddListener(() => { if (!busy && onMap) StartCoroutine(Dive()); });
        homeButton.gameObject.SetActive(false);
        clouds.alpha = 0;
        mapWorld.SetActive(false);
        Set(homeCam);
    }

    void Set(CinemachineCamera c)
    {
        foreach (var x in new[] { homeCam, homeHighCam, mapCloseCam, mapWideCam }) x.Priority = x == c ? 10 : 0;
    }

    void Update()
    {
        // Pinch out at home = rise; pinch in on the map = dive.
        if (Input.touchCount == 2 && !busy)
        {
            var a = Input.GetTouch(0); var b = Input.GetTouch(1);
            float prev = Vector2.Distance(a.position - a.deltaPosition, b.position - b.deltaPosition), now = Vector2.Distance(a.position, b.position);
            if (!onMap && now < prev - 12) StartCoroutine(Rise());
            if (onMap && now > prev + 12) StartCoroutine(Dive());
        }
    }

    IEnumerator Clouds(float from, float to, float seconds, float drift)
    {
        for (float t = 0; t < 1; t += Time.deltaTime / seconds)
        {
            float e = t * t * (3 - 2 * t);
            clouds.alpha = Mathf.Lerp(from, to, e);
            for (int i = 0; i < cloudPieces.Length; i++)
                cloudPieces[i].anchoredPosition += new Vector2((i % 2 == 0 ? 1 : -1) * 60, -drift * (1 + i * 0.3f)) * Time.deltaTime;
            yield return null;
        }
        clouds.alpha = to;
    }

    IEnumerator Rise()
    {
        busy = true; worldButton.gameObject.SetActive(false);
        Haptics.Rise(); SoundSynth.I?.Rise();
        flame.Look(new Vector2(0, 0.9f));
        Set(homeHighCam);                                   // up and back over the Sanctuary
        yield return new WaitForSeconds(0.9f);
        yield return Clouds(0, 1, 0.6f, 400);               // clouds sweep in
        homeWorld.SetActive(false); mapWorld.SetActive(true);
        var brain = Camera.main.GetComponent<CinemachineBrain>();
        var keep = brain.DefaultBlend; brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.Cut, 0);
        Set(mapCloseCam); yield return null;               // behind the clouds: close on the Sanctuary's island
        brain.DefaultBlend = keep;
        Set(mapWideCam);                                    // and pull out to the whole Emberlands
        yield return Clouds(1, 0, 0.9f, 300);
        yield return new WaitForSeconds(1.2f);
        Haptics.Arrive();
        onMap = true; busy = false; homeButton.gameObject.SetActive(true);
    }

    IEnumerator Dive()
    {
        busy = true; homeButton.gameObject.SetActive(false);
        Haptics.Rise(); SoundSynth.I?.Rise();
        Set(mapCloseCam);                                   // dive toward the Sanctuary's island
        yield return new WaitForSeconds(1.0f);
        yield return Clouds(0, 1, 0.5f, -400);
        mapWorld.SetActive(false); homeWorld.SetActive(true);
        var brain = Camera.main.GetComponent<CinemachineBrain>();
        var keep = brain.DefaultBlend; brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.Cut, 0);
        Set(homeHighCam); yield return null;
        brain.DefaultBlend = keep;
        Set(homeCam);
        yield return Clouds(1, 0, 0.9f, -300);
        yield return new WaitForSeconds(0.9f);
        Haptics.Arrive(); flame.Look(null); flame.Giggle();
        onMap = false; busy = false; worldButton.gameObject.SetActive(true);
    }
}
