// Picks the Flame's next idle behavior so it never visibly loops (decision 93, P2 plan §B.3 #6).
// Weighted, with per-behavior cooldowns, never the same behavior twice in a row, and seeded for reproducible measurements.
import Foundation

enum IdleBehavior: String, CaseIterable, Sendable {
    case glanceLeft, glanceRight, glanceUp, lookAtYou, stretch, hum, watchEmber, smallHop, sway, yawn, doze
}

/// SplitMix64: small, fast, seedable.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct AliveInputs: Sendable {
    enum TimeOfDay: String, CaseIterable, Sendable { case morning, day, evening, night }
    enum Season: String, CaseIterable, Sendable { case thaw, longLight, harvest, embernight }
    var timeOfDay: TimeOfDay = .day
    var season: Season = .longLight
    var mood: Double = 0.8          // Vitality, 0 (sleepy ember) … 1 (joyful)
}

struct IdlePicker {
    private var rng: SeededRandom
    private var last: IdleBehavior?
    private var lastUsed: [IdleBehavior: Int] = [:]
    private var step = 0

    init(seed: UInt64) { rng = SeededRandom(seed: seed) }

    /// Base weights shaped by the time of day and mood: mornings stretch and yawn, nights doze, low mood is calmer.
    static func weight(_ b: IdleBehavior, _ inputs: AliveInputs) -> Double {
        let energy = inputs.mood
        switch b {
        case .glanceLeft, .glanceRight: return 1.0
        case .glanceUp: return 0.6
        case .lookAtYou: return 1.2
        case .stretch: return inputs.timeOfDay == .morning ? 2.0 : 0.4
        case .yawn: return inputs.timeOfDay == .morning ? 1.2 : (inputs.timeOfDay == .night ? 1.5 : 0.1)
        case .doze: return inputs.timeOfDay == .night ? 2.0 : (energy < 0.3 ? 1.0 : 0.0)
        case .hum: return 0.5 + energy * 0.5
        case .watchEmber: return 0.8
        case .smallHop: return energy * 1.0
        case .sway: return 0.7
        }
    }

    /// Steps a behavior must wait before it can come back. At least 2 for everything, so A-B-A never happens
    /// (that's what made A-B-A-B patterns possible).
    static func cooldown(_ b: IdleBehavior) -> Int {
        switch b {
        case .stretch, .yawn, .smallHop: return 4
        case .doze: return 3
        default: return 2
        }
    }

    /// Seconds until the next idle behavior: 4–12 s, a little sooner when the Flame is lively.
    mutating func nextDelay(_ inputs: AliveInputs) -> Double {
        let base = Double.random(in: 4...12, using: &rng)
        return max(4, base * (1.15 - 0.3 * inputs.mood))
    }

    mutating func next(_ inputs: AliveInputs) -> IdleBehavior {
        step += 1
        let candidates = IdleBehavior.allCases.filter { b in
            guard b != last, Self.weight(b, inputs) > 0 else { return false }
            if let used = lastUsed[b], step - used <= Self.cooldown(b) { return false }
            return true
        }
        let pool = candidates.isEmpty ? IdleBehavior.allCases.filter { $0 != last } : candidates
        let total = pool.reduce(0) { $0 + Self.weight($1, inputs) }
        var roll = Double.random(in: 0..<max(total, 0.0001), using: &rng)
        var chosen = pool[0]
        for b in pool {
            roll -= Self.weight(b, inputs)
            if roll <= 0 { chosen = b; break }
        }
        last = chosen
        lastUsed[chosen] = step
        return chosen
    }

    /// Self-check used by the -selftest launch option: no immediate repeats, and no repeating pattern of length 2–6.
    static func selfTest(seed: UInt64 = 7, count: Int = 2000) -> String {
        var p = IdlePicker(seed: seed)
        let inputs = AliveInputs()
        var seq: [IdleBehavior] = []
        for _ in 0..<count { seq.append(p.next(inputs)) }
        let repeats = zip(seq, seq.dropFirst()).filter { $0 == $1 }.count
        var loops = 0
        for period in 2...6 {
            for start in stride(from: 0, to: seq.count - period * 3, by: 1) {
                let a = Array(seq[start..<start + period])
                if a == Array(seq[start + period..<start + 2 * period]) && a == Array(seq[start + 2 * period..<start + 3 * period]) {
                    loops += 1
                }
            }
        }
        let distinct = Set(seq).count
        return "selftest: \(count) picks, \(distinct) behaviors used, immediate repeats \(repeats), 3x-repeated patterns \(loops)"
    }
}
