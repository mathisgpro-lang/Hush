// THROWAWAY feel prototype (M0). Not the app. See README.md.
import SwiftUI
import Observation

enum Pillar: Int, CaseIterable, Identifiable {
    case body, mind, heart, spirit, craft, world
    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .body: Color(red: 0.91, green: 0.46, blue: 0.17)
        case .mind: Color(red: 0.29, green: 0.61, blue: 0.88)
        case .heart: Color(red: 0.85, green: 0.55, blue: 0.48)
        case .spirit: Color(red: 0.90, green: 0.91, blue: 0.94)
        case .craft: Color(red: 0.72, green: 0.54, blue: 0.23)
        case .world: Color(red: 0.37, green: 0.66, blue: 0.35)
        }
    }

    var name: String { ["Body", "Mind", "Heart", "Spirit", "Craft", "World"][rawValue] }

    /// Base pitch of the pillar's landing tone (its "voice").
    var toneHz: Double { [98, 523, 196, 659, 330, 262][rawValue] }
    /// Haptic character: sharpness of the pillar's texture.
    var sharpness: Float { [0.25, 0.85, 0.35, 0.15, 0.95, 0.5][rawValue] }
}

struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let pillar: Pillar
    let isSpark: Bool
    var done = false
}

struct Tuning {
    var holdSeconds = 0.25
    var flightSeconds = 0.7
    var thrumIntensity = 0.8
    var soundOn = true
}

struct SparkFlight: Identifiable {
    let id = UUID()
    let from: CGPoint
    let pillar: Pillar
    let start: Date
    let duration: Double
    let big: Bool
}

@Observable
final class FeelState {
    var vitality = 1.0
    var ascent = 1.0
    var veins: [Pillar: Double] = Dictionary(uniqueKeysWithValues: Pillar.allCases.map { ($0, $0.rawValue < 3 ? 0.22 : 0.1) })
    var recentMix: [Pillar: Double] = [.body: 0.4, .mind: 0.35, .heart: 0.25]
    var flareUntil = Date.distantPast
    var flights: [SparkFlight] = []
    var lastGain: (text: String, at: Date)? = nil
    var awayMode = false
    var comebackDays = 0
    var tuning = Tuning()
    var actions: [ActionItem] = FeelState.freshDay()

    let haptics = Haptics()
    let synth = Synth()

    init() {
        // Debug-only: `-autodemo` completes the first card after 1 s (for simulator screenshots).
        if ProcessInfo.processInfo.arguments.contains("-autodemo") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                if let first = self.actions.first {
                    self.complete(first, from: CGPoint(x: 200, y: 640), deliberate: true)
                }
            }
        }
    }

    static func freshDay() -> [ActionItem] {
        [
            ActionItem(title: "Morning run", subtitle: "4 km easy · Path", pillar: .body, isSpark: false),
            ActionItem(title: "Read", subtitle: "20 min · Path", pillar: .mind, isSpark: false),
            ActionItem(title: "Tell someone why you admire them", subtitle: "Spark", pillar: .heart, isSpark: true),
        ]
    }

    var dayComplete: Bool { actions.allSatisfy(\.done) }

    // MARK: - The tracking moment

    func pressBegan() {
        haptics.charge(seconds: tuning.holdSeconds)
        if tuning.soundOn { synth.play(.swell) }
    }

    func pressCancelled() { haptics.stopCharge() }

    /// Called on release. `deliberate` = the hold reached the charge time.
    func complete(_ item: ActionItem, from point: CGPoint, deliberate: Bool) {
        guard let i = actions.firstIndex(where: { $0.id == item.id }), !actions[i].done else { return }
        actions[i].done = true
        let comeback = awayMode
        haptics.stopCharge()
        haptics.strike(item.pillar, full: deliberate)
        if tuning.soundOn { synth.play(.strike) }

        let flight = SparkFlight(from: point, pillar: item.pillar, start: .now,
                                 duration: tuning.flightSeconds, big: item.isSpark || comeback)
        flights.append(flight)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(tuning.flightSeconds))
            self.land(item, comeback: comeback)
        }
    }

    private func land(_ item: ActionItem, comeback: Bool) {
        flights.removeAll { $0.pillar == item.pillar }
        veins[item.pillar] = min(1, (veins[item.pillar] ?? 0) + 0.14)
        for p in Pillar.allCases { recentMix[p] = (recentMix[p] ?? 0) * 0.85 }
        recentMix[item.pillar, default: 0] += 0.3

        let share = 1.0 / Double(actions.count)
        let gain = 0.01 * share
        ascent *= 1 + gain
        lastGain = (String(format: "+%.2f%%", gain * 100), .now)

        if comeback {
            awayMode = false
            comebackDays = 1
            vitality = 0.60
            flareUntil = .now.addingTimeInterval(2.4)
            haptics.comeback()
            if tuning.soundOn { synth.play(.comeback) }
        } else {
            vitality = min(1, vitality + 0.08)
            flareUntil = .now.addingTimeInterval(item.isSpark ? 1.2 : 0.6)
            haptics.thrum(item.pillar, intensity: Float(tuning.thrumIntensity))
            if tuning.soundOn { synth.play(.land(item.pillar)) }
        }

        if dayComplete {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.6))
                self.flareUntil = .now.addingTimeInterval(1.0)
                self.haptics.dayComplete()
                if self.tuning.soundOn { self.synth.play(.chord) }
                self.lastGain = ("Day complete · +1%", .now)
            }
        }
    }

    // MARK: - Debug

    func simulateAway() {
        vitality = 0.15
        awayMode = true
        actions = FeelState.freshDay()
    }

    func newDay() {
        actions = FeelState.freshDay()
        if comebackDays > 0 && comebackDays < 3 {
            comebackDays += 1
            vitality = max(vitality, comebackDays == 2 ? 0.8 : 1.0)
        }
    }
}
