import Foundation

public struct LocalDate: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year; self.month = month; self.day = day
    }

    public static func < (a: LocalDate, b: LocalDate) -> Bool {
        (a.year, a.month, a.day) < (b.year, b.month, b.day)
    }

    public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }
}

/// The wall-clock time at which a lived day starts (chapter 04: default 04:00; whole or half hours only).
public struct DayBoundary: Sendable, Equatable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        precondition((0..<24).contains(hour) && (minute == 0 || minute == 30), "boundary must be a whole or half hour")
        self.hour = hour; self.minute = minute
    }

    public static let `default` = DayBoundary(hour: 4, minute: 0)
}

/// Lived-day algorithm v2 (chapter 17 §B.6): B(X) = the earliest instant on date X whose wall clock is at or
/// after the boundary; livedDay(t) = the latest date X with B(X) ≤ t. Monotonic across DST gaps and repeats.
public enum LivedDayRule {
    public static let version = 2

    public static func livedDay(at instant: Date, in timeZone: TimeZone,
                                boundary: DayBoundary = .default) -> LocalDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: instant)
        let calendarDate = LocalDate(year: c.year!, month: c.month!, day: c.day!)
        if boundaryInstant(on: calendarDate, calendar: cal, boundary: boundary) <= instant {
            return calendarDate
        }
        let startOfDay = cal.date(from: c)!
        let previous = cal.date(byAdding: .day, value: -1, to: startOfDay)!
        let p = cal.dateComponents([.year, .month, .day], from: previous)
        return LocalDate(year: p.year!, month: p.month!, day: p.day!)
    }

    static func boundaryInstant(on date: LocalDate, calendar cal: Calendar, boundary: DayBoundary) -> Date {
        let start = cal.date(from: DateComponents(year: date.year, month: date.month, day: date.day))!
        return cal.nextDate(after: start.addingTimeInterval(-1),
                            matching: DateComponents(hour: boundary.hour, minute: boundary.minute, second: 0),
                            matchingPolicy: .nextTime,
                            repeatedTimePolicy: .first,
                            direction: .forward)!
    }
}

extension LocalDate {
    private static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private var noonUTC: Date {
        LocalDate.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    /// Calendar arithmetic on civil dates (no time zone involved).
    public func adding(days n: Int) -> LocalDate {
        let d = LocalDate.utcCalendar.date(byAdding: .day, value: n, to: noonUTC)!
        let c = LocalDate.utcCalendar.dateComponents([.year, .month, .day], from: d)
        return LocalDate(year: c.year!, month: c.month!, day: c.day!)
    }

    /// Whole days from `self` to `other` (positive if `other` is later).
    public func days(to other: LocalDate) -> Int {
        LocalDate.utcCalendar.dateComponents([.day], from: noonUTC, to: other.noonUTC).day!
    }
}
