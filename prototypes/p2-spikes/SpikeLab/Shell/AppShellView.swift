// The app shell's root: one screen at a time, with movement between them (the intro, home, the road map, a world).
import SwiftUI
import RealityKit

struct AppShellView: View {
    @State private var model = ShellModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
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
                RealmView(model: model, realm: r).overlay(DiveArrival(model: model)).transition(.opacity)
            }
        }
        .buttonStyle(PressableStyle())          // every button reacts the instant it's touched
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
        RealityView { content in
            content.camera = .virtual
            content.add(model.worldRoot)
            try? await Task.sleep(for: .milliseconds(200))     // let the first screen appear before the world loads
            let t0 = CACurrentMediaTime()
            await model.ensure(.sanctuary)
            if CommandLine.arguments.contains("-perf") {
                print(String(format: "LAUNCH world ready %.0f ms after the 3D view (build %.0f ms)", (CACurrentMediaTime() - AppTimer.start) * 1000, (CACurrentMediaTime() - t0) * 1000))
            }
            model.showActive()
            model.updates = content.subscribe(to: SceneEvents.Update.self) { e in model.tick(Float(e.deltaTime)) }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

enum AppTimer { static let start = CACurrentMediaTime() }
