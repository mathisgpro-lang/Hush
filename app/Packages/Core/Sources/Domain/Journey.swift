import Foundation

/// The First Journey (chapter 28 §A.8): steps open by living, never by the calendar alone.
public enum Journey {
    public static let stepCount = 6

    /// 0 = I The Ember, 1 = II The Spark, 2 = III The Others, 3 = IV The Voice, 4 = V The Chronicle, 5 = VI The Forge.
    public static func step(daysSinceBirth: Int, activeDays: Int, ownsMetal: Bool) -> Int {
        if ownsMetal { return 5 }
        if activeDays >= 10 && daysSinceBirth >= 7 { return 4 }
        if activeDays >= 7 { return 3 }
        if activeDays >= 3 { return 2 }
        if daysSinceBirth >= 1 && activeDays >= 1 { return 1 }
        return 0
    }

    /// The Metal Era (chapter 03 §B.4 rule set v1): 30 active days and total Depth ≥ 60.
    public static func metalEligible(activeDays: Int, totalDepth: Double) -> Bool {
        activeDays >= 30 && totalDepth >= 60
    }

    /// ISO week identifier ("2026-W40") of a lived day, used for weekly Rituals and the Chronicle.
    public static func isoWeek(_ day: LocalDate) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: 12))!
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear!, c.weekOfYear!)
    }
}
