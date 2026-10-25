import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct RemindersViewModelTests {
    private let permissions = FakePermissions()
    private let notifications = FakeNotifications()
    private let settings = AppSettings(store: InMemoryPreferencesStore())

    private func makeModel() -> RemindersViewModel {
        RemindersViewModel(
            settings: settings,
            permissions: permissions,
            notifications: notifications,
            calendar: SampleData.calendar
        )
    }

    @Test func remindersStartOff() {
        let model = makeModel()
        #expect(!model.remindersEnabled)
        #expect(model.summary == "Off")
        #expect(model.weekdayOptions.first?.weekday == 2)
    }

    @Test func turningOnAsksForPermissionAndSchedules() async {
        let model = makeModel()
        model.setRemindersEnabled(true)
        #expect(await eventually { model.remindersEnabled })
        #expect(permissions.requested == [.notifications])
        let weekdays = await eventuallyValue { await notifications.reminderWeekdays }
        #expect(weekdays == [3, 5, 7])
        #expect(await notifications.reminderHour == 18)
    }

    @Test func deniedPermissionKeepsRemindersOff() async {
        permissions.statusAfterRequest = .denied
        let model = makeModel()
        model.setRemindersEnabled(true)
        #expect(await eventually { model.isBlocked })
        #expect(!model.remindersEnabled)
    }

    @Test func changingDaysReschedulesWithoutTheOldOnes() async {
        settings.update { $0.remindersEnabled = true }
        let model = makeModel()
        let tuesday = WeekdayOption(weekday: 3, title: "Tue")
        model.toggle(tuesday)
        #expect(!model.isSelected(tuesday))
        let weekdays = await eventuallyValue { () async -> Set<Int>? in
            let current = await notifications.reminderWeekdays
            return current == [5, 7] ? current : nil
        }
        #expect(weekdays == [5, 7])
    }

    @Test func turningOffCancelsReminders() async {
        settings.update { $0.remindersEnabled = true }
        let model = makeModel()
        model.setRemindersEnabled(false)
        let cancels = await eventuallyValue { () async -> Int? in
            let count = await notifications.reminderCancelCount
            return count > 0 ? count : nil
        }
        #expect(cancels == 1)
        #expect(model.summary == "Off")
    }

    @Test func summaryListsDaysInWeekOrder() {
        var preferences = UserPreferences.standard
        preferences.remindersEnabled = true
        preferences.reminderWeekdays = [7, 3, 1]
        let summary = Formatting.reminder(preferences, calendar: SampleData.calendar)
        let days = SampleData.calendar.shortWeekdaySymbols
        #expect(summary.hasPrefix("\(days[2]), \(days[6]), \(days[0]) · "))
    }
}
