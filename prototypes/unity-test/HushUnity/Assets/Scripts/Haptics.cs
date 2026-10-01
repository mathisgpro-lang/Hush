// The haptic language on iOS through a tiny native Core Haptics plugin (Plugins/iOS/HushHaptics.mm).
// Silent in the editor and on devices without haptics.
using System.Runtime.InteropServices;

public static class Haptics
{
#if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")] static extern void HushHapticsTap(float intensity, float sharpness);
    [DllImport("__Internal")] static extern void HushHapticsCharge(float seconds);
    [DllImport("__Internal")] static extern void HushHapticsStop();
    [DllImport("__Internal")] static extern void HushHapticsIgnite();
    [DllImport("__Internal")] static extern void HushHapticsRise();
#else
    static void HushHapticsTap(float i, float s) { }
    static void HushHapticsCharge(float s) { }
    static void HushHapticsStop() { }
    static void HushHapticsIgnite() { }
    static void HushHapticsRise() { }
#endif
    public static void Heartbeat() { HushHapticsTap(0.4f, 0.2f); }
    public static void Nudge() { HushHapticsTap(0.25f, 0.3f); }
    public static void Catch() { HushHapticsTap(0.6f, 0.3f); }
    public static void Arrive() { HushHapticsTap(0.7f, 0.1f); }
    public static void StartCharge(float seconds) { HushHapticsCharge(seconds); }
    public static void StopCharge() { HushHapticsStop(); }
    public static void Ignite() { HushHapticsIgnite(); }
    public static void Rise() { HushHapticsRise(); }
}
