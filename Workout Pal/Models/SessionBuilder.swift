import Foundation

enum SessionBuilder {
    static func session(from routine: Routine, ownerID: String, now: Date = .now) -> WorkoutSession {
        WorkoutSession(
            id: UUID(),
            ownerID: ownerID,
            routineID: routine.id,
            routineName: routine.name,
            startedAt: now,
            endedAt: nil,
            activeSeconds: 0,
            status: .active,
            notes: "",
            exercises: routine.exercises.map { item in
                SessionExercise(
                    id: UUID(),
                    exerciseID: item.exerciseID,
                    exerciseName: item.exerciseName,
                    restSeconds: item.restSeconds,
                    sets: (0..<max(item.plannedSets, 1)).map { _ in
                        WorkoutSet(
                            id: UUID(),
                            reps: item.plannedReps,
                            load: item.plannedLoad,
                            isCompleted: false,
                            completedAt: nil,
                            source: .manual
                        )
                    }
                )
            }
        )
    }
}
