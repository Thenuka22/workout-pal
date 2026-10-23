import HealthKit

enum HealthDataTypes {
    static var read: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKObjectType.workoutType(),
        ]
    }

    static var share: Set<HKSampleType> {
        [HKObjectType.workoutType()]
    }
}
