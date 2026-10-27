@MainActor
protocol AccountStateStore: AnyObject {
    var usesOfflineProfile: Bool { get set }
    var hasSeenWalkthrough: Bool { get set }
    var hasClaimedLocalData: Bool { get set }
}
