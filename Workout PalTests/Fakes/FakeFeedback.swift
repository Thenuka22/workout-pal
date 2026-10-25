@testable import Workout_Pal

@MainActor
final class FakeFeedback: WorkoutFeedback {
    private(set) var countedReps: [Int] = []
    private(set) var completedSets = 0
    private(set) var finishedRests = 0

    func repCounted(_ count: Int) {
        countedReps.append(count)
    }

    func setCompleted() {
        completedSets += 1
    }

    func restFinished() {
        finishedRests += 1
    }
}
