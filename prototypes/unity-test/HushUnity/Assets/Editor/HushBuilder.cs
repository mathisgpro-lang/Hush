// Builds the whole Unity test from code (no manual editor work): URP 2D setup, sprite import, the Sanctuary scene with
// depth layers, the living Flame as a real 2D light, the task object, the cinematic rise to the world map, and the iOS
// build. Run: Unity -batchmode -projectPath … -executeMethod HushBuilder.BuildAll -quit
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.EventSystems;
using Unity.Cinemachine;
using System.Linq;

public static class HushBuilder
{
    const float PPU = 100;
    const float CamDist = 18f;

    [MenuItem("Hush/Build All")]
    public static void BuildAll() { SetupPipeline(); ImportArt(); BuildScene(); }

    [MenuItem("Hush/Build iOS")]
    public static void BuildIOS()
    {
        BuildAll();
        // The native haptics plugin needs Apple's Core Haptics framework linked.
        var plugin = (PluginImporter)AssetImporter.GetAtPath("Assets/Plugins/iOS/HushHaptics.mm");
        plugin.SetCompatibleWithPlatform(BuildTarget.iOS, true);
        plugin.SetPlatformData(BuildTarget.iOS, "FrameworkDependencies", "CoreHaptics;");
        plugin.SaveAndReimport();
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.iOS, "com.mathis.lifegamified.unitytest");
        PlayerSettings.productName = "Hush Unity Test";
        PlayerSettings.companyName = "Mathis";
        PlayerSettings.iOS.appleDeveloperTeamID = "SX845VA92A";
        PlayerSettings.iOS.appleEnableAutomaticSigning = true;
        PlayerSettings.iOS.targetOSVersionString = "16.0";
        PlayerSettings.iOS.targetDevice = iOSTargetDevice.iPhoneOnly;
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
        PlayerSettings.statusBarHidden = true;
        var r = BuildPipeline.BuildPlayer(new BuildPlayerOptions
        {
            scenes = new[] { "Assets/Scenes/Sanctuary.unity" },
            locationPathName = "Builds/iOS-" + System.DateTime.Now.ToString("HHmm"),
            target = BuildTarget.iOS,
            options = BuildOptions.None
        });
        Debug.Log("HUSH BUILD RESULT: " + r.summary.result + " errors=" + r.summary.totalErrors);
    }

    // ---------- URP with the 2D renderer (2D lights) ----------
    static void SetupPipeline()
    {
        System.IO.Directory.CreateDirectory("Assets/Settings");
        var rd = AssetDatabase.LoadAssetAtPath<Renderer2DData>("Assets/Settings/Renderer2D.asset");
        if (rd == null) { rd = ScriptableObject.CreateInstance<Renderer2DData>(); AssetDatabase.CreateAsset(rd, "Assets/Settings/Renderer2D.asset"); }
        var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>("Assets/Settings/URP.asset");
        if (urp == null) { urp = UniversalRenderPipelineAsset.Create(rd); AssetDatabase.CreateAsset(urp, "Assets/Settings/URP.asset"); }
        GraphicsSettings.defaultRenderPipeline = urp;
        for (int i = 0; i < QualitySettings.names.Length; i++) { QualitySettings.SetQualityLevel(i, false); QualitySettings.renderPipeline = urp; }
        AssetDatabase.SaveAssets();
    }

    // ---------- Sprites ----------
    static void ImportArt()
    {
        foreach (var guid in AssetDatabase.FindAssets("t:Texture2D", new[] { "Assets/Art" }))
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var ti = (TextureImporter)AssetImporter.GetAtPath(path);
            ti.textureType = TextureImporterType.Sprite;
            ti.spriteImportMode = SpriteImportMode.Single;
            ti.spritePixelsPerUnit = PPU;
            ti.mipmapEnabled = path.Contains("/Map/") || path.Contains("/Sanctuary/");
            ti.alphaIsTransparency = true;
            ti.npotScale = TextureImporterNPOTScale.None;
            ti.maxTextureSize = 4096;
            ti.textureCompression = TextureImporterCompression.Uncompressed;
            var s = new TextureImporterSettings(); ti.ReadTextureSettings(s);
            s.spriteMeshType = SpriteMeshType.FullRect;
            s.spriteAlignment = (int)(path.Contains("lf-tongue") ? SpriteAlignment.BottomCenter : SpriteAlignment.Center);
            ti.SetTextureSettings(s);
            ti.SaveAndReimport();
        }
    }

    static Sprite S(string p) => AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/" + p);
    static Material Mat(string name) => AssetDatabase.LoadAssetAtPath<Material>(
        "Packages/com.unity.render-pipelines.universal/Runtime/Materials/" + name + ".mat");

    static Material Glow()
    {
        var path = "Assets/Settings/Glow.mat";
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m != null) return m;
        m = new Material(Shader.Find("Universal Render Pipeline/Particles/Unlit"));
        m.SetTexture("_BaseMap", S("FX/glow.png").texture);
        m.SetFloat("_Surface", 1); m.SetFloat("_Blend", 2);           // transparent, additive
        m.SetColor("_BaseColor", new Color(1f, 0.8f, 0.5f, 1));
        m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT"); m.EnableKeyword("_BLENDMODE_ADD");
        m.SetOverrideTag("RenderType", "Transparent");
        m.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha); m.SetInt("_DstBlend", (int)BlendMode.One); m.SetInt("_ZWrite", 0);
        m.renderQueue = 3000;
        AssetDatabase.CreateAsset(m, path);
        return m;
    }

    static GameObject Sprite(string name, Sprite sp, Transform parent, Vector3 pos, float scale, int order, Material mat)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localScale = Vector3.one * scale;
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = sp; r.sortingOrder = order; if (mat) r.sharedMaterial = mat;
        return go;
    }

    static Light2D Light(string name, Transform parent, Vector3 pos, Light2D.LightType type, Color c, float intensity, float radius)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false); go.transform.localPosition = pos;
        var l = go.AddComponent<Light2D>();
        l.lightType = type; l.color = c; l.intensity = intensity;
        if (type == Light2D.LightType.Point) { l.pointLightOuterRadius = radius; l.pointLightInnerRadius = radius * 0.08f; l.falloffIntensity = 0.65f; }
        // Light every sorting layer.
        var so = new SerializedObject(l);
        var arr = so.FindProperty("m_ApplyToSortingLayers");
        var ids = SortingLayer.layers.Select(x => x.id).ToArray();
        arr.arraySize = ids.Length; for (int i = 0; i < ids.Length; i++) arr.GetArrayElementAtIndex(i).intValue = ids[i];
        so.ApplyModifiedPropertiesWithoutUndo();
        return l;
    }

    static CinemachineCamera VCam(string name, Vector3 pos, Vector3 euler, float fov)
    {
        var go = new GameObject(name);
        go.transform.position = pos; go.transform.eulerAngles = euler;
        var c = go.AddComponent<CinemachineCamera>();
        var lens = c.Lens; lens.FieldOfView = fov; lens.NearClipPlane = 0.1f; lens.FarClipPlane = 200; c.Lens = lens;
        return c;
    }

    static Vector2 BodyPx(float x, float y) => new Vector2((x - 364.5f) / PPU, (1105 - y) / PPU);

    // ---------- The scene ----------
    static void BuildScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var lit = Mat("Sprite-Lit-Default"); var unlit = Mat("Sprite-Unlit-Default"); var glowMat = Glow();

        // Camera + Cinemachine brain.
        var camGo = new GameObject("Main Camera"); camGo.tag = "MainCamera";
        var cam = camGo.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor; cam.backgroundColor = new Color(0.05f, 0.03f, 0.06f);
        cam.orthographic = false; cam.fieldOfView = 54.3f; cam.transform.position = new Vector3(0, 0, -CamDist);
        var brain = camGo.AddComponent<CinemachineBrain>();
        brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.EaseInOut, 1.6f);

        // The dusk light over everything (slightly below 1, so the Flame's own light reads).
        var world = new GameObject("World").transform;
        Light("Global Dusk Light", world, Vector3.zero, Light2D.LightType.Global, new Color(1f, 0.95f, 0.9f), 0.92f, 0);

        // Home: the Sanctuary in depth layers. Each layer is scaled so it lines up exactly from the rest camera.
        var home = new GameObject("Home").transform; home.SetParent(world, false);
        float[] zs = { 0f, -0.7f, -1.4f, -2.4f };
        string[] names = { "L0-far", "L1-mid", "L2-circle", "L3-near" };
        int[] orders = { 0, 1, 2, 40 };
        for (int i = 0; i < 4; i++)
        {
            float k = (CamDist + zs[i]) / CamDist;
            Sprite("Sanctuary " + names[i], S($"Sanctuary/sanctuary-{names[i]}.png"), home, new Vector3(0, 0, zs[i]), k, orders[i], lit);
        }

        // The Flame on the stone circle, at the circle layer's depth.
        float circleZ = -1.45f, kc = (CamDist + circleZ) / CamDist;
        var circle = new Vector3(-0.04f * kc, 0.09f * 18.46f / 18.46f * kc, circleZ);
        var flameRoot = new GameObject("Flame").transform; flameRoot.SetParent(home, false);
        flameRoot.localPosition = circle + new Vector3(0, -0.05f, 0);
        flameRoot.localScale = Vector3.one * (1.7f / 11.05f) * kc;
        var body = new GameObject("Body (feet pivot)").transform; body.SetParent(flameRoot, false);
        var tongues = new Transform[5];
        float[] dxs = { -240, -130, 0, 130, 240 };
        for (int i = 0; i < 5; i++)
        {
            float dx = dxs[i], surfaceY = 290 - Mathf.Sqrt(300 * 300 - dx * dx);
            var sp = S($"Flame/lf-tongue-{i}.png");
            float hPx = sp.rect.height * 0.5f;
            var b = BodyPx(365 + dx, surfaceY) - new Vector2(0, hPx * 0.38f / PPU);
            var t = Sprite($"Tongue {i}", sp, body, new Vector3(b.x, b.y, 0), 0.5f, 10 + i, unlit).transform;
            t.localEulerAngles = new Vector3(0, 0, -dx / 240f * 16f);
            tongues[i] = t;
        }
        Sprite("Body", S("Flame/lf-body.png"), body, new Vector3(0, 11.05f / 2, 0), 1, 20, unlit);
        var face = new GameObject("Face").transform; face.SetParent(body, false);
        var eyeL = Sprite("Eye L", S("Flame/lf-eye-open-L.png"), face, BodyPx(228, 352), 0.75f, 30, unlit).GetComponent<SpriteRenderer>();
        var eyeR = Sprite("Eye R", S("Flame/lf-eye-open-R.png"), face, BodyPx(502, 352), 0.75f, 30, unlit).GetComponent<SpriteRenderer>();
        Sprite("Brow L", S("Flame/lf-brow-L.png"), face, BodyPx(222, 255), 0.575f, 31, unlit);
        Sprite("Brow R", S("Flame/lf-brow-R.png"), face, BodyPx(508, 255), 0.575f, 31, unlit);
        var mouth = Sprite("Mouth", S("Flame/lf-mouth-smile.png"), face, BodyPx(365, 432), 0.6f, 32, unlit).GetComponent<SpriteRenderer>();

        var rig = flameRoot.gameObject.AddComponent<FlameRig>();
        rig.body = body; rig.face = face; rig.tongues = tongues; rig.eyeL = eyeL; rig.eyeR = eyeR; rig.mouth = mouth;
        rig.eyeOpenL = S("Flame/lf-eye-open-L.png"); rig.eyeOpenR = S("Flame/lf-eye-open-R.png");
        rig.eyeClosedL = S("Flame/lf-eye-closed-L.png"); rig.eyeClosedR = S("Flame/lf-eye-closed-R.png");
        rig.eyeUp = S("Flame/lf-eye-up.png"); rig.eyeDown = S("Flame/lf-eye-down.png");
        rig.mouthSmile = S("Flame/lf-mouth-smile.png"); rig.mouthJoy = S("Flame/lf-mouth-joy.png"); rig.mouthO = S("Flame/lf-mouth-o.png");
        rig.mouthTalk = S("Flame/lf-mouth-talk.png"); rig.mouthFlat = S("Flame/lf-mouth-flat.png");
        rig.wanderRange = 2.2f;

        // The Flame as a real light: a wide warm glow on the world + a tighter core at its feet.
        var fl = flameRoot.gameObject.AddComponent<FlameLight>();
        fl.glow = Light("Flame Light", body, new Vector3(0, 5.5f, 0), Light2D.LightType.Point, new Color(1f, 0.62f, 0.28f), 1.1f, 3.2f);
        fl.glow.transform.localScale = Vector3.one;
        fl.glow.pointLightOuterRadius = 3.2f / flameRoot.localScale.x * 0 + 3.2f;
        fl.core = Light("Flame Core Light", body, new Vector3(0, 0.5f, 0), Light2D.LightType.Point, new Color(1f, 0.75f, 0.4f), 1.0f, 1.2f);
        // Light2D radii are in world units regardless of parent scale.

        // Embers rising from the Flame.
        var embersGo = new GameObject("Embers"); embersGo.transform.SetParent(body, false); embersGo.transform.localPosition = new Vector3(0, 9, 0);
        var ps = embersGo.AddComponent<ParticleSystem>();
        var main = ps.main; main.startLifetime = 2.2f; main.startSpeed = 0.35f; main.startSize = 0.06f; main.maxParticles = 60;
        main.startColor = new Color(1f, 0.72f, 0.3f); main.simulationSpace = ParticleSystemSimulationSpace.World; main.gravityModifier = -0.02f;
        var em = ps.emission; em.rateOverTime = 9;
        var shape = ps.shape; shape.shapeType = ParticleSystemShapeType.Sphere; shape.radius = 2.5f;
        var col = ps.colorOverLifetime; col.enabled = true;
        var grad = new Gradient(); grad.SetKeys(new[] { new GradientColorKey(new Color(1, 0.8f, 0.4f), 0), new GradientColorKey(new Color(1, 0.4f, 0.1f), 1) },
            new[] { new GradientAlphaKey(0, 0), new GradientAlphaKey(1, 0.15f), new GradientAlphaKey(0, 1) });
        col.color = grad;
        var psr = embersGo.GetComponent<ParticleSystemRenderer>(); psr.sharedMaterial = glowMat; psr.sortingOrder = 35;

        // The task object: a candle bowl at the circle's front edge (placeholder art until the style-matched objects exist).
        var bowl = Sprite("Task: candle bowl", S("FX/bowl.png"), home, new Vector3(circle.x + 1.25f, circle.y - 0.9f, circleZ), 0.42f * kc, 25, lit);
        var bowlGlow = Sprite("Glow", S("FX/glow.png"), bowl.transform, new Vector3(0, 0.2f, 0), 1.2f, 24, glowMat).GetComponent<SpriteRenderer>();
        var orb = Sprite("Light orb", S("FX/glow.png"), home, Vector3.zero, 0.6f, 45, glowMat);
        Light("Orb Light", orb.transform, Vector3.zero, Light2D.LightType.Point, new Color(1f, 0.8f, 0.45f), 1.4f, 1.6f);
        var burstGo = new GameObject("Burst"); burstGo.transform.SetParent(bowl.transform, false); burstGo.transform.localPosition = new Vector3(0, 0.5f, 0);
        var burst = burstGo.AddComponent<ParticleSystem>();
        var bm = burst.main; bm.startLifetime = 0.9f; bm.startSpeed = 2.2f; bm.startSize = 0.12f; bm.loop = false; bm.playOnAwake = false;
        bm.startColor = new Color(1f, 0.82f, 0.45f); bm.duration = 0.2f; bm.gravityModifier = 0.4f;
        var be = burst.emission; be.rateOverTime = 0; be.SetBursts(new[] { new ParticleSystem.Burst(0, 40) });
        var bshape = burst.shape; bshape.shapeType = ParticleSystemShapeType.Circle; bshape.radius = 0.2f;
        var bpsr = burstGo.GetComponent<ParticleSystemRenderer>(); bpsr.sharedMaterial = glowMat; bpsr.sortingOrder = 46;
        var hold = bowl.AddComponent<HoldToGive>();
        hold.art = bowl.GetComponent<SpriteRenderer>(); hold.glow = bowlGlow; hold.flame = rig; hold.flameLight = fl;
        hold.flameChest = fl.glow.transform; hold.orb = orb.transform; hold.burst = burst;

        // The world map, out of view until the rise.
        var map = new GameObject("Map").transform; map.SetParent(world, false); map.localPosition = new Vector3(200, 0, 0);
        Sprite("World map", S("Map/world-map.png"), map, Vector3.zero, 1, 0, lit);
        var island = new Vector3(200 + (400 - 401.5f) / PPU, (979 - 1555) / PPU, 0);

        // Cinemachine cameras: home, high over home, close on the map's Sanctuary island, the whole map.
        var homeCam = VCam("Cam Home", new Vector3(0, 0, -CamDist), Vector3.zero, 54.3f);
        var homeHigh = VCam("Cam Home High", new Vector3(0, 5.5f, -27f), new Vector3(10, 0, 0), 58f);
        var mapClose = VCam("Cam Map Close", island + new Vector3(0, -0.6f, -5f), new Vector3(-6, 0, 0), 50f);
        var mapWide = VCam("Cam Map Wide", new Vector3(200, -1.5f, -19.8f), Vector3.zero, 56f);

        // UI: the World / Home buttons and the cloud mask.
        var canvasGo = new GameObject("UI", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        var canvas = canvasGo.GetComponent<Canvas>(); canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        var scaler = canvasGo.GetComponent<CanvasScaler>(); scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize; scaler.referenceResolution = new Vector2(1179, 2556); scaler.matchWidthOrHeight = 0.5f;
        new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        var cloudsGo = new GameObject("Clouds", typeof(RectTransform), typeof(CanvasGroup)); cloudsGo.transform.SetParent(canvasGo.transform, false);
        var crt = (RectTransform)cloudsGo.transform; crt.anchorMin = Vector2.zero; crt.anchorMax = Vector2.one; crt.offsetMin = crt.offsetMax = Vector2.zero;
        var cg = cloudsGo.GetComponent<CanvasGroup>(); cg.blocksRaycasts = false;
        var pieces = new RectTransform[6];
        for (int i = 0; i < 6; i++)
        {
            var p = new GameObject("Cloud " + i, typeof(RectTransform), typeof(Image)); p.transform.SetParent(cloudsGo.transform, false);
            var img = p.GetComponent<Image>(); img.sprite = S("FX/cloud.png"); img.raycastTarget = false; img.color = new Color(1, 0.97f, 0.94f, 0.95f);
            var r = (RectTransform)p.transform; r.sizeDelta = new Vector2(2200, 2200);
            r.anchoredPosition = new Vector2((i % 3 - 1) * 500, (i / 3 - 0.5f) * 1100);
            pieces[i] = r;
        }
        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        Button MakeButton(string label, Vector2 pos)
        {
            var bgo = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button)); bgo.transform.SetParent(canvasGo.transform, false);
            var r = (RectTransform)bgo.transform; r.anchorMin = r.anchorMax = new Vector2(0.5f, 0); r.sizeDelta = new Vector2(420, 120); r.anchoredPosition = pos;
            bgo.GetComponent<Image>().color = new Color(0.08f, 0.06f, 0.05f, 0.78f);
            var tgo = new GameObject("Text", typeof(RectTransform), typeof(Text)); tgo.transform.SetParent(bgo.transform, false);
            var tr = (RectTransform)tgo.transform; tr.anchorMin = Vector2.zero; tr.anchorMax = Vector2.one; tr.offsetMin = tr.offsetMax = Vector2.zero;
            var tx = tgo.GetComponent<Text>(); tx.text = label; tx.font = font; tx.fontSize = 48; tx.alignment = TextAnchor.MiddleCenter; tx.color = new Color(1f, 0.88f, 0.7f);
            return bgo.GetComponent<Button>();
        }
        var worldBtn = MakeButton("The World", new Vector2(0, 170));
        var homeBtn = MakeButton("Home", new Vector2(0, 170));

        var rise = new GameObject("World Rise").AddComponent<WorldRise>();
        rise.homeCam = homeCam; rise.homeHighCam = homeHigh; rise.mapCloseCam = mapClose; rise.mapWideCam = mapWide;
        rise.clouds = cg; rise.cloudPieces = pieces; rise.homeWorld = home.gameObject; rise.mapWorld = map.gameObject;
        rise.worldButton = worldBtn; rise.homeButton = homeBtn; rise.flame = rig;

        new GameObject("Sound").AddComponent<SoundSynth>();
        var dir = new GameObject("Home Director").AddComponent<HomeDirector>();
        dir.flame = rig; dir.flameHit = fl.glow.transform; dir.homeCam = homeCam;

        System.IO.Directory.CreateDirectory("Assets/Scenes");
        EditorSceneManager.SaveScene(scene, "Assets/Scenes/Sanctuary.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/Sanctuary.unity", true) };
        AssetDatabase.SaveAssets();
        Debug.Log("HUSH SCENE BUILT");
    }

    // A screenshot from the home camera in batch mode, to check the scene without a device.
    [MenuItem("Hush/Snapshot")]
    public static void Snapshot()
    {
        EditorSceneManager.OpenScene("Assets/Scenes/Sanctuary.unity");
        var cam = Camera.main;
        var rt = new RenderTexture(1179 / 2, 2556 / 2, 24);
        cam.targetTexture = rt; cam.Render();
        RenderTexture.active = rt;
        var tex = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0); tex.Apply();
        System.IO.File.WriteAllBytes("Builds/snapshot.png", tex.EncodeToPNG());
        cam.targetTexture = null;
        Debug.Log("HUSH SNAPSHOT SAVED");
    }
}
