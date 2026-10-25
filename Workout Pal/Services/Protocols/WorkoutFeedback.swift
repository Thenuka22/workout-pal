@MainActor
protocol WorkoutFeedback: AnyObject {
    func repCounted(_ count: Int)
    func setCompleted()
    func restFinished()
}
