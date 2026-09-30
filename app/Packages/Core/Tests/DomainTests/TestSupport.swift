import Foundation
import Testing

/// Parses an ISO 8601 UTC instant, e.g. "2026-03-28T23:30:00Z".
func utc(_ s: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)!
}

/// The chapter 04 numeric contract: equal within 1e-9.
func expectClose(_ got: Double, _ want: Double, tolerance: Double = 1e-9,
                 sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(abs(got - want) <= tolerance, "got \(got), want \(want)", sourceLocation: sourceLocation)
}

/// Deterministic RNG for property tests (Swift's default RNG can't be seeded).
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
