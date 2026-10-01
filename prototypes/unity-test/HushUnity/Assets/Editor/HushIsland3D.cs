// Builds the 3D Sanctuary island from code (3D world plan, step 1): a URP 3D pipeline with post-processing, procedural
// cliffs and ruins, the stone circle with glowing runes, braziers, trees, waterfalls, an ocean, distant realm islands in
// the haze, clouds, the dusk sun and fog, your Flame (Codex's parts) as a real light, the task bowl, and the camera rig.
// Run: Unity -batchmode -projectPath … -executeMethod HushIsland3D.Build -quit   (BuildIOS for the phone)
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.EventSystems;
using Unity.Cinemachine;
using System.Collections.Generic;

public static class HushIsland3D
{
    const string Gen = "Assets/Generated";
    static readonly Vector3 SunDir = new Vector3(-0.85f, 0.22f, 0.45f).normalized;  // low, off to the left of the home view: warm side light, long shadows
    static int meshCount;

    [MenuItem("Hush/Build 3D Island")]
    public static void Build() { Pipeline(); BuildScene(); }

    [MenuItem("Hush/Build 3D Island iOS")]
    public static void BuildIOS()
    {
        Build();
        var plugin = (PluginImporter)AssetImporter.GetAtPath("Assets/Plugins/iOS/HushHaptics.mm");
        plugin.SetCompatibleWithPlatform(BuildTarget.iOS, true);
        plugin.SetPlatformData(BuildTarget.iOS, "FrameworkDependencies", "CoreHaptics;");
        plugin.SaveAndReimport();
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.iOS, "com.mathis.lifegamified.unitytest");
        PlayerSettings.productName = "Hush 3D";
        PlayerSettings.iOS.appleDeveloperTeamID = "SX845VA92A";
        PlayerSettings.iOS.appleEnableAutomaticSigning = true;
        PlayerSettings.iOS.targetOSVersionString = "16.0";
        PlayerSettings.iOS.targetDevice = iOSTargetDevice.iPhoneOnly;
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
        PlayerSettings.statusBarHidden = true;
        var r = BuildPipeline.BuildPlayer(new BuildPlayerOptions
        {
            scenes = new[] { "Assets/Scenes/Island3D.unity" },
            locationPathName = "Builds/iOS3D-" + System.DateTime.Now.ToString("HHmm"),
            target = BuildTarget.iOS
        });
        Debug.Log("HUSH 3D BUILD RESULT: " + r.summary.result + " errors=" + r.summary.totalErrors + " path=" + r.summary.outputPath);
    }

    // ---------- URP 3D with post-processing and the depth texture (ocean foam) ----------
    static void Pipeline()
    {
        System.IO.Directory.CreateDirectory("Assets/Settings");
        var rd = AssetDatabase.LoadAssetAtPath<UniversalRendererData>("Assets/Settings/Renderer3D.asset");
        if (rd == null)
        {
            rd = ScriptableObject.CreateInstance<UniversalRendererData>();
            rd.postProcessData = AssetDatabase.LoadAssetAtPath<PostProcessData>("Packages/com.unity.render-pipelines.universal/Runtime/Data/PostProcessData.asset");
            AssetDatabase.CreateAsset(rd, "Assets/Settings/Renderer3D.asset");
        }
        var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>("Assets/Settings/URP3D.asset");
        if (urp == null) { urp = UniversalRenderPipelineAsset.Create(rd); AssetDatabase.CreateAsset(urp, "Assets/Settings/URP3D.asset"); }
        urp.supportsCameraDepthTexture = true;
        urp.supportsHDR = true;
        urp.msaaSampleCount = 2;
        urp.shadowDistance = 45;
        urp.renderScale = 1;
        EditorUtility.SetDirty(urp);
        GraphicsSettings.defaultRenderPipeline = urp;
        for (int i = 0; i < QualitySettings.names.Length; i++) { QualitySettings.SetQualityLevel(i, false); QualitySettings.renderPipeline = urp; }
        AssetDatabase.SaveAssets();
    }

    // ---------- Helpers ----------
    static Material Lit(string name, Color c, float smooth = 0.15f, Color? emission = null, Texture emissionMap = null)
    {
        var path = $"{Gen}/M_{name}.mat";
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m == null) { m = new Material(Shader.Find("Universal Render Pipeline/Lit")); AssetDatabase.CreateAsset(m, path); }
        m.SetColor("_BaseColor", c); m.SetFloat("_Smoothness", smooth); m.SetFloat("_Metallic", 0);
        if (emission.HasValue)
        {
            m.EnableKeyword("_EMISSION"); m.SetColor("_EmissionColor", emission.Value);
            if (emissionMap) m.SetTexture("_EmissionMap", emissionMap);
            m.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
        }
        EditorUtility.SetDirty(m);
        return m;
    }

    static Material ShaderMat(string name, string shader, System.Action<Material> setup = null)
    {
        var path = $"{Gen}/M_{name}.mat";
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m == null) { m = new Material(Shader.Find(shader)); AssetDatabase.CreateAsset(m, path); }
        m.shader = Shader.Find(shader);
        setup?.Invoke(m); EditorUtility.SetDirty(m);
        return m;
    }

    static Mesh SaveMesh(Mesh m)
    {
        m.RecalculateNormals(); m.RecalculateBounds();
        AssetDatabase.CreateAsset(m, $"{Gen}/mesh_{meshCount++}.asset");
        return m;
    }

    static GameObject MeshObject(string name, Mesh mesh, Transform parent, params Material[] mats)
    {
        var go = new GameObject(name); go.transform.SetParent(parent, false);
        go.AddComponent<MeshFilter>().sharedMesh = mesh;
        var r = go.AddComponent<MeshRenderer>(); r.sharedMaterials = mats;
        return go;
    }

    static GameObject Prim(PrimitiveType t, string name, Transform parent, Vector3 pos, Vector3 scale, Material m, Vector3? euler = null)
    {
        var go = GameObject.CreatePrimitive(t); go.name = name;
        Object.DestroyImmediate(go.GetComponent<Collider>());
        go.transform.SetParent(parent, false); go.transform.localPosition = pos; go.transform.localScale = scale;
        if (euler.HasValue) go.transform.localEulerAngles = euler.Value;
        go.GetComponent<MeshRenderer>().sharedMaterial = m;
        return go;
    }

    static float N(float x, float y) => Mathf.PerlinNoise(x, y) * 2 - 1;

    /// A rocky island: a gently rolling top at y = 0 and cliffs falling to `depth`, with irregular edges.
    static Mesh IslandMesh(float radius, float depth, float seed, float topBump = 0.25f, float flatCenter = 0.4f)
    {
        int seg = 96, rings = 10, rows = 14;
        var v = new List<Vector3>(); var tri0 = new List<int>(); var tri1 = new List<int>();
        float Edge(float a) => radius * (1 + 0.16f * N(Mathf.Cos(a) * 1.3f + seed, Mathf.Sin(a) * 1.3f + seed) + 0.06f * N(Mathf.Cos(a) * 4 + seed * 2, Mathf.Sin(a) * 4));
        v.Add(Vector3.zero);
        for (int r = 1; r <= rings; r++)
            for (int s = 0; s < seg; s++)
            {
                float a = s * Mathf.PI * 2 / seg, f = (float)r / rings, e = Edge(a) * f;
                float x = Mathf.Sin(a) * e, z = Mathf.Cos(a) * e;
                float h = f < flatCenter ? 0 : topBump * N(x * 0.25f + seed, z * 0.25f) * (f - flatCenter) - 0.25f * Mathf.Pow(f, 6);
                v.Add(new Vector3(x, h, z));
            }
        for (int s = 0; s < seg; s++) { tri0.Add(0); tri0.Add(1 + s); tri0.Add(1 + (s + 1) % seg); }
        for (int r = 1; r < rings; r++)
            for (int s = 0; s < seg; s++)
            {
                int a0 = 1 + (r - 1) * seg + s, a1 = 1 + (r - 1) * seg + (s + 1) % seg, b0 = a0 + seg, b1 = a1 + seg;
                tri0.AddRange(new[] { a0, b0, a1, a1, b0, b1 });
            }
        int cliffStart = v.Count;
        for (int k = 0; k <= rows; k++)
            for (int s = 0; s < seg; s++)
            {
                float a = s * Mathf.PI * 2 / seg, f = (float)k / rows;
                float e = Edge(a) * (1 + 0.22f * f + 0.08f * N(a * 3 + seed, f * 5));
                float y = -0.25f - depth * f + 0.4f * N(a * 6, f * 3 + seed);
                v.Add(new Vector3(Mathf.Sin(a) * e, k == 0 ? -0.25f : y, Mathf.Cos(a) * e));
            }
        for (int k = 0; k < rows; k++)
            for (int s = 0; s < seg; s++)
            {
                int a0 = cliffStart + k * seg + s, a1 = cliffStart + k * seg + (s + 1) % seg, b0 = a0 + seg, b1 = a1 + seg;
                tri1.AddRange(new[] { a0, b0, a1, a1, b0, b1 });
            }
        var m = new Mesh { indexFormat = IndexFormat.UInt32 };
        m.SetVertices(v); m.subMeshCount = 2; m.SetTriangles(tri0, 0); m.SetTriangles(tri1, 1);
        return SaveMesh(m);
    }

    static Mesh Disc(float radius, int seg = 96)
    {
        var v = new List<Vector3> { Vector3.zero }; var uv = new List<Vector2> { new Vector2(0.5f, 0.5f) }; var t = new List<int>();
        for (int s = 0; s <= seg; s++) { float a = s * Mathf.PI * 2 / seg; v.Add(new Vector3(Mathf.Sin(a) * radius, 0, Mathf.Cos(a) * radius)); uv.Add(new Vector2(0.5f + Mathf.Sin(a) * 0.5f, 0.5f + Mathf.Cos(a) * 0.5f)); }
        for (int s = 1; s <= seg; s++) { t.Add(0); t.Add(s); t.Add(s + 1); }
        var m = new Mesh(); m.SetVertices(v); m.SetUVs(0, uv); m.SetTriangles(t, 0); return SaveMesh(m);
    }

    static Mesh Grid(float size, int n)
    {
        var v = new List<Vector3>(); var t = new List<int>();
        for (int j = 0; j <= n; j++) for (int i = 0; i <= n; i++) v.Add(new Vector3((i / (float)n - 0.5f) * size, 0, (j / (float)n - 0.5f) * size));
        for (int j = 0; j < n; j++) for (int i = 0; i < n; i++) { int a = j * (n + 1) + i, b = a + 1, c = a + n + 1, d = c + 1; t.AddRange(new[] { a, c, b, b, c, d }); }
        var m = new Mesh { indexFormat = IndexFormat.UInt32 }; m.SetVertices(v); m.SetTriangles(t, 0); return SaveMesh(m);
    }

    static Mesh Quad(float w, float h)
    {
        var m = new Mesh();
        m.SetVertices(new List<Vector3> { new(-w / 2, 0, 0), new(w / 2, 0, 0), new(-w / 2, h, 0), new(w / 2, h, 0) });
        m.SetUVs(0, new List<Vector2> { new(0, 0), new(1, 0), new(0, 1), new(1, 1) });
        m.SetTriangles(new[] { 0, 2, 1, 1, 2, 3 }, 0);
        return SaveMesh(m);
    }

    /// A rune ring for the stone circle: concentric rings and glyph marks, drawn into a texture (emission map).
    static Texture2D RuneTexture()
    {
        const int S = 1024; var tex = new Texture2D(S, S, TextureFormat.RGBA32, false);
        var px = new Color32[S * S];
        for (int y = 0; y < S; y++)
            for (int x = 0; x < S; x++)
            {
                float dx = (x - S / 2f) / (S / 2f), dy = (y - S / 2f) / (S / 2f), r = Mathf.Sqrt(dx * dx + dy * dy), a = Mathf.Atan2(dy, dx);
                float ring = Mathf.Max(Band(r, 0.92f, 0.012f), Band(r, 0.62f, 0.01f), Band(r, 0.34f, 0.008f), Band(r, 0.12f, 0.006f));
                float glyph = (r > 0.68f && r < 0.86f) ? Glyph(a, r, 28) : 0;
                float inner = (r > 0.40f && r < 0.56f) ? Glyph(a + 0.3f, r * 1.4f, 16) * 0.8f : 0;
                float v = Mathf.Clamp01(Mathf.Max(ring, Mathf.Max(glyph, inner)));
                byte b = (byte)(v * 255); px[y * S + x] = new Color32(b, b, b, 255);
            }
        tex.SetPixels32(px); tex.Apply();
        System.IO.File.WriteAllBytes($"{Gen}/runes.png", tex.EncodeToPNG());
        AssetDatabase.ImportAsset($"{Gen}/runes.png");
        return AssetDatabase.LoadAssetAtPath<Texture2D>($"{Gen}/runes.png");
    }
    static float Band(float r, float c, float w) => Mathf.Clamp01(1 - Mathf.Abs(r - c) / w);
    static float Glyph(float a, float r, int count)
    {
        float cell = (a / (Mathf.PI * 2) + 0.5f) * count, f = cell - Mathf.Floor(cell), id = Mathf.Floor(cell);
        float k = Mathf.PerlinNoise(id * 0.73f, 0.5f);
        float stroke = Mathf.Max(Band(f, 0.5f, 0.04f) * (k > 0.3f ? 1 : 0), Band(Mathf.Repeat(r * 30 + id, 1), 0.5f, 0.06f) * (k > 0.6f ? 1 : 0));
        return f > 0.18f && f < 0.82f ? stroke : 0;
    }

    static Sprite Sp(string p) => AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/" + p);

    static GameObject SpriteObj(string name, Sprite s, Transform parent, Vector3 pos, float scale, int order, Material m)
    {
        var go = new GameObject(name); go.transform.SetParent(parent, false); go.transform.localPosition = pos; go.transform.localScale = Vector3.one * scale;
        var r = go.AddComponent<SpriteRenderer>(); r.sprite = s; r.sortingOrder = order; r.sharedMaterial = m;
        return go;
    }

    static Light PointLight(string name, Transform parent, Vector3 pos, Color c, float intensity, float range)
    {
        var go = new GameObject(name); go.transform.SetParent(parent, false); go.transform.localPosition = pos;
        var l = go.AddComponent<Light>(); l.type = LightType.Point; l.color = c; l.intensity = intensity; l.range = range; l.shadows = LightShadows.None;
        return l;
    }

    static ParticleSystem Particles(string name, Transform parent, Vector3 pos, Material m, Color c, float rate, float life, float speed, float size, float radius, float gravity = 0, int max = 200)
    {
        var go = new GameObject(name); go.transform.SetParent(parent, false); go.transform.localPosition = pos;
        var ps = go.AddComponent<ParticleSystem>();
        var main = ps.main; main.startLifetime = life; main.startSpeed = speed; main.startSize = size; main.maxParticles = max; main.startColor = c;
        main.simulationSpace = ParticleSystemSimulationSpace.World; main.gravityModifier = gravity;
        var em = ps.emission; em.rateOverTime = rate;
        var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Sphere; sh.radius = radius;
        var col = ps.colorOverLifetime; col.enabled = true;
        var g = new Gradient(); g.SetKeys(new[] { new GradientColorKey(Color.white, 0), new GradientColorKey(Color.white, 1) },
            new[] { new GradientAlphaKey(0, 0), new GradientAlphaKey(1, 0.15f), new GradientAlphaKey(0, 1) });
        col.color = g;
        go.GetComponent<ParticleSystemRenderer>().sharedMaterial = m;
        return ps;
    }

    static Vector2 BodyPx(float x, float y) => new Vector2((x - 364.5f) / 100f, (1105 - y) / 100f);

    // ---------- The scene ----------
    static void BuildScene()
    {
        System.IO.Directory.CreateDirectory(Gen);
        meshCount = 0;
        foreach (var f in System.IO.Directory.GetFiles(Gen, "mesh_*.asset")) AssetDatabase.DeleteAsset(f);
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var rnd = new System.Random(7);
        float R(float a, float b) => a + (float)rnd.NextDouble() * (b - a);

        // Materials (the palette of the Age-of-Stone painting).
        var stone = Lit("Stone", new Color(0.80f, 0.70f, 0.56f));
        var stoneDark = Lit("StoneDark", new Color(0.58f, 0.50f, 0.43f));
        var rock = Lit("Rock", new Color(0.50f, 0.42f, 0.38f));
        var grass = Lit("Grass", new Color(0.46f, 0.52f, 0.24f));
        var leaves = Lit("Leaves", new Color(0.40f, 0.50f, 0.18f));
        var leavesGold = Lit("LeavesGold", new Color(0.62f, 0.58f, 0.22f));
        var ivy = Lit("Ivy", new Color(0.30f, 0.42f, 0.16f));
        var wisteria = Lit("Wisteria", new Color(0.55f, 0.42f, 0.75f));
        var trunk = Lit("Trunk", new Color(0.36f, 0.27f, 0.20f));
        var runes = RuneTexture();
        var circleMat = Lit("Circle", new Color(0.82f, 0.72f, 0.56f), 0.25f, new Color(2.2f, 1.2f, 0.45f), runes);
        var sky = ShaderMat("Sky", "Hush/Sky", m => m.SetVector("_SunDir", SunDir));
        var ocean = ShaderMat("Ocean", "Hush/Ocean", m => m.SetVector("_SunDir", SunDir));
        var fall = ShaderMat("Waterfall", "Hush/Waterfall");
        var spriteMat = ShaderMat("Sprite", "Hush/Sprite", m => { m.SetFloat("_DstBlend", 10); m.renderQueue = 3100; });
        var glowMat = ShaderMat("Glow", "Hush/Sprite", m => { m.SetFloat("_DstBlend", 1); m.SetTexture("_MainTex", Sp("FX/glow.png").texture); m.renderQueue = 3150; });
        var cloudMat = ShaderMat("Cloud", "Hush/Sprite", m => { m.SetFloat("_DstBlend", 10); m.SetColor("_Tint", new Color(1f, 0.82f, 0.78f, 0.75f)); m.renderQueue = 3050; });

        // Sun, sky, ambient light, fog.
        var sunGo = new GameObject("Sun"); var sun = sunGo.AddComponent<Light>();
        sun.type = LightType.Directional; sun.color = new Color(1f, 0.80f, 0.58f); sun.intensity = 1.9f;
        sun.shadows = LightShadows.Soft; sun.shadowStrength = 0.7f;
        sunGo.transform.rotation = Quaternion.LookRotation(-SunDir);
        RenderSettings.sun = sun;
        RenderSettings.skybox = sky;
        RenderSettings.ambientMode = AmbientMode.Trilight;
        RenderSettings.ambientSkyColor = new Color(0.62f, 0.60f, 0.64f);
        RenderSettings.ambientEquatorColor = new Color(0.92f, 0.74f, 0.60f);
        RenderSettings.ambientGroundColor = new Color(0.32f, 0.28f, 0.26f);
        RenderSettings.fog = true; RenderSettings.fogMode = FogMode.Linear;
        RenderSettings.fogColor = new Color(0.93f, 0.74f, 0.64f); RenderSettings.fogStartDistance = 40; RenderSettings.fogEndDistance = 420;

        // Post-processing: bloom, filmic tonemapping, a warm grade, a soft vignette.
        var volGo = new GameObject("Post Processing"); var vol = volGo.AddComponent<Volume>(); vol.isGlobal = true;
        var profile = ScriptableObject.CreateInstance<VolumeProfile>();
        var bloom = profile.Add<Bloom>(true); bloom.threshold.Override(1.1f); bloom.intensity.Override(0.75f); bloom.scatter.Override(0.72f); bloom.tint.Override(new Color(1f, 0.85f, 0.7f));
        var tone = profile.Add<Tonemapping>(true); tone.mode.Override(TonemappingMode.ACES);
        var ca = profile.Add<ColorAdjustments>(true); ca.postExposure.Override(0.05f); ca.contrast.Override(14); ca.saturation.Override(14);
        var vig = profile.Add<Vignette>(true); vig.intensity.Override(0.22f); vig.smoothness.Override(0.5f);
        AssetDatabase.CreateAsset(profile, $"{Gen}/PostProfile.asset");
        vol.sharedProfile = profile;

        var world = new GameObject("World").transform;

        // The ocean.
        var sea = MeshObject("Ocean", Grid(520, 220), world, ocean); sea.transform.position = new Vector3(0, -6f, 40);

        // The Sanctuary island.
        var island = new GameObject("Sanctuary Island").transform; island.SetParent(world, false);
        MeshObject("Island", IslandMesh(11f, 9f, 3.1f), island, grass, rock);
        // Rocky stacks in the sea around it.
        for (int i = 0; i < 9; i++)
        {
            float a = R(0, Mathf.PI * 2), d = R(14, 26);
            var st = MeshObject("Sea stack", IslandMesh(R(1.2f, 2.6f), R(3, 7), R(0, 50), 0.6f, 0), island, rock, rock);
            st.transform.position = new Vector3(Mathf.Sin(a) * d, -6f + R(1.5f, 4.5f), Mathf.Cos(a) * d);
        }

        // The stone circle with glowing runes, and steps down toward the front.
        var circle = MeshObject("Stone circle", Disc(3.3f), island, circleMat); circle.transform.localPosition = new Vector3(0, 0.03f, 0);
        Prim(PrimitiveType.Cylinder, "Circle rim", island, new Vector3(0, -0.06f, 0), new Vector3(7.4f, 0.12f, 7.4f), stoneDark);
        for (int i = 0; i < 4; i++)
            Prim(PrimitiveType.Cube, "Step", island, new Vector3(0, -0.12f - i * 0.16f, -3.9f - i * 0.45f), new Vector3(3.2f, 0.16f, 0.5f), stone);

        // Ruined arches around the back of the circle, with ivy.
        void Arch(Vector3 at, float yaw, float h, bool broken)
        {
            var arch = new GameObject("Arch").transform; arch.SetParent(island, false); arch.localPosition = at; arch.localEulerAngles = new Vector3(0, yaw, 0);
            Prim(PrimitiveType.Cube, "Pillar", arch, new Vector3(-1.1f, h / 2, 0), new Vector3(0.62f, h, 0.62f), stone);
            Prim(PrimitiveType.Cube, "Pillar", arch, new Vector3(1.1f, (broken ? h * 0.6f : h) / 2, 0), new Vector3(0.62f, broken ? h * 0.6f : h, 0.62f), stone);
            Prim(PrimitiveType.Cube, "Base", arch, new Vector3(-1.1f, 0.15f, 0), new Vector3(0.85f, 0.3f, 0.85f), stoneDark);
            Prim(PrimitiveType.Cube, "Base", arch, new Vector3(1.1f, 0.15f, 0), new Vector3(0.85f, 0.3f, 0.85f), stoneDark);
            if (!broken) Prim(PrimitiveType.Cube, "Lintel", arch, new Vector3(0, h + 0.22f, 0), new Vector3(3.0f, 0.45f, 0.75f), stone);
            for (int k = 0; k < 7; k++)
                Prim(PrimitiveType.Sphere, "Ivy", arch, new Vector3(R(-1.4f, 1.4f), R(h * 0.4f, h + 0.3f), R(-0.4f, 0.4f)), Vector3.one * R(0.25f, 0.55f), k % 3 == 0 ? wisteria : ivy);
        }
        Arch(new Vector3(-3.9f, 0, 2.6f), -35, 4.2f, false);
        Arch(new Vector3(0, 0, 4.6f), 0, 5.0f, false);
        Arch(new Vector3(3.9f, 0, 2.6f), 35, 3.6f, true);
        Arch(new Vector3(-6.5f, 0, 6.5f), -20, 6.2f, false);
        for (int i = 0; i < 6; i++)
        {
            float a = R(0, Mathf.PI * 2), d = R(5.5f, 9f);
            Prim(PrimitiveType.Cube, "Fallen stone", island, new Vector3(Mathf.Sin(a) * d, 0.2f, Mathf.Cos(a) * d), new Vector3(R(0.4f, 1.2f), R(0.3f, 0.6f), R(0.4f, 0.9f)), stoneDark, new Vector3(R(-20, 20), R(0, 360), R(-15, 15)));
        }

        // Braziers with real firelight around the circle.
        for (int i = 0; i < 5; i++)
        {
            float a = Mathf.Lerp(-110, 110, i / 4f) * Mathf.Deg2Rad + Mathf.PI;
            var p = new Vector3(Mathf.Sin(a) * 4.0f, 0, Mathf.Cos(a) * 4.0f);
            var b = new GameObject("Brazier").transform; b.SetParent(island, false); b.localPosition = p;
            Prim(PrimitiveType.Cylinder, "Stand", b, new Vector3(0, 0.45f, 0), new Vector3(0.28f, 0.45f, 0.28f), stoneDark);
            Prim(PrimitiveType.Cylinder, "Bowl", b, new Vector3(0, 0.95f, 0), new Vector3(0.75f, 0.12f, 0.75f), stone);
            var l = PointLight("Fire light", b, new Vector3(0, 1.4f, 0), new Color(1f, 0.6f, 0.25f), 1.6f, 4.5f); l.gameObject.AddComponent<Flicker>();
            Particles("Fire", b, new Vector3(0, 1.1f, 0), glowMat, new Color(1f, 0.6f, 0.25f, 0.9f), 26, 0.7f, 0.5f, 0.32f, 0.15f, -0.25f, 60);
        }

        // Trees on the island's edge.
        for (int i = 0; i < 9; i++)
        {
            float a = R(0, Mathf.PI * 2), d = R(7.5f, 10.5f);
            if (Mathf.Abs(Mathf.DeltaAngle(a * Mathf.Rad2Deg, 200)) < 55) continue;    // keep the view from the home camera open
            var t = new GameObject("Tree").transform; t.SetParent(island, false); t.localPosition = new Vector3(Mathf.Sin(a) * d, 0, Mathf.Cos(a) * d);
            float h = R(2.2f, 4f);
            Prim(PrimitiveType.Cylinder, "Trunk", t, new Vector3(0, h / 2, 0), new Vector3(0.28f, h / 2, 0.28f), trunk);
            for (int k = 0; k < 4; k++)
                Prim(PrimitiveType.Sphere, "Leaves", t, new Vector3(R(-0.8f, 0.8f), h + R(-0.2f, 0.8f), R(-0.8f, 0.8f)), Vector3.one * R(1.3f, 2.2f), k % 2 == 0 ? leaves : leavesGold);
        }

        // Waterfalls spilling off the island's edge into the sea.
        foreach (var a in new[] { 120f, 160f, 225f })
        {
            float ar = a * Mathf.Deg2Rad;
            var w = MeshObject("Waterfall", Quad(1.6f, 6.2f), island, fall);
            w.transform.localPosition = new Vector3(Mathf.Sin(ar) * 11.3f, -6.2f, Mathf.Cos(ar) * 11.3f);
            w.transform.localRotation = Quaternion.LookRotation(new Vector3(Mathf.Sin(ar), 0, Mathf.Cos(ar)));
            Particles("Mist", island, w.transform.localPosition + Vector3.up * 0.3f, cloudMat.GetTexture("_MainTex") ? cloudMat : glowMat, new Color(1, 1, 1, 0.35f), 6, 2.5f, 0.3f, 1.6f, 0.6f, -0.02f, 30);
        }

        // Distant realms in the haze (silhouettes for now), each with its own light.
        void Realm(string name, Vector3 at, float radius, float height, Color glow, int lanterns, float peak = 0)
        {
            var r = new GameObject(name).transform; r.SetParent(world, false); r.position = at;
            MeshObject("Island", IslandMesh(radius, height, R(0, 90), 1.2f, 0.1f), r, grass, rock);
            if (peak > 0) Prim(PrimitiveType.Capsule, "Peak", r, new Vector3(0, peak / 2, 0), new Vector3(radius * 0.9f, peak / 2, radius * 0.9f), rock);
            PointLight("Realm light", r, new Vector3(0, 3 + peak, 0), glow, 6, radius * 4);
            for (int k = 0; k < lanterns; k++)
            {
                var g = SpriteObj("Lantern", Sp("FX/glow.png"), r, new Vector3(R(-radius * 0.7f, radius * 0.7f), R(1, 4 + peak * 0.6f), R(-radius * 0.7f, radius * 0.7f)), R(1.5f, 3.5f), 50, glowMat);
                g.GetComponent<SpriteRenderer>().color = glow;
                g.AddComponent<Billboard>().fullFacing = true;
            }
        }
        Realm("The Whispering Grove", new Vector3(-55, -6, 70), 14, 6, new Color(1f, 0.75f, 0.4f), 26);
        Realm("The Stillwater", new Vector3(62, -6, 85), 12, 4, new Color(0.6f, 0.85f, 1f), 6);
        Realm("Forge Mountain", new Vector3(10, -6, 170), 20, 8, new Color(1f, 0.35f, 0.15f), 8, 26);
        Realm("The Library of Embers", new Vector3(-95, 10, 150), 9, 6, new Color(0.55f, 0.75f, 1f), 12);
        Realm("The Ascent Highlands", new Vector3(110, -6, 150), 18, 7, new Color(1f, 0.6f, 0.3f), 6, 12);

        // Clouds: banks around the island at different heights, slowly drifting.
        for (int i = 0; i < 26; i++)
        {
            float a = R(0, Mathf.PI * 2), d = R(55, 170);
            if (Mathf.Abs(Mathf.DeltaAngle(a * Mathf.Rad2Deg, 200)) < 45) continue;     // never in front of the home camera
            var c = SpriteObj("Cloud", Sp("FX/cloud.png"), world, new Vector3(Mathf.Sin(a) * d, R(2, 24), Mathf.Cos(a) * d), R(6, 14), 5, cloudMat);
            c.AddComponent<Billboard>(); var dr = c.AddComponent<Drift>(); dr.velocity = new Vector3(R(0.15f, 0.5f), 0, 0); dr.wrap = 40;
        }
        // Embers and fireflies in the air above the circle.
        Particles("Air sparks", island, new Vector3(0, 2.5f, 0), glowMat, new Color(1f, 0.8f, 0.45f, 0.8f), 10, 5, 0.15f, 0.08f, 6, -0.01f, 80);

        // Your Flame on the circle: Codex's parts on a billboard that faces the camera, and a real light.
        var flameRoot = new GameObject("Flame").transform; flameRoot.SetParent(island, false); flameRoot.localPosition = new Vector3(0, 0.05f, 0.2f);
        flameRoot.gameObject.AddComponent<Billboard>();
        var flameScale = new GameObject("Scale").transform; flameScale.SetParent(flameRoot, false); flameScale.localScale = Vector3.one * (1.15f / 11.05f);
        var body = new GameObject("Body (feet pivot)").transform; body.SetParent(flameScale, false);
        var tongues = new Transform[5]; float[] dxs = { -240, -130, 0, 130, 240 };
        for (int i = 0; i < 5; i++)
        {
            float dx = dxs[i], surfaceY = 290 - Mathf.Sqrt(300 * 300 - dx * dx);
            var sp = Sp($"Flame/lf-tongue-{i}.png"); float hPx = sp.rect.height * 0.5f;
            var b = BodyPx(365 + dx, surfaceY) - new Vector2(0, hPx * 0.38f / 100f);
            var t = SpriteObj($"Tongue {i}", sp, body, new Vector3(b.x, b.y, 0.01f), 0.5f, 10 + i, spriteMat).transform;
            t.localEulerAngles = new Vector3(0, 0, -dx / 240f * 16f); tongues[i] = t;
        }
        SpriteObj("Body", Sp("Flame/lf-body.png"), body, new Vector3(0, 11.05f / 2, 0), 1, 20, spriteMat);
        var face = new GameObject("Face").transform; face.SetParent(body, false); face.localPosition = new Vector3(0, 0, -0.01f);
        var eyeL = SpriteObj("Eye L", Sp("Flame/lf-eye-open-L.png"), face, BodyPx(228, 352), 0.75f, 30, spriteMat).GetComponent<SpriteRenderer>();
        var eyeR = SpriteObj("Eye R", Sp("Flame/lf-eye-open-R.png"), face, BodyPx(502, 352), 0.75f, 30, spriteMat).GetComponent<SpriteRenderer>();
        SpriteObj("Brow L", Sp("Flame/lf-brow-L.png"), face, BodyPx(222, 255), 0.575f, 31, spriteMat);
        SpriteObj("Brow R", Sp("Flame/lf-brow-R.png"), face, BodyPx(508, 255), 0.575f, 31, spriteMat);
        var mouth = SpriteObj("Mouth", Sp("Flame/lf-mouth-smile.png"), face, BodyPx(365, 432), 0.6f, 32, spriteMat).GetComponent<SpriteRenderer>();
        var rig = flameRoot.gameObject.AddComponent<FlameRig>();
        rig.body = body; rig.face = face; rig.tongues = tongues; rig.eyeL = eyeL; rig.eyeR = eyeR; rig.mouth = mouth;
        rig.eyeOpenL = Sp("Flame/lf-eye-open-L.png"); rig.eyeOpenR = Sp("Flame/lf-eye-open-R.png");
        rig.eyeClosedL = Sp("Flame/lf-eye-closed-L.png"); rig.eyeClosedR = Sp("Flame/lf-eye-closed-R.png");
        rig.eyeUp = Sp("Flame/lf-eye-up.png"); rig.eyeDown = Sp("Flame/lf-eye-down.png");
        rig.mouthSmile = Sp("Flame/lf-mouth-smile.png"); rig.mouthJoy = Sp("Flame/lf-mouth-joy.png"); rig.mouthO = Sp("Flame/lf-mouth-o.png");
        rig.mouthTalk = Sp("Flame/lf-mouth-talk.png"); rig.mouthFlat = Sp("Flame/lf-mouth-flat.png");
        rig.wanderRange = 6f;
        var fl = flameRoot.gameObject.AddComponent<FlameLight3D>();
        fl.glow = PointLight("Flame light", flameRoot, new Vector3(0, 0.55f, 0), new Color(1f, 0.62f, 0.3f), 1.4f, 4.2f); fl.baseIntensity = 1.4f; fl.baseRange = 4.2f;
        Particles("Flame embers", flameRoot, new Vector3(0, 0.8f, 0), glowMat, new Color(1f, 0.72f, 0.3f, 1), 10, 2, 0.25f, 0.05f, 0.25f, -0.03f, 40);
        var groundGlow = SpriteObj("Ground glow", Sp("FX/glow.png"), flameRoot, new Vector3(0, 0.04f, 0), 1.5f, 1, glowMat);
        groundGlow.transform.localEulerAngles = new Vector3(90, 0, 0); groundGlow.GetComponent<SpriteRenderer>().color = new Color(1f, 0.6f, 0.25f, 0.3f);
        var flameHit = flameRoot.gameObject.AddComponent<CapsuleCollider>(); flameHit.center = new Vector3(0, 0.8f, 0); flameHit.radius = 0.6f; flameHit.height = 1.8f;

        // The task: the candle bowl at the circle's edge (placeholder art), held to give light.
        var bowl = SpriteObj("Task: candle bowl", Sp("FX/bowl.png"), island, new Vector3(1.6f, 0.25f, -1.5f), 0.12f, 25, spriteMat);
        bowl.AddComponent<Billboard>();
        bowl.AddComponent<SphereCollider>().radius = 2.6f;
        var bowlGlow = SpriteObj("Glow", Sp("FX/glow.png"), bowl.transform, new Vector3(0, 0.6f, 0), 1.6f, 24, glowMat).GetComponent<SpriteRenderer>();
        var orb = SpriteObj("Light orb", Sp("FX/glow.png"), island, Vector3.zero, 0.5f, 60, glowMat); orb.AddComponent<Billboard>().fullFacing = true;
        PointLight("Orb light", orb.transform, Vector3.zero, new Color(1f, 0.8f, 0.45f), 2.5f, 3f);
        var burst = Particles("Burst", bowl.transform, new Vector3(0, 1.5f, 0), glowMat, new Color(1f, 0.82f, 0.45f, 1), 0, 0.9f, 2.2f, 0.12f, 0.2f, 0.4f, 60);
        var bm = burst.main; bm.loop = false; bm.playOnAwake = false; bm.duration = 0.2f;
        var be = burst.emission; be.SetBursts(new[] { new ParticleSystem.Burst(0, 40) });
        var hold = bowl.AddComponent<HoldToGive>();
        hold.art = bowl.GetComponent<SpriteRenderer>(); hold.glow = bowlGlow; hold.flame = rig; hold.flameLight = fl;
        hold.flameChest = fl.glow.transform; hold.orb = orb.transform; hold.burst = burst;

        // Camera + Cinemachine: home (driven by the director), the rise above the island, the world from high above.
        var camGo = new GameObject("Main Camera"); camGo.tag = "MainCamera";
        var cam = camGo.AddComponent<Camera>(); cam.fieldOfView = 45; cam.nearClipPlane = 0.1f; cam.farClipPlane = 700;
        var camData = camGo.AddComponent<UniversalAdditionalCameraData>(); camData.renderPostProcessing = true; camData.antialiasing = AntialiasingMode.FastApproximateAntialiasing;
        camGo.AddComponent<CinemachineBrain>();
        CinemachineCamera VCam(string n, Vector3 pos, Vector3 lookAt, float fov)
        {
            var go = new GameObject(n); go.transform.position = pos; go.transform.rotation = Quaternion.LookRotation(lookAt - pos);
            var c = go.AddComponent<CinemachineCamera>(); var lens = c.Lens; lens.FieldOfView = fov; lens.NearClipPlane = 0.1f; lens.FarClipPlane = 700; c.Lens = lens; return c;
        }
        var homeCam = VCam("Cam Home", new Vector3(-4.4f, 8.2f, -12.3f), new Vector3(0, 0.6f, 0), 42);
        var riseCam = VCam("Cam Rise", new Vector3(-6, 26, -24), new Vector3(0, 0, 4), 50);
        var worldCam = VCam("Cam World", new Vector3(0, 95, -90), new Vector3(0, -6, 70), 55);
        cam.transform.SetPositionAndRotation(homeCam.transform.position, homeCam.transform.rotation);

        // UI: the World / Home buttons and the cloud layer you pass through.
        var canvasGo = new GameObject("UI", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        canvasGo.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
        var scaler = canvasGo.GetComponent<CanvasScaler>(); scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize; scaler.referenceResolution = new Vector2(1179, 2556); scaler.matchWidthOrHeight = 0.5f;
        new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        var cloudsGo = new GameObject("Clouds", typeof(RectTransform), typeof(CanvasGroup)); cloudsGo.transform.SetParent(canvasGo.transform, false);
        var crt = (RectTransform)cloudsGo.transform; crt.anchorMin = Vector2.zero; crt.anchorMax = Vector2.one; crt.offsetMin = crt.offsetMax = Vector2.zero;
        var cg = cloudsGo.GetComponent<CanvasGroup>(); cg.blocksRaycasts = false;
        var pieces = new RectTransform[6];
        for (int i = 0; i < 6; i++)
        {
            var p = new GameObject("Cloud " + i, typeof(RectTransform), typeof(Image)); p.transform.SetParent(cloudsGo.transform, false);
            var img = p.GetComponent<Image>(); img.sprite = Sp("FX/cloud.png"); img.raycastTarget = false; img.color = new Color(1, 0.9f, 0.88f, 0.95f);
            var r = (RectTransform)p.transform; r.sizeDelta = new Vector2(2200, 2200); r.anchoredPosition = new Vector2((i % 3 - 1) * 500, (i / 3 - 0.5f) * 1100);
            pieces[i] = r;
        }
        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        Button MakeButton(string label)
        {
            var bgo = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button)); bgo.transform.SetParent(canvasGo.transform, false);
            var r = (RectTransform)bgo.transform; r.anchorMin = r.anchorMax = new Vector2(0.5f, 0); r.sizeDelta = new Vector2(440, 120); r.anchoredPosition = new Vector2(0, 170);
            bgo.GetComponent<Image>().color = new Color(0.08f, 0.06f, 0.05f, 0.7f);
            var tgo = new GameObject("Text", typeof(RectTransform), typeof(Text)); tgo.transform.SetParent(bgo.transform, false);
            var tr = (RectTransform)tgo.transform; tr.anchorMin = Vector2.zero; tr.anchorMax = Vector2.one; tr.offsetMin = tr.offsetMax = Vector2.zero;
            var tx = tgo.GetComponent<Text>(); tx.text = label; tx.font = font; tx.fontSize = 48; tx.alignment = TextAnchor.MiddleCenter; tx.color = new Color(1f, 0.88f, 0.7f);
            return bgo.GetComponent<Button>();
        }
        var worldBtn = MakeButton("The World"); var homeBtn = MakeButton("Home");

        var dirGo = new GameObject("Director"); var dir = dirGo.AddComponent<Island3DDirector>();
        dir.homeCam = homeCam; dir.riseCam = riseCam; dir.worldCam = worldCam; dir.focus = circle.transform; dir.flame = rig; dir.flameHit = flameHit;
        dir.clouds = cg; dir.cloudPieces = pieces; dir.worldButton = worldBtn; dir.homeButton = homeBtn;
        new GameObject("Sound").AddComponent<SoundSynth>();

        EditorSceneManager.SaveScene(scene, "Assets/Scenes/Island3D.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/Island3D.unity", true) };
        AssetDatabase.SaveAssets();
        Debug.Log("HUSH 3D SCENE BUILT");
    }

    [MenuItem("Hush/Snapshot 3D")]
    public static void Snapshot()
    {
        EditorSceneManager.OpenScene("Assets/Scenes/Island3D.unity");
        foreach (var (n, cname) in new[] { ("warmup", "Cam World"), ("home", "Cam Home"), ("rise", "Cam Rise"), ("world", "Cam World") })
        {
            var cam = Camera.main; var vc = GameObject.Find(cname);
            cam.transform.SetPositionAndRotation(vc.transform.position, vc.transform.rotation);
            var rt = new RenderTexture(1179 / 2, 2556 / 2, 24, RenderTextureFormat.ARGB32);
            cam.targetTexture = rt; cam.Render(); RenderTexture.active = rt;
            var tex = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0); tex.Apply();
            System.IO.File.WriteAllBytes($"Builds/snap3d-{n}.png", tex.EncodeToPNG());
            cam.targetTexture = null;
        }
        Debug.Log("HUSH 3D SNAPSHOTS SAVED");
    }
}
