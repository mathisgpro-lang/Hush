// The app shell's root: one screen at a time, with movement between them (the intro, home, the road map, a world).
import SwiftUI

struct AppShellView: View {
    @State private var model = ShellModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch model.screen {
            case .intro:
                IntroView(model: model).transition(.opacity)
            case .home:
                HomeView(model: model).transition(.asymmetric(insertion: .scale(scale: 1.15).combined(with: .opacity), removal: .opacity))
            case .map:
                RoadMapView(model: model).transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity), removal: .opacity))
            case .realm(let r):
                RealmView(model: model, realm: r).transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(model.screen == .intro)
    }
}
