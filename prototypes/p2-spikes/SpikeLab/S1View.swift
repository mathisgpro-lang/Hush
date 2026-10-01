// S1 · The living Flame (P2 plan §B.3). The alive system + touch + tilt + awareness controls, on any FlameRig.
import SwiftUI
import RealityKit
import CoreMotion

@MainActor
final class TiltSource {
    private let motion = CMMotionManager()
    var isLive: Bool { motion.isDeviceMotionActive }

    func start(_ handler: @escaping (SIMD2<Float>) -> Void) {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30
        motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let a = data?.attitude else { return }
            handler(SIMD2(Float(a.roll), Float(a.pitch - 0.7)))   // ~40° is a natural holding angle
        }
    }

    func stop() { motion.stopDeviceMotionUpdates() }
}

enum FlameRoute: String, CaseIterable { case blender = "A · Blender", painted = "C · Layers", hero = "C · Codex hero" }

/// S1 with a route switcher: every route is judged by the same alive system and controls.
struct S1Screen: View {
    @State private var route: FlameRoute = CommandLine.arguments.contains("-hero") ? .hero
        : CommandLine.arguments.contains("-painted") ? .painted : .blender
    var body: some View {
        S1View(route: route)
            .id(route)
            .safeAreaInset(edge: .top) {
                Picker("Route", selection: $route) {
                    ForEach(FlameRoute.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal)
            }
    }
}

struct S1View: View {
    let route: FlameRoute
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var probe = ProbeModel()
    @State private var rig: FlameRig?
    @State private var tilt = TiltSource()
    @State private var simTilt = SIMD2<Float>(0, 0)
    @State private var showControls = !CommandLine.arguments.contains("-nocontrols")
    @State private var selfTest = ""

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.08, green: 0.06, blue: 0.1).ignoresSafeArea()
            GeometryReader { geo in
                RealityView { content in
                    content.camera = .virtual
                    let r: FlameRig
                    switch route {
                    case .blender:
                        guard let flame = try? await probe.load() else { return }
                        let b = flame.visualBounds(relativeTo: nil)
                        let s = 0.3 / max(b.extents.y, 0.001)
                        flame.scale = .init(repeating: s)
                        flame.position = -b.center * s
                        let probeRig = ProbeRig(probe: probe, model: flame)
                        content.add(probeRig.leanPivot)
                        probe.playIdle(transition: 0)
                        r = probeRig
                    case .painted:
                        let painted = PaintedRig(layout: .placeholder)
                        do { try await painted.build() } catch { selfTest = "painted rig failed: \(error)"; return }
                        content.add(painted.leanPivot)
                        r = painted
                    case .hero:
                        let hero = HeroRig()
                        do { try await hero.build() } catch { selfTest = "hero failed: \(error)"; return }
                        content.add(hero.leanPivot)
                        hero.updates = content.subscribe(to: SceneEvents.Update.self) { e in
                            hero.update(dt: Float(e.deltaTime))   // fluid motion, stepped every frame
                        }
                        r = hero
                    }

                    let camera = PerspectiveCamera()
                    camera.camera.fieldOfViewInDegrees = 40
                    camera.look(at: [0, -0.1, 0], from: [0, -0.05, 0.9], relativeTo: nil)   // Flame sits in the upper half, above the controls
                    content.add(camera)
                    let sun = DirectionalLight()
                    sun.light.intensity = 3000
                    sun.look(at: .zero, from: [0.4, 0.8, 0.6], relativeTo: nil)
                    content.add(sun)

                    rig = r
                    let d = AliveDirector(seed: 42, meter: meter)
                    director = d
                    d.attach(r, tempo: route == .hero ? 0.55 : 1)   // the painted Flame is livelier
                    applyLaunchOptions(d)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { v in director?.fingerMoved(normalized(v.location, in: geo.size)) }
                        .onEnded { _ in director?.fingerMoved(nil) }
                )
                .simultaneousGesture(TapGesture().onEnded { director?.tapped() })
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in director?.longPressed() })
            }
            VStack(spacing: 8) {
                HUDView(meter: meter)
                if let d = director {
                    Text(latencyText(d)).font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if showControls, let d = director { controls(d) }
                Button(showControls ? "Hide controls" : "Show controls") { showControls.toggle() }
                    .font(.caption).buttonStyle(.bordered)
            }
            .padding(.horizontal).padding(.bottom, 6)
        }
        .navigationTitle("S1 · \(route.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            meter.start()
            tilt.start { t in director?.tilted(t) }
        }
        .onDisappear { meter.stop(); tilt.stop(); director?.stop() }
    }

    @ViewBuilder private func controls(_ d: AliveDirector) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Time", selection: Binding(get: { d.inputs.timeOfDay }, set: { d.inputs.timeOfDay = $0 })) {
                ForEach(AliveInputs.TimeOfDay.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            Picker("Season", selection: Binding(get: { d.inputs.season }, set: { d.inputs.season = $0 })) {
                ForEach(AliveInputs.Season.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            HStack {
                Text("Mood").font(.caption)
                Slider(value: Binding(get: { d.inputs.mood }, set: { d.inputs.mood = $0 }), in: 0...1)
            }
            HStack(spacing: 4) {
                ForEach(Pillar.allCases, id: \.self) { p in
                    Button(p.rawValue) { d.actionCompleted(p) }.font(.caption2).buttonStyle(.bordered)
                }
            }
            if !tilt.isLive {
                HStack {
                    Text("Tilt").font(.caption)
                    Slider(value: Binding(get: { Double(simTilt.x) }, set: { simTilt.x = Float($0); d.tilted(simTilt) }), in: -0.7...0.7)
                }
            }
            Text(d.history.reversed().joined(separator: "\n"))
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).frame(height: 70, alignment: .top).clipped()
            if !selfTest.isEmpty { Text(selfTest).font(.system(size: 10, design: .monospaced)).foregroundStyle(.green) }
        }
        .padding(10)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }

    private func normalized(_ p: CGPoint, in size: CGSize) -> SIMD2<Float> {
        SIMD2(Float(p.x / size.width) * 2 - 1, 1 - Float(p.y / size.height) * 2)
    }

    private func latencyText(_ d: AliveDirector) -> String {
        guard !d.lastLatencyMs.isEmpty else { return "touch → response: tap the Flame" }
        let sorted = d.lastLatencyMs.sorted()
        let p50 = sorted[sorted.count / 2], p95 = sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.95))]
        return String(format: "touch → response  last %.0f ms · p50 %.0f · p95 %.0f (n=%d)", d.lastLatencyMs.last!, p50, p95, sorted.count)
    }

    /// Launch options for screenshots and tests in the simulator.
    private func applyLaunchOptions(_ d: AliveDirector) {
        let args = CommandLine.arguments
        if args.contains("-selftest") { selfTest = IdlePicker.selfTest() }
        if args.contains("-night") { d.inputs.timeOfDay = .night }
        if args.contains("-morning") { d.inputs.timeOfDay = .morning }
        if let i = args.firstIndex(of: "-mood"), i + 1 < args.count, let m = Double(args[i + 1]) { d.inputs.mood = m }
        if args.contains("-autotap") {
            Task { @MainActor in
                for _ in 0..<12 { try? await Task.sleep(for: .milliseconds(900)); d.tapped() }
            }
        }
    }
}
