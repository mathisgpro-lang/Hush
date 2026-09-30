/// One completed Action as the growth engine sees it (after corrections; chapter 04 §B.2).
public struct ScoredAction: Sendable, Equatable {
    public let occurrenceKey: String
    public let pillarWeights: [Pillar: Double]
    public let d: Double
    public let isSpark: Bool

    public init(occurrenceKey: String, pillarWeights: [Pillar: Double], d: Double, isSpark: Bool) {
        self.occurrenceKey = occurrenceKey
        self.pillarWeights = pillarWeights
        self.d = d
        self.isSpark = isSpark
    }

    public var isEdge: Bool { isSpark || d >= RuleSetV1.edgeDifficulty }

    /// w_p × d × edge. Non-finite or non-positive inputs contribute nothing (upstream validators should
    /// prevent them; the engine must never crash or be poisoned by them).
    public func contribution(to pillar: Pillar) -> Double {
        guard d.isFinite, d > 0, let w = pillarWeights[pillar], w.isFinite, w > 0 else { return 0 }
        return w * d * (isEdge ? RuleSetV1.edgeMultiplier : 1.0)
    }
}

/// Depth (chapter 04 §B.3): monotonic by construction.
public enum Depth {
    /// Concave, non-decreasing daily effort curve.
    public static func curve(_ x: Double) -> Double {
        min(x, 2.0) + 0.5 * min(max(x - 2.0, 0.0), 1.0) + 0.25 * max(x - 3.0, 0.0)
    }

    /// E(p, D): per occurrence, the max over its duplicates of w_p × d × edge; summed in key order.
    public static func effort(_ actions: [ScoredAction], pillar: Pillar) -> Double {
        var best: [String: Double] = [:]
        for a in actions {
            best[a.occurrenceKey] = max(best[a.occurrenceKey] ?? 0, a.contribution(to: pillar))
        }
        return best.keys.sorted().reduce(0.0) { $0 + best[$1]! }
    }

    /// Total Depth for a pillar. `days` = consecutive lived days, oldest first (empty days included).
    public static func total(days: [[ScoredAction]], pillar: Pillar) -> Double {
        let efforts = days.map { effort($0, pillar: pillar) }
        var total = 0.0
        for i in efforts.indices {
            let window = efforts[max(0, i - RuleSetV1.consistencyWindow)..<i]
            let active = Double(window.filter { $0 > 0 }.count)
            let consistency = 1.0 + RuleSetV1.consistencyBonus * active / Double(RuleSetV1.consistencyWindow)
            total += curve(efforts[i]) * consistency
        }
        return total
    }
}
