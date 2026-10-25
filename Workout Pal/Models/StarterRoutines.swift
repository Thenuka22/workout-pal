import Foundation

struct StarterSlot: Sendable {
    let area: BodyArea
    let difficulty: ExerciseDifficulty
    let preferredNames: [String]
    let sets: Int
    let reps: Int
    let restSeconds: Int
}

struct StarterTemplate: Identifiable, Sendable {
    let name: String
    let notes: String
    let slots: [StarterSlot]

    var id: String { name }
}

extension FitnessLevel {
    var planSymbolName: String {
        switch self {
        case .beginner: "leaf.fill"
        case .intermediate: "flame.fill"
        case .advanced: "bolt.fill"
        }
    }
}

enum StarterRoutines {
    static func templates(for level: FitnessLevel) -> [StarterTemplate] {
        switch level {
        case .beginner:
            [
                StarterTemplate(
                    name: "Full body foundations",
                    notes: "Simple moves for every area. Start light and focus on form.",
                    slots: [
                        StarterSlot(area: .legs, difficulty: .beginner, preferredNames: ["Squats", "Bodyweight Squat", "Air Squat"], sets: 3, reps: 12, restSeconds: 60),
                        StarterSlot(area: .chest, difficulty: .beginner, preferredNames: ["Push-Ups", "Push Up", "Pushups", "Incline Push Up"], sets: 3, reps: 10, restSeconds: 60),
                        StarterSlot(area: .back, difficulty: .beginner, preferredNames: ["Superman", "Bird Dog", "Back Extension"], sets: 3, reps: 12, restSeconds: 60),
                        StarterSlot(area: .abs, difficulty: .beginner, preferredNames: ["Crunches", "Dead Bug", "Deadbug"], sets: 3, reps: 15, restSeconds: 45),
                        StarterSlot(area: .shoulders, difficulty: .beginner, preferredNames: ["Lateral Raises", "Front Raises"], sets: 3, reps: 12, restSeconds: 45),
                    ]
                ),
            ]
        case .intermediate:
            [
                StarterTemplate(
                    name: "Upper body strength",
                    notes: "Presses, rows and arms with a steady rest between sets.",
                    slots: [
                        StarterSlot(area: .chest, difficulty: .intermediate, preferredNames: ["Bench Press", "Benchpress Dumbbells"], sets: 4, reps: 8, restSeconds: 90),
                        StarterSlot(area: .back, difficulty: .intermediate, preferredNames: ["Bent Over Rowing", "Bent Over Dumbbell Rows (Single Arm)"], sets: 4, reps: 8, restSeconds: 90),
                        StarterSlot(area: .shoulders, difficulty: .intermediate, preferredNames: ["Arnold Shoulder Press", "Shoulder Press, Dumbbells", "Military Press"], sets: 3, reps: 10, restSeconds: 75),
                        StarterSlot(area: .arms, difficulty: .intermediate, preferredNames: ["Biceps Curls With Dumbbell", "Biceps Curls With Barbell"], sets: 3, reps: 12, restSeconds: 60),
                        StarterSlot(area: .arms, difficulty: .intermediate, preferredNames: ["Barbell Triceps Extension", "Triceps Extension"], sets: 3, reps: 12, restSeconds: 60),
                    ]
                ),
                StarterTemplate(
                    name: "Lower body & core",
                    notes: "Squats, lunges and core work to round out the week.",
                    slots: [
                        StarterSlot(area: .legs, difficulty: .intermediate, preferredNames: ["Dumbbell Goblet Squat", "Barbell Squat"], sets: 4, reps: 10, restSeconds: 90),
                        StarterSlot(area: .legs, difficulty: .intermediate, preferredNames: ["Dumbbell Lunges Walking", "Dumbbell Lunges Standing"], sets: 3, reps: 10, restSeconds: 75),
                        StarterSlot(area: .calves, difficulty: .beginner, preferredNames: ["Calf Raises", "Standing Calf Raises"], sets: 3, reps: 15, restSeconds: 45),
                        StarterSlot(area: .abs, difficulty: .intermediate, preferredNames: ["Hanging Leg Raises", "Cable Woodchoppers"], sets: 3, reps: 12, restSeconds: 60),
                    ]
                ),
            ]
        case .advanced:
            [
                StarterTemplate(
                    name: "Push",
                    notes: "Heavy presses first, then higher-rep accessories.",
                    slots: [
                        StarterSlot(area: .chest, difficulty: .intermediate, preferredNames: ["Bench Press"], sets: 5, reps: 5, restSeconds: 150),
                        StarterSlot(area: .shoulders, difficulty: .intermediate, preferredNames: ["Military Press", "Arnold Shoulder Press"], sets: 4, reps: 6, restSeconds: 120),
                        StarterSlot(area: .chest, difficulty: .intermediate, preferredNames: ["Dips"], sets: 3, reps: 10, restSeconds: 90),
                        StarterSlot(area: .arms, difficulty: .intermediate, preferredNames: ["Bench Press Narrow Grip", "Barbell Triceps Extension"], sets: 3, reps: 10, restSeconds: 75),
                    ]
                ),
                StarterTemplate(
                    name: "Pull",
                    notes: "A heavy hinge followed by vertical and horizontal pulls.",
                    slots: [
                        StarterSlot(area: .back, difficulty: .advanced, preferredNames: ["Deadlifts"], sets: 5, reps: 5, restSeconds: 150),
                        StarterSlot(area: .back, difficulty: .intermediate, preferredNames: ["Pull Ups", "Chin Up"], sets: 4, reps: 8, restSeconds: 120),
                        StarterSlot(area: .back, difficulty: .intermediate, preferredNames: ["Bent Over Rowing"], sets: 4, reps: 8, restSeconds: 90),
                        StarterSlot(area: .arms, difficulty: .intermediate, preferredNames: ["Biceps Curls With Barbell"], sets: 3, reps: 10, restSeconds: 60),
                    ]
                ),
                StarterTemplate(
                    name: "Legs",
                    notes: "Squat heavy, then single-leg work, calves and core.",
                    slots: [
                        StarterSlot(area: .legs, difficulty: .intermediate, preferredNames: ["Barbell Squat", "Barbell Hack Squats"], sets: 5, reps: 5, restSeconds: 150),
                        StarterSlot(area: .legs, difficulty: .advanced, preferredNames: ["Pistol Squat"], sets: 3, reps: 6, restSeconds: 120),
                        StarterSlot(area: .legs, difficulty: .intermediate, preferredNames: ["Barbell Lunges Standing"], sets: 3, reps: 10, restSeconds: 90),
                        StarterSlot(area: .calves, difficulty: .beginner, preferredNames: ["Calf Raises"], sets: 4, reps: 15, restSeconds: 60),
                        StarterSlot(area: .abs, difficulty: .intermediate, preferredNames: ["Hanging Leg Raises"], sets: 3, reps: 12, restSeconds: 60),
                    ]
                ),
            ]
        }
    }

