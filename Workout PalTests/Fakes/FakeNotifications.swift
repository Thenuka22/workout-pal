import Foundation
@testable import Workout_Pal

actor FakeNotifications: NotificationScheduling {
    private(set) var reminderWeekdays: Set<Int>?
    private(set) var reminderHour: Int?
    private(set) var reminderMinute: Int?
    private(set) var reminderCancelCount = 0
    private(set) var restAlerts: [Date] = []
    private(set) var restCancelCount = 0

    func scheduleWorkoutReminders(weekdays: Set<Int>, hour: Int, minute: Int) async {
        reminderWeekdays = weekdays
        reminderHour = hour
        reminderMinute = minute
    }

    func cancelWorkoutReminders() async {
        reminderWeekdays = nil
        reminderCancelCount += 1
    }

    func scheduleRestAlert(at date: Date, nextExercise: String?) async {
        restAlerts.append(date)
    }

    func cancelRestAlert() async {
        restCancelCount += 1
    }
}
