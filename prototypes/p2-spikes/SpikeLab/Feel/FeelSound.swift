// Interaction sounds (P2.5 spec A.4), synthesized in-house so they're free and always in the same musical key
// (D major pentatonic). Ambience and music from free libraries come later (downloads asked first).
// Respects the silent switch (ambient category).
import AVFoundation

@MainActor
final class FeelSound {
    static let shared = FeelSound()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var chargeNode: AVAudioPlayerNode?

    // D major pentatonic (D, E, F#, A, B) across octaves.
    static let pentatonic: [Float] = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33, 659.25, 739.99, 880.0]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.8
        try? engine.start()
    }

    private func buffer(seconds: Double, _ sample: (Double) -> Float) -> AVAudioPCMBuffer {
        let n = AVAudioFrameCount(seconds * 44100)
        let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
        b.frameLength = n
        let d = b.floatChannelData![0]
        for i in 0..<Int(n) { d[i] = sample(Double(i) / 44100) }
        return b
    }
    private func play(_ b: AVAudioPCMBuffer, on node: AVAudioPlayerNode? = nil) {
        if !engine.isRunning { try? engine.start() }
        let p = node ?? player
        p.scheduleBuffer(b, at: nil, options: .interrupts)
        p.play()
    }

    /// A soft bell: sine partials with an exponential decay.
    private func bell(_ f: Double, t: Double, decay: Double = 3.0) -> Float {
        let env = exp(-t * decay) * min(1, t * 200)
        return Float(env * (sin(2 * .pi * f * t) * 0.6 + sin(2 * .pi * f * 2.0 * t) * 0.25 + sin(2 * .pi * f * 3.01 * t) * 0.1))
    }

    /// The hold: an airy tone rising through the pentatonic over `duration`, with a breath of noise.
    func startCharge(duration: Double = 1.0, pitch: Int = 0) {
        let node = AVAudioPlayerNode()
        engine.attach(node); engine.connect(node, to: engine.mainMixerNode, format: format)
        chargeNode = node
        let base = Double(Self.pentatonic[pitch % 5])
        var phase = 0.0
        let b = buffer(seconds: duration) { t in
            let k = t / duration
            let f = base * pow(2, k * 1.0)                         // one octave glide
            phase += 2 * .pi * f / 44100
            let noise = Double.random(in: -1...1) * 0.04 * k
            let env = min(1, t * 8) * (0.18 + 0.32 * k)
            return Float(env * (sin(phase) * 0.7 + sin(phase * 2) * 0.15) + noise)
        }
        play(b, on: node)
    }
    func stopCharge() {
        guard let node = chargeNode else { return }
        node.stop(); engine.detach(node); chargeNode = nil
    }

    /// Ignition: a soft fire bloom (filtered noise burst) + a chord of bells in the key.
    func ignite(pitch: Int = 0) {
        let notes = [0, 2, 4].map { Double(Self.pentatonic[(pitch + $0) % Self.pentatonic.count]) }
        var lp = 0.0
        play(buffer(seconds: 1.6) { t in
            let n = Double.random(in: -1...1)
            lp += (n - lp) * 0.08
            let fire = lp * exp(-t * 6) * 0.5
            let bells = notes.enumerated().reduce(0.0) { acc, x in acc + Double(self.bell(x.element, t: max(0, t - Double(x.offset) * 0.05), decay: 2.4)) }
            return Float(fire + bells * 0.28)
        })
    }

    /// The Flame catches the light: two quick high bells.
    func catchLight() {
        play(buffer(seconds: 0.6) { t in
            self.bell(1174.66, t: t, decay: 7) * 0.25 + self.bell(1479.98, t: max(0, t - 0.08), decay: 7) * 0.2
        })
    }

    /// A shimmering sweep for the light's flight.
    func sweep() {
        var phase = 0.0
        play(buffer(seconds: 0.9) { t in
            let f = 900 + 1400 * t
            phase += 2 * .pi * f / 44100
            let env = sin(.pi * t / 0.9)
            return Float(env * sin(phase) * 0.05 * (0.6 + 0.4 * sin(t * 60)))
        })
    }

    /// The Flame's babble (Emberspeak placeholder): a few pitched vowel-like syllables.
    func babble(syllables: Int = 4) {
        let notes = (0..<syllables).map { _ in Double(Self.pentatonic[Int.random(in: 3...8)]) }
        play(buffer(seconds: Double(syllables) * 0.13) { t in
            let i = min(syllables - 1, Int(t / 0.13))
            let local = t - Double(i) * 0.13
            let env = sin(.pi * min(1, local / 0.12))
            let f = notes[i] * (1 + 0.04 * sin(local * 40))
            let formant = sin(2 * .pi * f * t) * 0.6 + sin(2 * .pi * f * 2 * t) * 0.3 + sin(2 * .pi * 1200 * t) * 0.05
            return Float(env * formant * 0.12)
        })
    }

    /// A gentle chime for choices and arrivals.
    func chime(_ pitch: Int) { play(buffer(seconds: 1.2) { t in self.bell(Double(Self.pentatonic[pitch % Self.pentatonic.count]), t: t) * 0.25 }) }

    /// Wind swell for the camera rising (filtered noise rising and falling).
    func rise() {
        var lp = 0.0
        play(buffer(seconds: 1.8) { t in
            let n = Double.random(in: -1...1)
            let a = 0.02 + 0.05 * sin(.pi * t / 1.8)
            lp += (n - lp) * a
            return Float(lp * sin(.pi * t / 1.8) * 1.4)
        })
    }
}
