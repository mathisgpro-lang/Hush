/// Every constant of growth rule set v1 (chapter 04 Part B). Changing any value = a new rule set.
public enum RuleSetV1 {
    public static let version = 1
    public static let edgeMultiplier = 1.2
    public static let edgeDifficulty = 1.2
    public static let fillCap = 0.5
    public static let emptyScheduleFullDay = 2.0
    public static let restGrowthCredit = 1.0
    public static let vitalityWindow = 14
    public static let vitalityDecay = 0.8
    public static let freeDaySpan = 7
    public static let liveBoost = 0.3
    public static let vitalityFloor = 0.15
    public static let embersThreshold = 0.25
    public static let absenceForComeback = 3
    public static let relight: [Int: Double] = [1: 0.60, 2: 0.80, 3: 1.00]
    public static let consistencyWindow = 27
    public static let consistencyBonus = 0.5
}
