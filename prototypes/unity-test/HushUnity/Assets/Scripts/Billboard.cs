// Keeps a 2D-painted thing (the Flame, cloud banks) facing the camera around the vertical axis.
using UnityEngine;
public class Billboard : MonoBehaviour
{
    public bool fullFacing;
    void LateUpdate()
    {
        var cam = Camera.main; if (!cam) return;
        var d = transform.position - cam.transform.position;
        if (!fullFacing) d.y = 0;
        if (d.sqrMagnitude > 1e-4f) transform.rotation = Quaternion.LookRotation(d);
    }
}
