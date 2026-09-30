import SwiftUI

@main
struct LifeGamifiedApp: App {
    @State private var model = AppModel()
    private let haptics = Haptics()
    private let synth = Synth()
    @State private var inBirth: Bool? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if inBirth ?? !model.isBorn {
                    BirthFlow(model: model, haptics: haptics, synth: synth) {
                        withAnimation(.easeInOut(duration: 1.2)) { inBirth = false }
                    }
                } else {
                    TodayView(model: model, haptics: haptics, synth: synth)
                        .transition(.opacity)
                }
            }
            .onAppear { if inBirth == nil { inBirth = !model.isBorn } }
            .onChange(of: model.isBorn) { _, born in if !born { inBirth = true } }
        }
    }
}
