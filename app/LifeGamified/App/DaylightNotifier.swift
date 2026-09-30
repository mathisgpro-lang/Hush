import Foundation
import UserNotifications

/// "Your day is ready" (chapter 05 §B.4): at most one gentle local notification a day, opt-in,
/// never about streaks or missed days. No push server; nothing leaves the phone.
enum DaylightNotifier {
    static let id = "day-ready"
    static let lines = [
        "Your day is ready.",
        "Your Flame is waiting for today's first spark.",
        "A new day in the Sanctuary.",
        "Something small and good waits for you today.",
    ]

    static func requestAndSchedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        schedule(hour: hour, minute: minute)
        return true
    }

    static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Life Gamified"
        content.body = lines[Calendar.current.component(.weekday, from: .now) % lines.count]
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        UserDefaults.standard.set(hour * 60 + minute, forKey: "notify.minutes")
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UserDefaults.standard.removeObject(forKey: "notify.minutes")
    }

    static var scheduledMinutes: Int? { UserDefaults.standard.object(forKey: "notify.minutes") as? Int }
}