    static func summary(for level: FitnessLevel) -> String {
        templates(for: level).map(\.name).joined(separator: " · ")
    }

    static func routines(for level: FitnessLevel, catalog: [Exercise], ownerID: String, now: Date = .now) -> [Routine] {
        let items = CatalogGrouping.items(from: catalog)
        return templates(for: level).compactMap { template in
            var used = Set<Int>()
            let exercises = template.slots.compactMap { slot -> RoutineExercise? in
                guard let item = pick(slot, from: items, excluding: used) else {
                    return nil
                }
                used.insert(item.id)
                return RoutineExercise(
                    id: UUID(),
                    exerciseID: item.exercise.id,
                    exerciseName: item.exercise.name,
                    plannedSets: slot.sets,
                    plannedReps: slot.reps,
                    plannedLoad: item.exercise.suggestedLoad,
                    restSeconds: slot.restSeconds
                )
            }
            guard !exercises.isEmpty else {
                return nil
            }
            return Routine(
                id: UUID(),
                ownerID: ownerID,
                name: template.name,
                notes: template.notes,
                exercises: exercises,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    static func pick(_ slot: StarterSlot, from items: [CatalogItem], excluding used: Set<Int>) -> CatalogItem? {
        let available = items.filter { !used.contains($0.id) }
        for name in slot.preferredNames {
            if let match = available.first(where: { $0.exercise.name.caseInsensitiveCompare(name) == .orderedSame }) {
                return match
            }
        }
        let inArea = available
            .filter { $0.area == slot.area }
            .sorted { $0.exercise.name.localizedCaseInsensitiveCompare($1.exercise.name) == .orderedAscending }
        let easier = inArea.filter { $0.difficulty <= slot.difficulty }
        return inArea.first { $0.difficulty == slot.difficulty }
            ?? easier.max { $0.difficulty < $1.difficulty }
            ?? inArea.min { $0.difficulty < $1.difficulty }
    }
}
