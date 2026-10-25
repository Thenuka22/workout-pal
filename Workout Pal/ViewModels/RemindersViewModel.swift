import Foundation
import Observation

struct WeekdayOption: Identifiable, Hashable {
    let weekday: Int
    let title: String

    var id: Int { weekday }
}

@MainActor
@Observable
final class RemindersViewModel {
    private(set) var access: PermissionStatus = .notDetermined
    private(set) var isLoading = true

    private let settings: AppSettings
    private let permissions: any PermissionsProviding
    private let notifications: any NotificationScheduling
    private let calendar: Calendar

    init(
        settings: AppSettings,
        permissions: any PermissionsProviding,
        notifications: any NotificationScheduling,
        calendar: Calendar = .current
    ) {
        self.settings = settings
        self.permissions = permissions
        self.notifications = notifications
        self.calendar = calendar
    }

    var weekdayOptions: [WeekdayOption] {
        let symbols = calendar.shortWeekdaySymbols
        return (0..<7).map { offset in
            let weekday = ((calendar.firstWeekday - 1 + offset) % 7) + 1
            return WeekdayOption(weekday: weekday, title: symbols[weekday - 1])
        }
    }

    var remindersEnabled: Bool {
        settings.preferences.remindersEnabled
    }

    var restAlertsEnabled: Bool {
        settings.preferences.restAlertsEnabled
    }

    var summary: String {
        Formatting.reminder(settings.preferences, calendar: calendar)
    }

    var isBlocked: Bool {
        access == .denied
    }

    var reminderTime: Date {
        get {
            let preferences = settings.preferences
            return calendar.date(
                bySettingHour: preferences.reminderHour,
                minute: preferences.reminderMinute,
                second: 0,
                of: .now
            ) ?? .now
        }
        set {
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            settings.update { preferences in
                preferences.reminderHour = components.hour ?? preferences.reminderHour
                preferences.reminderMinute = components.minute ?? preferences.reminderMinute
            }
            reschedule()
        }
    }

    func isSelected(_ option: WeekdayOption) -> Bool {
        settings.preferences.reminderWeekdays.contains(option.weekday)
    }

    func load() async {
        access = await permissions.status(of: .notifications)
        isLoading = false
    }

    func setRemindersEnabled(_ enabled: Bool) {
        guard enabled else {
            settings.update { $0.remindersEnabled = false }
            reschedule()
            return
        }
        Task {
            let access = await self.permissions.request(.notifications)
            self.access = access
            guard access == .granted else {
                return
            }
            self.settings.update { $0.remindersEnabled = true }
            self.reschedule()
        }
    }

    func toggle(_ option: WeekdayOption) {
        settings.update { preferences in
            if preferences.reminderWeekdays.contains(option.weekday) {
                preferences.reminderWeekdays.remove(option.weekday)
            } else {
                preferences.reminderWeekdays.insert(option.weekday)
            }
        }
        reschedule()
    }

    func setRestAlertsEnabled(_ enabled: Bool) {
        settings.update { $0.restAlertsEnabled = enabled }
        if enabled && access == .notDetermined {
            Task {
                self.access = await self.permissions.request(.notifications)
            }
        }
    }

    private func reschedule() {
        let preferences = settings.preferences
        Task {
            if preferences.remindersEnabled && !preferences.reminderWeekdays.isEmpty {
                await self.notifications.scheduleWorkoutReminders(
                    weekdays: preferences.reminderWeekdays,
                    hour: preferences.reminderHour,
                    minute: preferences.reminderMinute
                )
            } else {
                await self.notifications.cancelWorkoutReminders()
            }
        }
    }
}
