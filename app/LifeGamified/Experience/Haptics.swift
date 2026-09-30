import CoreHaptics
import Domain

/// Core Haptics patterns for the tracking moment (chapter 06 §A.2, §B.3 starting values).
final class Haptics {
    private var engine: CHHapticEngine?
    private var chargePlayer: CHHapticAdvancedPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = false
        // Core Haptics calls this on its own queue: hop to the main actor (Swift 6 isolation; Codex code review).
        engine?.resetHandler = { @Sendable [weak self] in
            Task { @MainActor in
                self?.chargePlayer = nil
                try? self?.engine?.start()
            }
        }
        try? engine?.start()
    }

    private func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func transient(_ intensity: Float, _ sharpness: Float, at t: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [.init(parameterID: .hapticIntensity, value: intensity),
                                   .init(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: t)
    }

    private func continuous(_ intensity: Float, _ sharpness: Float, at t: TimeInterval, for d: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous,
                      parameters: [.init(parameterID: .hapticIntensity, value: intensity),
                                   .init(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: t, duration: d)
    }

    /// Press: a firm soft "button", then a rising hum while charging.
    func charge(seconds: Double) {
        guard let engine else { return }
        let hum = continuous(1.0, 0.2, at: 0.02, for: seconds)
        let ramp = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                          controlPoints: [.init(relativeTime: 0, value: 0.15),
                                                          .init(relativeTime: seconds, value: 0.7)],
                                          relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [transient(0.6, 0.4), hum], parameterCurves: [ramp])
            chargePlayer = try engine.makeAdvancedPlayer(with: pattern)
            try chargePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    func stopCharge() {
        try? chargePlayer?.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
    }

    /// Release: the crisp strike (lighter on a quick tap).
    func strike(_ pillar: Pillar, full: Bool) {
        play([transient(full ? 1.0 : 0.6, 0.9)])
    }

    /// Landing: a warm thrum in the pillar's texture (Heart = a double beat).
    func thrum(_ pillar: Pillar, intensity: Float) {
        var events = [continuous(intensity, pillar.sharpness * 0.4, at: 0, for: 0.18)]
        if pillar == .heart { events.append(transient(intensity * 0.7, 0.3, at: 0.24)) }
        if pillar == .craft { events.append(transient(intensity * 0.8, 0.95, at: 0.12)) }
        let fade = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                          controlPoints: [.init(relativeTime: 0, value: 1),
                                                          .init(relativeTime: 0.18, value: 0)],
                                          relativeTime: 0)
        play(events, curves: [fade])
    }

    /// The last Action of the day: two soft resolving beats.
    func dayComplete() {
        play([transient(0.5, 0.3), transient(0.8, 0.2, at: 0.18)])
    }

    /// The birth: a slow heartbeat that quickens and swells while the ember is held.
    func birthCharge(seconds: Double) {
        guard let engine else { return }
        var events: [CHHapticEvent] = []
        var t = 0.0, gap = 0.55
        while t < seconds {
            events.append(transient(Float(0.35 + 0.6 * t / seconds), 0.2, at: t))
            events.append(transient(Float(0.25 + 0.5 * t / seconds), 0.15, at: t + 0.12))
            t += gap; gap = max(0.18, gap * 0.86)
        }
        events.append(continuous(0.9, 0.3, at: seconds - 0.4, for: 0.4))
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [])
            chargePlayer = try engine.makeAdvancedPlayer(with: pattern)
            try chargePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    /// The carving: stone grain, felt as fine irregular taps.
    func carve(seconds: Double) {
        var events: [CHHapticEvent] = []
        var t = 0.0
        var i = 0
        while t < seconds {
            events.append(transient(Float(0.3 + 0.4 * Double((i * 7) % 5) / 4), 0.95, at: t))
            t += 0.06 + 0.05 * Double((i * 3) % 4); i += 1
        }
        play(events)
    }

    /// The comeback: a rising crescendo, then a deep bloom.
    func comeback() {
        let rise = continuous(1.0, 0.3, at: 0, for: 1.2)
        let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                           controlPoints: [.init(relativeTime: 0, value: 0.1),
                                                           .init(relativeTime: 1.1, value: 1.0),
                                                           .init(relativeTime: 1.2, value: 0.0)],
                                           relativeTime: 0)
        play([rise, transient(1.0, 0.6, at: 1.2), continuous(0.7, 0.15, at: 1.25, for: 0.5)], curves: [curve])
    }
}
