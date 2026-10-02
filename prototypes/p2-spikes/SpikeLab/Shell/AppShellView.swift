// The app shell's root: one screen at a time, with movement between them (the intro, home, the road map, a world).
import SwiftUI

struct AppShellView: View {
    @State private var model = ShellModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch model.screen {
            case .intro:
                FinchIntro(model: model).transition(.opacity)
            case .home:
                HomeView(model: model).overlay(DiveArrival(model: model))
                    .transition(.asymmetric(insertion: .scale(scale: 1.15).combined(with: .opacity), removal: .opacity))
            case .map:
                LivingMapView(model: model).transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity), removal: .opacity))
            case .realm(let r):
                RealmView(model: model, realm: r).overlay(DiveArrival(model: model)).transition(.opacity)
            }
        }
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
                    try? await Task.sleep(for: .milliseconds(900))        // the realm finishes appearing under the light
                    withAnimation(.easeOut(duration: 1.2)) { light = 0 }
                    try? await Task.sleep(for: .milliseconds(1250)); model.arrivingByDive = false
                }
            }
    }
}
