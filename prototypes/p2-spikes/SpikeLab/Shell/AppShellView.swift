// The app shell's root: one screen at a time, with movement between them (the intro, home, the road map, a world).
import SwiftUI
import RealityKit

struct AppShellView: View {
    @State private var model = ShellModel()

    var body: some View {
        let _ = PerfProbe.body("Shell")
        ZStack {
            Theme.floor.ignoresSafeArea()               // the ground the world rests on (never a black band)
            WorldLayer(model: model)
                .onAppear { if CommandLine.arguments.contains("-perf") { print(String(format: "LAUNCH first screen %.0f ms", (CACurrentMediaTime() - AppTimer.start) * 1000)) } }                 // the one 3D view: the worlds live here, screens float on top
            switch model.screen {
            case .intro:
                FinchIntro(model: model).transition(.opacity)
            case .home:
                HomeView(model: model).overlay(DiveArrival(model: model))
                    .transition(.asymmetric(insertion: .scale(scale: 1.06).combined(with: .opacity), removal: .opacity))
            case .map:
                LivingMapView(model: model).transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
            case .realm(let r):
                HomeView(model: model, world: r).id(r).overlay(DiveArrival(model: model)).transition(.opacity)   // the same interface in every world
            }
        }
        .overlay { LaunchVeil(visible: model.screen != .intro && !model.coreReady) }
        .buttonStyle(PressableStyle())          // every button reacts the instant it's touched
        .task {                                  // (-realm X) test: travel to a realm the way a user does, through home
            guard let i = CommandLine.arguments.firstIndex(of: "-realm"), i + 1 < CommandLine.arguments.count,
                  let r = RealmID(rawValue: CommandLine.arguments[i + 1]) else { return }
            while !model.sanctuaryBuilt { try? await Task.sleep(for: .milliseconds(200)) }
            try? await Task.sleep(for: .milliseconds(600))
            model.go(.realm(r))
        }
        .task { if CommandLine.arguments.contains("-uitest") { await runUITest(model) } }
        .task {                                  // (-reacttest) home → map → Grove → map → home, timing each change
            guard CommandLine.arguments.contains("-reacttest") else { return }
            for s in [Screen.map, .realm(.grove), .map, .home, .map, .home] {
                try? await Task.sleep(for: .seconds(5))
                withAnimation(.screen) { model.go(s) }
            }
        }
        .animation(.screen, value: model.screen)
        .preferredColorScheme(.dark)
        .statusBarHidden(model.screen == .intro)
    }
}

/// The end of the map's dive: the realm opens out of a wash of light (the screen starts white and clears while the
/// world settles from a little closer), so flying in feels like one continuous move.
struct DiveArrival: View {
    let model: ShellModel
    @State private var light: Double = 1
    var body: some View {
        Color(red: 1, green: 0.96, blue: 0.9).opacity(model.arrivingByDive ? light : 0).ignoresSafeArea().allowsHitTesting(false)
            .onAppear {
                guard model.arrivingByDive else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))        // the realm is already there (kept alive): clear quickly
                    withAnimation(.easeOut(duration: 0.55)) { light = 0 }
                    try? await Task.sleep(for: .milliseconds(600)); model.arrivingByDive = false
                }
            }
    }
}

