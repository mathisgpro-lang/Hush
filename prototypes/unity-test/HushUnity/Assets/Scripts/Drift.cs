// Slow drifting for clouds, birds and the like.
using UnityEngine;
public class Drift : MonoBehaviour
{
    public Vector3 velocity = new Vector3(0.3f, 0, 0); public float bob = 0; public float wrap = 0; Vector3 start; float seed;
    void Start() { start = transform.position; seed = Random.value * 10; }
    void Update()
    {
        var p = transform.position + velocity * Time.deltaTime;
        if (wrap > 0 && Mathf.Abs(p.x - start.x) > wrap) p.x = start.x - Mathf.Sign(p.x - start.x) * wrap;
        p.y = (bob > 0 ? start.y + Mathf.Sin(Time.time * 0.7f + seed) * bob : p.y);
        transform.position = p;
    }
}
