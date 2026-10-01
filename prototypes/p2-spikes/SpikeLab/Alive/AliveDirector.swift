// The alive system (decision 93): decides when and what the Flame does. Each Flame route (Blender, image-to-3D,
// painted rig) only implements FlameRig, so all three are judged by exactly the same behavior.
import Foundation
import QuartzCore

enum Pillar: String, CaseIterable, Sendable { case body, mind, heart, spirit, craft, world }

enum Reaction: Sendable, Equatable {
    case giggle                 // tapped
    case leanIn                 // long press
    case cheer                  // a completed action
    case pillar(Pillar)         // a pillar-specific reaction after an action
}

@MainActor
protocol FlameRig: AnyObject {
    func perform(_ idle: IdleBehavior)
    func react(_ reaction: Reaction)
    func blink()
    /// Where the eyes look, in view space: (-1…1, -1…1); nil returns to neutral.
    func look(at point: SIMD2<Float>?)
    /// Phone tilt, in radians (roll, pitch): the Flame sways with it.
    func lean(_ tilt: SIMD2<Float>)
    /// Mood (Vitality) and seasonal tint drive glow and liveliness.
    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay)
    /// Mouth openness 0…1 (Emberspeak sync).
    func mouth(_ open: Float)
}

@MainActor @Observable
final class AliveDirector {
    var inputs = AliveInputs() { didSet { applyInputs() } }
    private(set) var history: [String] = []
    private(set) var lastLatencyMs: [Double] = []

    private weak var rig: FlameRig?
    private var picker: IdlePicker
    private var idleTask: Task<Void, Never>?
    private var blinkTask: Task<Void, Never>?
    private var rng: SeededRandom
    private let meter: FrameMeter

    init(seed: UInt64, meter: FrameMeter) {
        picker = IdlePicker(seed: seed)
        rng = SeededRandom(seed: seed ^ 0xB11CC)
        self.meter = meter
    }

    func attach(_ rig: FlameRig, tempo: Double = 1) {
        self.rig = rig
        picker.tempo = tempo
        applyInputs()
        start()
    }

    func start() {
        idleTask?.cancel(); blinkTask?.cancel()
        idleTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let delay = self.picker.nextDelay(self.inputs)
                try? await Task.sleep(for: .seconds(delay))
                if Task.isCancelled { return }
                let b = self.picker.next(self.inputs)
                self.rig?.perform(b)
                self.record("idle · \(b.rawValue)")
            }
        }
        blinkTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                // Blinks are independent of idles: every 2–6 s, sometimes a double blink.
                let wait = Double.random(in: 2...6, using: &self.rng)
                try? await Task.sleep(for: .seconds(wait))
                if Task.isCancelled { return }
                if self.inputs.timeOfDay == .night && self.inputs.mood < 0.3 { continue } // asleep: eyes stay closed
                self.rig?.blink()
                if Double.random(in: 0...1, using: &self.rng) < 0.15 {
                    try? await Task.sleep(for: .milliseconds(220))
                    self.rig?.blink()
                }
            }
        }
    }

    func stop() { idleTask?.cancel(); blinkTask?.cancel() }

    // MARK: Touch, with input-to-visible-response latency measured on the next presented frame.

    func tapped() { respond(.giggle) }
    func longPressed() { respond(.leanIn) }
    func actionCompleted(_ pillar: Pillar) {
        respond(.cheer)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            self?.rig?.react(.pillar(pillar))
            self?.record("react · \(pillar.rawValue)")
        }
    }

    func fingerMoved(_ p: SIMD2<Float>?) { rig?.look(at: p) }
    func tilted(_ t: SIMD2<Float>) { rig?.lean(t) }

    private func respond(_ r: Reaction) {
        let touchTime = CACurrentMediaTime()
        rig?.react(r)
        record("react · \(r)")
        meter.onNextFrame { [weak self] frameTime in
            guard let self else { return }
            let ms = (frameTime - touchTime) * 1000
            self.lastLatencyMs = Array((self.lastLatencyMs + [ms]).suffix(20))
        }
    }

    private func applyInputs() {
        rig?.setMood(Float(inputs.mood), season: inputs.season, timeOfDay: inputs.timeOfDay)
    }

    private func record(_ s: String) {
        let t = String(format: "%.1f", CACurrentMediaTime().truncatingRemainder(dividingBy: 1000))
        history = Array((history + ["\(t) \(s)"]).suffix(10))
    }
}
