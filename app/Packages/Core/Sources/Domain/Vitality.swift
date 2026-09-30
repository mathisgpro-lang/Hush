import Foundation

/// Vitality (chapter 04 §B.5, rev 7). Mirrors `reference/growth_reference_v1.py::vitality` exactly.
public enum Vitality {
    public static func isEmbers(_ v: Double) -> Bool { v <= RuleSetV1.embersThreshold }

    /// Absence days (runs of ≥ 3 zeros) immediately followed by ≥ 3 finalized days with presence > 0.
    public static func forgivenDays(_ history: [Double]) -> Set<Int> {
        var out = Set<Int>()
        var i = 0
        while i < history.count {
            guard history[i] == 0 else { i += 1; continue }
            var j = i
            while j < history.count && history[j] == 0 { j += 1 }
            var k = j
            while k < history.count && history[k] > 0 { k += 1 }
            if j - i >= RuleSetV1.absenceForComeback && k - j >= 3 { out.formUnion(i..<j) }
            i = j
        }
        return out
    }

    public static func value(history rawHistory: [Double], today rawToday: Double = 0) -> Double {
        let clamp: (Double) -> Double = { $0.isFinite ? min(1, max(0, $0)) : 0 }
        let history = rawHistory.map(clamp)
        let today = clamp(rawToday)

        // Comeback state from finalized days only.
        var nFin = 0
        var k = history.count - 1
        while k >= 0 && history[k] > 0 { nFin += 1; k -= 1 }
        var absence = 0
        while k >= 0 && history[k] == 0 { absence += 1; k -= 1 }
        let inComeback = absence >= RuleSetV1.absenceForComeback && nFin <= 3 && (nFin >= 1 || today > 0)

        // Window: the last 14 finalized days, minus forgiven days; days before birth count as 1.0.
        let forgiven = forgivenDays(history)
        let lastIndices = history.isEmpty ? [] :
            Array(stride(from: history.count - 1, through: max(0, history.count - RuleSetV1.vitalityWindow), by: -1))
        let missing = RuleSetV1.vitalityWindow - lastIndices.count
        var past = lastIndices.filter { !forgiven.contains($0) }.map { history[$0] }
            + Array(repeating: 1.0, count: missing)

        let raw = (0..<past.count).map { pow(RuleSetV1.vitalityDecay, Double($0)) }
        let totalWeight = raw.reduce(0, +)
        let weights = totalWeight > 0 ? raw.map { $0 / totalWeight } : []

        let span = min(RuleSetV1.freeDaySpan, past.count)
        if span > 0 && past[0..<span].contains(where: { $0 > 0 }) {
            let j = (0..<span).min { (past[$0], $0) < (past[$1], $1) }!
            past[j] = 1.0
        }

        let vHist = zip(weights, past).reduce(0.0) { $0 + $1.0 * $1.1 }
        var v = vHist + (1.0 - vHist) * RuleSetV1.liveBoost * today
        if inComeback {
            let nEff = min(3, nFin + (today > 0 ? 1 : 0))
            if nEff >= 1, let relight = RuleSetV1.relight[nEff] { v = max(v, relight) }
        }
        return max(RuleSetV1.vitalityFloor, v)
    }
}
