// Small glue for the test scene: tap the Flame → it giggles; a gentle camera breath (parallax across the depth layers).
using UnityEngine;
using Unity.Cinemachine;

public class HomeDirector : MonoBehaviour
{
    public FlameRig flame;
    public Transform flameHit;
    public CinemachineCamera homeCam;
    Vector3 camBase;

    void Start() { camBase = homeCam.transform.position; Application.targetFrameRate = 60; }

    void Update()
    {
        float t = Time.time;
        homeCam.transform.position = camBase + new Vector3(Mathf.PerlinNoise(t * 0.09f, 1) - 0.5f, (Mathf.PerlinNoise(t * 0.07f, 5) - 0.5f) * 0.6f, 0) * 0.9f;
        if (Input.GetMouseButtonDown(0))
        {
            var cam = Camera.main;
            var w = cam.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, Mathf.Abs(cam.transform.position.z - flameHit.position.z)));
            if (Vector2.Distance(w, flameHit.position) < 0.9f) flame.Giggle();
        }
    }
}
