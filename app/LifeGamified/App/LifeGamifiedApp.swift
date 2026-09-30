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
                // Simulator testing only: `-demoScene carving|dawn` shows one birth scene directly.
                if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-demoScene"),
                   i + 1 < ProcessInfo.processInfo.arguments.count {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        if ProcessInfo.processInfo.arguments[i + 1] == "carving" { BirthCarving(duration: 3.0) } else { BirthDawn(model: model) }
                    }
                } else if inBirth ?? !model.onboarded {
                    BirthFlow(model: model, haptics: haptics, synth: synth, startPhase: BirthFlow.resumePhase(model)) {
                        withAnimation(.easeInOut(duration: 1.2)) { inBirth = false }
                    }
                } else {
                    TodayView(model: model, haptics: haptics, synth: synth)
                        .transition(.opacity)
                }
            }
            .onAppear { if inBirth == nil { inBirth = !model.onboarded } }
            .onChange(of: model.isBorn) { _, born in if !born { inBirth = true } }
        }
    }
}
