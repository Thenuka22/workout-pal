import Foundation
import UserNotifications

struct LocalNotificationScheduler: NotificationScheduling {
    private static let reminderIdentifiers = (1...7).map { "workout-reminder-\($0)" }
    private static let restIdentifier = "rest-timer"

    func scheduleWorkoutReminders(weekdays: Set<Int>, hour: Int, minute: Int) async {
        await cancelWorkoutReminders()
        for weekday in weekdays.sorted() where (1...7).contains(weekday) {
            let content = UNMutableNotificationContent()
            content.title = "Time to move"
            content.body = "Your workout is waiting. Open Workout Pal to start today's plan."
            content.sound = .default
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "workout-reminder-\(weekday)",
                content: content,
                trigger: trigger
            )
            await add(request)
        }
    }

    func cancelWorkoutReminders() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.reminderIdentifiers)
    }

    func scheduleRestAlert(at date: Date, nextExercise: String?) async {
        let interval = date.timeIntervalSinceNow
        guard interval >= 1 else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Rest is over"
        content.body = nextExercise.map { "Next up: \($0)." } ?? "Time for your next set."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        await add(UNNotificationRequest(identifier: Self.restIdentifier, content: content, trigger: trigger))
    }

    func cancelRestAlert() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.restIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.restIdentifier])
    }

    private func add(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UNUserNotificationCenter.current().add(request) { @Sendable _ in
                continuation.resume()
            }
        }
    }
}
