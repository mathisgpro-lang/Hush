// The light of the real day (corrections list #7): the worlds follow the sun, not just the clock. Sunrise and sunset
// move with the seasons (dark at 17:30 in December, light at 21:00 in June), from a rough place guessed from the
// time zone (no location permission). The shaders get a "light hour" in which sunrise is always 6:15 and sunset
// 18:45, so the painted looks of dawn, day, dusk and night (tod-lut.png) land at the right moments all year.
import Foundation
import RealityKit

enum SolarClock {
    /// A rough place for the time zone (latitude, longitude); the zone's own meridian when unknown.
    private static let place: (lat: Double, lon: Double) = {
        let tz = TimeZone.current
        let known: [String: (Double, Double)] = [
            "Europe/Paris": (48.9, 2.4), "Europe/London": (51.5, -0.1), "Europe/Berlin": (52.5, 13.4),
            "Europe/Madrid": (40.4, -3.7), "Europe/Rome": (41.9, 12.5), "Europe/Brussels": (50.8, 4.4),
            "Europe/Amsterdam": (52.4, 4.9), "Europe/Zurich": (47.4, 8.5), "America/New_York": (40.7, -74.0),
            "America/Los_Angeles": (34.1, -118.2), "America/Chicago": (41.9, -87.6), "Asia/Tokyo": (35.7, 139.7),
            "Australia/Sydney": (-33.9, 151.2), "America/Montreal": (45.5, -73.6), "America/Toronto": (43.7, -79.4),
        ]
        if let k = known[tz.identifier] { return k }
        let std = Double(tz.secondsFromGMT() - Int(tz.daylightSavingTimeOffset())) / 3600
        return (45, std * 15)
    }()

    /// Sunrise, solar noon and sunset today, in local clock hours.
    static func sun(on date: Date = Date()) -> (rise: Double, noon: Double, set: Double) {
        let cal = Calendar.current, tz = TimeZone.current
        let n = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 172)
        let decl = -23.44 * cos(2 * .pi / 365 * (n + 10)) * .pi / 180
        let lat = place.lat * .pi / 180
        let cosW = max(-1, min(1, -tan(lat) * tan(decl)))
        let half = acos(cosW) * 180 / .pi / 15                       // half the day length, in hours
        let b = 2 * .pi * (n - 81) / 364                              // the equation of time (minutes)
        let eot = 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b)
        let zone = Double(tz.secondsFromGMT(for: date)) / 3600
        let noon = 12 + zone - place.lon / 15 - eot / 60
        return (noon - half, noon, noon + half)
    }

    /// The clock bent so that sunrise is 6:15 and sunset 18:45 (what the shaders expect).
    static func lightHour(_ date: Date = Date()) -> Float {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = Double(c.hour ?? 18) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
        let s = sun(on: date)
        let rise = min(max(s.rise, 2), 10), set = min(max(s.set, 14), 23), noon = min(max(s.noon, rise + 1), set - 1)
        let pts: [(Double, Double)] = [(0, 0), (rise, 6.25), (noon, 12.5), (set, 18.75), (24, 24)]
        for i in 1..<pts.count where h <= pts[i].0 {
            let (x0, y0) = pts[i - 1], (x1, y1) = pts[i]
            return Float(y0 + (h - x0) / max(0.01, x1 - x0) * (y1 - y0))
        }
        return Float(h)
    }

    /// The looks of the hour, shared by every world's material (loaded once, no mipmaps: tiles must not blend).
    @MainActor private static var lutCache: TextureResource?
    @MainActor static func lut() async -> TextureResource? {
        if let lutCache { return lutCache }
        let t = try? await TextureResource(named: "tod-lut.png", options: .init(semantic: .raw, mipmapsMode: .none))
        lutCache = t
        return t
    }
}
