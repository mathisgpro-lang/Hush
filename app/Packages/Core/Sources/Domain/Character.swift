import Foundation

/// Your Flame's evolution (chapter 29 §A.2, §B.1): permanent stages earned by living, never revoked.
public enum CharacterStage: Int, CaseIterable, Sendable, Comparable {
    case spark, flame, blaze, kindled, beyond

    public static func < (a: CharacterStage, b: CharacterStage) -> Bool { a.rawValue < b.rawValue }

    public var name: String { ["Spark", "Flame", "Blaze", "Kindled", "Beyond"][rawValue] }

    /// Rule set v1 (by default, chapter 29 §B.1). Time lived matters, not bursts of effort.
    public static func earned(activeDays: Int, totalDepth: Double) -> CharacterStage {
        if activeDays >= 300 && totalDepth >= 800 { return .kindled }
        if activeDays >= 60 && totalDepth >= 120 { return .blaze }
        if activeDays >= 7 { return .flame }
        return .spark
    }

    public var key: String { "character:stage-\(rawValue)" }

    /// The stage your Flame shows: the highest one already celebrated (owned forever).
    public static func owned(witnessed: Set<String>) -> CharacterStage {
        allCases.last { $0 == .spark || witnessed.contains($0.key) } ?? .spark
    }

    /// The next stage to celebrate, if you've earned more than you've witnessed.
    public static func pending(activeDays: Int, totalDepth: Double, witnessed: Set<String>) -> CharacterStage? {
        let earned = earned(activeDays: activeDays, totalDepth: totalDepth)
        let owned = owned(witnessed: witnessed)
        return earned > owned ? CharacterStage(rawValue: owned.rawValue + 1) : nil
    }
}
