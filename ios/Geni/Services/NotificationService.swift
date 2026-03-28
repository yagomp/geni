import Foundation
import UserNotifications

@Observable
@MainActor
class NotificationService {
    var isEnabled: Bool = false
    var reminderHour: Int = 17
    var reminderMinute: Int = 0
    var weeklyReportEnabled: Bool = false

    private let enabledKey = "geni_reminders_enabled"
    private let hourKey = "geni_reminder_hour"
    private let minuteKey = "geni_reminder_minute"
    private let weeklyEnabledKey = "geni_weekly_report_enabled"
    private let defaults = UserDefaults.standard

    init() {
        isEnabled = defaults.bool(forKey: enabledKey)
        reminderHour = defaults.object(forKey: hourKey) as? Int ?? 17
        reminderMinute = defaults.object(forKey: minuteKey) as? Int ?? 0
        weeklyReportEnabled = defaults.bool(forKey: weeklyEnabledKey)
    }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func enableReminders() {
        Task {
            let granted = await requestPermission()
            if granted {
                isEnabled = true
                defaults.set(true, forKey: enabledKey)
                scheduleDaily()
            }
        }
    }

    func disableReminders() {
        isEnabled = false
        defaults.set(false, forKey: enabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["geni_daily_reminder"])
    }

    func setReminderTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
        defaults.set(hour, forKey: hourKey)
        defaults.set(minute, forKey: minuteKey)
        if isEnabled {
            scheduleDaily()
        }
    }

    func scheduleDaily() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["geni_daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Geni"
        content.body = L.s(.reminderBody)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "geni_daily_reminder", content: content, trigger: trigger)

        center.add(request)
    }

    func enableWeeklyReport(profiles: [ChildProfile], persistence: PersistenceService) {
        Task {
            let granted = await requestPermission()
            if granted {
                weeklyReportEnabled = true
                defaults.set(true, forKey: weeklyEnabledKey)
                scheduleWeeklyReport(profiles: profiles, persistence: persistence)
            }
        }
    }

    func disableWeeklyReport() {
        weeklyReportEnabled = false
        defaults.set(false, forKey: weeklyEnabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["geni_weekly_report"])
    }

    func scheduleWeeklyReport(profiles: [ChildProfile], persistence: PersistenceService) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["geni_weekly_report"])

        let summaries = profiles.map { profile -> String in
            let report = persistence.weeklyStats(for: profile.id, profileName: profile.nickname)
            return "\(profile.nickname): \(report.daysActive)/7 \(L.s(.daysActiveOf7)), \(report.accuracy)% \(L.s(.accuracy))"
        }

        let content = UNMutableNotificationContent()
        content.title = "Geni - \(L.s(.weeklyReport))"
        content.body = summaries.joined(separator: " | ")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 18

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "geni_weekly_report", content: content, trigger: trigger)

        center.add(request)
    }
}
