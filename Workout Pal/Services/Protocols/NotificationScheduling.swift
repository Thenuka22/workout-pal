import Foundation

protocol NotificationScheduling: Sendable {
    func scheduleWorkoutReminders(weekdays: Set<Int>, hour: Int, minute: Int) async
    func cancelWorkoutReminders() async
    func scheduleRestAlert(at date: Date, nextExercise: String?) async
    func cancelRestAlert() async
}
