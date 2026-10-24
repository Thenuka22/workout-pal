import Foundation
import HealthKit

final class HealthKitService: HealthService, @unchecked Sendable {
    private enum Measure: Sendable {
        case steps
        case distance

        var type: HKQuantityType {
            switch self {
            case .steps: HKQuantityType(.stepCount)
            case .distance: HKQuantityType(.distanceWalkingRunning)
            }
        }

        func value(of quantity: HKQuantity) -> Double {
            switch self {
            case .steps: quantity.doubleValue(for: .count())
            case .distance: quantity.doubleValue(for: .meter())
            }
        }
    }

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func todaySummary(now: Date) async throws -> HealthDaySummary {
        let startOfDay = Calendar.current.startOfDay(for: now)
        let steps = try await sum(.steps, from: startOfDay, to: now)
        let distance = try await sum(.distance, from: startOfDay, to: now)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: startOfDay) ?? startOfDay
        let workouts = try await otherWorkouts(since: weekAgo)
        return HealthDaySummary(
            steps: steps.map { Int($0.rounded()) },
            distanceMeters: distance,
            otherWorkouts: workouts
        )
    }

    private func sum(_ measure: Measure, from start: Date, to end: Date) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let store = store
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: measure.type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { @Sendable _, statistics, error in
                if let error {
                    if (error as? HKError)?.code == .errorNoData {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                continuation.resume(returning: statistics?.sumQuantity().map { measure.value(of: $0) })
            }
            store.execute(query)
        }
    }

    private func otherWorkouts(since start: Date) async throws -> [HealthWorkoutSummary] {
        let recent = HKQuery.predicateForSamples(withStart: start, end: nil, options: [])
        let notMine = NSCompoundPredicate(notPredicateWithSubpredicate: HKQuery.predicateForObjects(from: HKSource.default()))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [recent, notMine])
        let newestFirst = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let store = store
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HealthWorkoutSummary], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 10,
                sortDescriptors: [newestFirst]
            ) { @Sendable _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    HealthWorkoutSummary(
                        id: workout.uuid,
                        name: Self.name(for: workout.workoutActivityType),
                        startedAt: workout.startDate,
                        durationSeconds: workout.duration,
                        sourceName: workout.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    private static func name(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walk"
        case .running: "Run"
        case .hiking: "Hike"
        case .cycling: "Cycle"
        case .swimming: "Swim"
        case .yoga: "Yoga"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "Strength training"
        case .highIntensityIntervalTraining: "HIIT"
        default: "Workout"
        }
    }
}