/// The app's single 3D view (like a game engine's): it holds the Sanctuary, the map and the Grove under one root,
/// shows the one on screen and moves only that one. Screens are SwiftUI layers on top of it.
struct WorldLayer: View {
    let model: ShellModel
    var body: some View {
        if CommandLine.arguments.contains("-no3d") { Color(red: 0.2, green: 0.15, blue: 0.2).ignoresSafeArea() } else {
        RealityView { content in
            content.camera = .virtual
            content.add(model.worldRoot)
            try? await Task.sleep(for: .milliseconds(200))     // let the first screen appear before the world loads
            let t0 = CACurrentMediaTime()
            await model.ensure(.sanctuary)
            if model.screen != .intro { await model.preloadCore() }        // behind the dusk veil
            if CommandLine.arguments.contains("-perf") {
                print(String(format: "LAUNCH world ready %.0f ms after the 3D view (build %.0f ms)", (CACurrentMediaTime() - AppTimer.start) * 1000, (CACurrentMediaTime() - t0) * 1000))
            }
            model.showActive()
            model.updates = content.subscribe(to: SceneEvents.Update.self) { e in model.tick(Float(e.deltaTime)) }
        }
        .ignoresSafeArea()
        .modifier(RenderScale(scale: WorldLayer.renderScale))
        // A breath of overscan, pinned on the Flame's circle so it never moves: the camera's slow drift never shows an edge.
        .scaleEffect(1.04, anchor: UnitPoint(x: 0.5, y: 0.40 + model.worldLift))
        // The world's lower edge melts into the ground the quest sheet stands on.
        // (Solid ground continues below it, so the overscan never peeks out under the fade; no clipping, which would
        // cut the world off under the status bar.)
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                LinearGradient(colors: [Theme.floor.opacity(0), Theme.floor], startPoint: .top, endPoint: .bottom).frame(height: 110)
                Theme.floor.frame(height: 90)
            }
            .offset(y: 90)
            .opacity(model.worldLift > 0 ? 1 : 0)          // only when the world is a lifted stage (home, a realm)
        }
        .offset(y: -model.worldLift * UIScreen.main.bounds.height)        // the stage in the top half, fixed (decisions 157, 158)
        .animation(Motion.soft, value: model.worldLift)
        .allowsHitTesting(false)
        }
    }

    /// The painted world is drawn at 75% of the screen's resolution, then scaled up: painted art stays sharp, and
    /// the graphics chip gets its headroom back (the 3D's fixed cost scales with pixels: 4.4 → 1.2 ms at 60%).
    /// The interface itself (text, buttons, sheets) is always drawn at full resolution. (-rs N to test others.)
    static let renderScale: CGFloat = {
        let a = CommandLine.arguments
        if let i = a.firstIndex(of: "-rs"), i + 1 < a.count, let v = Double(a[i + 1]) { return CGFloat(v) }
        return 0.75
    }()
}

/// Draws its content into a smaller frame (fewer pixels to shade) and scales it back up to fill the screen.
struct RenderScale: ViewModifier {
    let scale: CGFloat
    func body(content: Content) -> some View {
        if scale >= 0.999 { content } else {
            GeometryReader { g in
                content
                    .frame(width: g.size.width * scale, height: g.size.height * scale)
                    .scaleEffect(1 / scale, anchor: .topLeading)
            }
            .ignoresSafeArea()
        }
    }
}

enum AppTimer { static let start = CACurrentMediaTime() }

/// The short loading moment at launch: dusk, a breathing ember, then the world fades in fully prepared.
struct LaunchVeil: View {
    let visible: Bool
    @State private var gone = false
    @State private var breathe = false
    var body: some View {
        // Once faded, the veil leaves the screen entirely (its breathing animation must not keep running unseen:
        // it was redrawing the whole screen every frame and halving home to 30 fps).
        if !removed { veil }
    }
    @State private var removed = false
    private var veil: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.24, green: 0.18, blue: 0.36), Color(red: 0.55, green: 0.36, blue: 0.5), Color(red: 0.93, green: 0.6, blue: 0.48)],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 18) {
                Circle().fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.8, blue: 0.45), .clear], center: .center, startRadius: 2, endRadius: 40))
                    .frame(width: 80, height: 80).scaleEffect(breathe ? 1.08 : 0.92).opacity(breathe ? 1 : 0.8)
                Text("Waking the Emberlands").font(.story(17)).foregroundStyle(.white.opacity(0.85))
            }
        }
        .ignoresSafeArea()
        .opacity(gone ? 0 : 1)
        .allowsHitTesting(!gone)
        .onAppear {
            if !visible { removed = true; return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { breathe = true }
        }
        .onChange(of: visible) { _, v in
            if !v {
                withAnimation(.easeOut(duration: 0.45)) { gone = true }
                Task { @MainActor in try? await Task.sleep(for: .milliseconds(500)); removed = true }
            }
        }
    }
}
