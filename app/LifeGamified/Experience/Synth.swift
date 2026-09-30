// Placeholder sounds, synthesized on device. Real sound design (chapter 06/12) replaces these assets later.
import AVFoundation
import Domain

final class Synth {
    enum Sound: Hashable { case swell, strike, land(Pillar), chord, comeback, wind, birth }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var cache: [Sound: AVAudioPCMBuffer] = [:]
    private let ambience = AVAudioPlayerNode()
    private var ambienceStarted = false

    init() {
        // .ambient respects the silent switch (chapter 06 §A.5).
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for _ in 0..<6 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        engine.attach(ambience)
        engine.connect(ambience, to: engine.mainMixerNode, format: format)
        ambience.volume = 0
        try? engine.start()
    }

    /// The fire's own sound: a quiet, looping crackle. Level follows Vitality (embers ≈ silent).
    func setAmbience(vitality: Double) {
        guard engine.isRunning || (try? engine.start()) != nil else { return }
        if !ambienceStarted {
            ambience.scheduleBuffer(fireLoop(), at: nil, options: .loops)
            ambience.play()
            ambienceStarted = true
        }
        ambience.volume = Float(0.02 + 0.13 * max(0, min(1, vitality)))
    }

    func stopAmbience() { ambience.volume = 0 }

    private func fireLoop() -> AVAudioPCMBuffer {
        let sr = format.sampleRate
        let n = AVAudioFrameCount(6 * sr)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
        buf.frameLength = n
        let out = buf.floatChannelData![0]
        var rng = SystemRandomNumberGenerator()
        var brown = 0.0
        var pop = 0.0
        for i in 0..<Int(n) {
            // low roar: brown noise
            brown = (brown + Double.random(in: -1...1, using: &rng) * 0.02) * 0.995
            // crackles: sparse decaying clicks
            if Double.random(in: 0...1, using: &rng) < 0.0004 { pop = Double.random(in: 0.3...1, using: &rng) }
            pop *= 0.992
            let click = pop * Double.random(in: -1...1, using: &rng)
            // fade the loop's ends so it repeats seamlessly
            let edge = min(1, Double(min(i, Int(n) - i)) / (0.05 * sr))
            out[i] = Float((brown * 3 + click * 0.5) * edge)
        }
        return buf
    }

    func play(_ sound: Sound) {
        guard engine.isRunning || (try? engine.start()) != nil else { return }
        let buffer = cache[sound] ?? render(sound)
        cache[sound] = buffer
        let p = players[next]
        next = (next + 1) % players.count
        p.scheduleBuffer(buffer, at: nil, options: .interrupts)
        p.play()
    }

    private func render(_ sound: Sound) -> AVAudioPCMBuffer {
        switch sound {
        case .swell: return tone([(110, 0.25)], seconds: 0.35, attack: 0.25, decay: 6, noise: 0.05, gain: 0.25)
        case .strike: return tone([(2400, 0.2), (3600, 0.1)], seconds: 0.14, attack: 0.001, decay: 40, noise: 0.6, gain: 0.5)
        case .land(let p):
            let f = p.toneHz
            return tone([(f, 0.6), (f * 2, 0.25), (f * 3, 0.1)], seconds: 0.8, attack: 0.005, decay: 5, noise: 0.02, gain: 0.45)
        case .chord: return tone([(196, 0.3), (247, 0.25), (294, 0.25), (392, 0.2)], seconds: 1.6, attack: 0.05, decay: 2.2, noise: 0, gain: 0.35)
        case .comeback: return tone([(98, 0.4), (147, 0.3), (196, 0.3), (294, 0.2)], seconds: 2.2, attack: 1.1, decay: 1.6, noise: 0.08, gain: 0.45)
        case .wind: return tone([(55, 0.1)], seconds: 6, attack: 2.5, decay: 0.6, noise: 0.35, gain: 0.18)
        case .birth: return tone([(65, 0.4), (98, 0.35), (131, 0.3), (196, 0.25), (262, 0.15)], seconds: 4, attack: 1.8, decay: 0.9, noise: 0.06, gain: 0.5)
        }
    }

    /// partials: (frequency Hz, amplitude). Exponential decay after a linear attack.
    private func tone(_ partials: [(Double, Double)], seconds: Double, attack: Double,
                      decay: Double, noise: Double, gain: Double) -> AVAudioPCMBuffer {
        let sr = format.sampleRate
        let n = AVAudioFrameCount(seconds * sr)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
        buf.frameLength = n
        let out = buf.floatChannelData![0]
        var rng = SystemRandomNumberGenerator()
        for i in 0..<Int(n) {
            let t = Double(i) / sr
            let env = t < attack ? t / attack : exp(-(t - attack) * decay)
            var s = 0.0
            for (f, a) in partials { s += a * sin(2 * .pi * f * t) }
            s += noise * (Double.random(in: -1...1, using: &rng))
            out[i] = Float(s * env * gain)
        }
        return buf
    }
}
