// The haptic language (P2.5 spec A.3): eight patterns, built with Core Haptics. Silent on devices without haptics.
import CoreHaptics
import UIKit

@MainActor
final class FeelHaptics {
    static let shared = FeelHaptics()
    private var engine: CHHapticEngine?
    private var charging: CHHapticAdvancedPatternPlayer?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = true
        engine?.resetHandler = { [weak self] in Task { @MainActor in try? self?.engine?.start() } }
        try? engine?.start()
    }

    private func tap(_ i: Float, _ s: Float, at t: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            .init(parameterID: .hapticIntensity, value: i), .init(parameterID: .hapticSharpness, value: s)], relativeTime: t)
    }
    private func hum(_ i: Float, _ s: Float, at t: TimeInterval, for d: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            .init(parameterID: .hapticIntensity, value: i), .init(parameterID: .hapticSharpness, value: s)], relativeTime: t, duration: d)
    }
    private func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard let engine, let p = try? CHHapticPattern(events: events, parameterCurves: curves) else { return }
        try? engine.makePlayer(with: p).start(atTime: CHHapticTimeImmediate)
    }

    func heartbeat() { play([tap(0.4, 0.2), tap(0.25, 0.2, at: 0.12)]) }
    func ignite() {
        play([tap(1.0, 0.6), hum(0.5, 0.3, at: 0.02, for: 0.4)],
             curves: [CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [.init(relativeTime: 0.02, value: 1), .init(relativeTime: 0.42, value: 0)], relativeTime: 0)])
    }
    func catchLight() { play([tap(0.6, 0.3), tap(0.3, 0.3, at: 0.1)]) }
    func rise() {
        play([hum(0.4, 0.1, at: 0, for: 1.5)],
             curves: [CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [.init(relativeTime: 0, value: 0.25), .init(relativeTime: 0.8, value: 1), .init(relativeTime: 1.5, value: 0)], relativeTime: 0)])
    }
    func arrive() { play([tap(0.7, 0.1)]) }
    func nudge() { play([tap(0.25, 0.3)]) }
    func nope() { play([tap(0.35, 0.8), tap(0.3, 0.8, at: 0.09)]) }

    /// The hold: a continuous rising charge (0.15 → 0.8 over `duration`) with soft ticks. Stop it with `stopCharge()`.
    func startCharge(duration: TimeInterval = 1.0) {
        guard let engine else { return }
        var events = [hum(0.8, 0.5, at: 0, for: duration)]
        var t: TimeInterval = 0.12
        while t < duration { events.append(tap(Float(0.15 + 0.5 * t / duration), 0.4, at: t)); t += 0.12 }
        let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 0.2), .init(relativeTime: duration, value: 1)], relativeTime: 0)
        guard let p = try? CHHapticPattern(events: events, parameterCurves: [curve]),
              let player = try? engine.makeAdvancedPlayer(with: p) else { return }
        charging = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }
    func stopCharge() { try? charging?.stop(atTime: CHHapticTimeImmediate); charging = nil }
}
