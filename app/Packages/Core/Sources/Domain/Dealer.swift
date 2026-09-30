import Foundation

/// A Path the user walks (from `pathStarted` entries). Slice 1: at most 3, in the order started.
public struct ActivePath: Sendable, Equatable, Hashable {
    public let pathId: String
    public let templateId: String
    public let pillar: Pillar
    public init(pathId: String, templateId: String, pillar: Pillar) {
        self.pathId = pathId; self.templateId = templateId; self.pillar = pillar
    }
}

public struct SparkCandidate: Sendable, Equatable {
    public let id: String
    public let pillar: Pillar
    public init(id: String, pillar: Pillar) { self.id = id; self.pillar = pillar }
}

/// Hands you your day (chapter 05 §B.1, Slice 1 subset). Pure and deterministic.
public enum Dealer {
    public static let maxPaths = 3
    public static let sparkStretch = 1.25

    public static func activePaths(_ entries: [Entry]) -> [ActivePath] {
        var seen = Set<String>()
        var out: [ActivePath] = []
        for e in entries.sorted(by: { $0.occurredAt < $1.occurredAt }) {
            if case .pathStarted(let id, let template, let pillar) = e.payload, !seen.contains(id) {
                seen.insert(id)
                out.append(ActivePath(pathId: id, templateId: template, pillar: pillar))
            }
        }
        return Array(out.prefix(maxPaths))
    }

    public static func pathKey(_ pathId: String, _ day: LocalDate) -> String { "path:\(pathId):\(day)" }
    public static func sparkKey(_ sparkId: String, _ day: LocalDate) -> String { "spark:\(day):\(sparkId)" }

    /// The day's slots: one step per active Path, plus a Spark once the Spark has unlocked (day 2 onward).
    public static func plan(day: LocalDate, paths: [ActivePath], sparks: [SparkCandidate], seed: String,
                            sparkUnlocked: Bool, recentlyDealt: Set<String>) -> [PlannedSlot] {
        var slots = paths.map {
            PlannedSlot(occurrenceKey: pathKey($0.pathId, day), pillarWeights: [$0.pillar: 1], d: 1, isSpark: false)
        }
        if sparkUnlocked, let spark = pickSpark(day: day, paths: paths, sparks: sparks, seed: seed, recentlyDealt: recentlyDealt) {
            slots.append(PlannedSlot(occurrenceKey: sparkKey(spark.id, day), pillarWeights: [spark.pillar: 1],
                                     d: sparkStretch, isSpark: true))
        }
        return slots
    }

    /// Prefers pillars the user has no Path in (the Spark widens the adventure), avoids recent repeats.
    public static func pickSpark(day: LocalDate, paths: [ActivePath], sparks: [SparkCandidate], seed: String,
                                 recentlyDealt: Set<String>, excluding: Set<String> = []) -> SparkCandidate? {
        let pathPillars = Set(paths.map(\.pillar))
        let fresh = sparks.filter { !recentlyDealt.contains($0.id) && !excluding.contains($0.id) }
        let pool = fresh.isEmpty ? sparks.filter { !excluding.contains($0.id) } : fresh
        let widening = pool.filter { !pathPillars.contains($0.pillar) }
        let candidates = (widening.isEmpty ? pool : widening).sorted { $0.id < $1.id }
        guard !candidates.isEmpty else { return nil }
        return candidates[Int(fnv1a("\(seed)|\(day)") % UInt64(candidates.count))]
    }

    /// Stable 64-bit FNV-1a (deterministic across runs and platforms, unlike Swift's Hasher).
    public static func fnv1a(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return h
    }
}
