import Foundation

@MainActor
final class TestClock {
    private(set) var now: Date

    init(_ now: Date) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

@MainActor
func eventually(timeout: Duration = .seconds(2), _ condition: () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if condition() {
            return true
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

@MainActor
func eventuallyValue<T>(timeout: Duration = .seconds(2), _ produce: () async -> T?) async -> T? {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if let value = await produce() {
            return value
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await produce()
}
