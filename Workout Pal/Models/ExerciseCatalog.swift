import Foundation

enum BodyArea: String, CaseIterable, Identifiable, Sendable {
    case abs
    case arms
    case back
    case calves
    case cardio
    case chest
    case legs
    case shoulders
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .abs: "Abs"
        case .arms: "Arms"
        case .back: "Back"
        case .calves: "Calves"
        case .cardio: "Cardio"
        case .chest: "Chest"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .abs: "figure.core.training"
        case .arms: "dumbbell.fill"
        case .back: "figure.rower"
        case .calves: "shoeprints.fill"
        case .cardio: "heart.fill"
        case .chest: "figure.arms.open"
        case .legs: "figure.step.training"
        case .shoulders: "figure.strengthtraining.traditional"
        case .other: "square.grid.2x2.fill"
        }
    }

    init(category: String) {
        let name = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self = BodyArea.allCases.first { area in
            area != .other && area.title.caseInsensitiveCompare(name) == .orderedSame
        } ?? .other
    }
}

enum ExerciseDifficulty: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case beginner
    case intermediate
    case advanced

    static let easierVariantKeywords = ["assisted", "machine", "knee", "band"]
    static let advancedKeywords = [
        "deadlift", "snatch", "clean", "jerk", "muscle up", "muscle-up", "pistol", "handstand",
        "dragon flag", "planche", "front lever", "back lever", "one arm push", "one-arm push",
        "one arm pull", "one-arm pull", "archer", "deficit", "good morning", "overhead squat",
        "weighted", "clap", "plyo",
    ]
    static let intermediateKeywords = [
        "dip", "pull up", "pull-up", "pullup", "chin up", "chin-up", "burpee", "pike", "hanging",
        "toes to bar", "box jump", "jump squat", "jump lunge", "tuck jump",
    ]
    static let beginnerKeywords = [
        "crunch", "plank", "bridge", "wall", "knee", "assisted", "machine", "stretch", "walk", "march",
        "bird dog", "deadbug", "dead bug", "superman", "raise", "calf", "cycling", "jumping jack",
    ]
    static let loadedEquipment = ["barbell", "sz-bar", "dumbbell", "kettlebell", "cable", "pull-up bar"]

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    static func < (lhs: ExerciseDifficulty, rhs: ExerciseDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func estimate(for exercise: Exercise) -> ExerciseDifficulty {
        let name = exercise.name.lowercased()
        if easierVariantKeywords.contains(where: { name.contains($0) }) {
            return .beginner
        }
        if advancedKeywords.contains(where: { name.contains($0) }) {
            return .advanced
        }
        if intermediateKeywords.contains(where: { name.contains($0) }) {
            return .intermediate
        }
        if beginnerKeywords.contains(where: { name.contains($0) }) {
            return .beginner
        }
        let equipment = exercise.equipment.map { $0.lowercased() }
        let usesLoad = equipment.contains { item in
            loadedEquipment.contains { item.contains($0) }
        }
        return usesLoad ? .intermediate : .beginner
    }
}

extension FitnessLevel {
    var suitedDifficulties: Set<ExerciseDifficulty> {
        switch self {
        case .beginner: [.beginner]
        case .intermediate: [.beginner, .intermediate]
        case .advanced: Set(ExerciseDifficulty.allCases)
        }
    }
}

struct CatalogItem: Identifiable, Hashable, Sendable {
    let exercise: Exercise
    let area: BodyArea
    let difficulty: ExerciseDifficulty

    init(exercise: Exercise) {
        self.exercise = exercise
        area = BodyArea(category: exercise.category)
        difficulty = ExerciseDifficulty.estimate(for: exercise)
    }

    var id: Int { exercise.id }
}

struct ExerciseSection: Identifiable, Hashable, Sendable {
    let area: BodyArea
    let items: [CatalogItem]

    var id: BodyArea { area }
}

enum LibraryScope: Hashable, Identifiable, Sendable {
    case forYou
    case all
    case area(BodyArea)

    var id: String {
        switch self {
        case .forYou: "forYou"
        case .all: "all"
        case .area(let area): area.rawValue
        }
    }

    var title: String {
        switch self {
        case .forYou: "For you"
        case .all: "All"
        case .area(let area): area.title
        }
    }
}

enum CatalogGrouping {
    static func items(from exercises: [Exercise]) -> [CatalogItem] {
        exercises.map { CatalogItem(exercise: $0) }
    }

    static func scopes(for items: [CatalogItem]) -> [LibraryScope] {
        let present = Set(items.map(\.area))
        let areas: [LibraryScope] = BodyArea.allCases.filter { present.contains($0) }.map { .area($0) }
        return [.forYou, .all] + areas
    }

    static func matches(_ exercise: Exercise, query: String, muscle: String?, equipment: String?) -> Bool {
        if let muscle, !exercise.primaryMuscles.contains(muscle) {
            return false
        }
        if let equipment, !exercise.equipment.contains(equipment) {
            return false
        }
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if search.isEmpty {
            return true
        }
        return exercise.name.lowercased().contains(search)
            || exercise.category.lowercased().contains(search)
            || exercise.primaryMuscles.contains { $0.lowercased().contains(search) }
    }

    static func sections(
        items: [CatalogItem],
        scope: LibraryScope,
        difficulty: ExerciseDifficulty?,
        query: String,
        muscle: String? = nil,
        equipment: String? = nil,
        fitnessLevel: FitnessLevel?
    ) -> [ExerciseSection] {
        let suited = fitnessLevel?.suitedDifficulties ?? Set(ExerciseDifficulty.allCases)
        let visible = items.filter { item in
            guard matches(item.exercise, query: query, muscle: muscle, equipment: equipment) else {
                return false
            }
            if let difficulty {
                guard item.difficulty == difficulty else {
                    return false
                }
            }
            switch scope {
            case .all:
                return true
            case .forYou:
                return difficulty != nil || suited.contains(item.difficulty)
            case .area(let area):
                return item.area == area
            }
        }
        let grouped = Dictionary(grouping: visible) { $0.area }
        return BodyArea.allCases.compactMap { area in
            guard let items = grouped[area], !items.isEmpty else {
                return nil
            }
            let sorted = items.sorted { lhs, rhs in
                if lhs.difficulty != rhs.difficulty {
                    return lhs.difficulty < rhs.difficulty
                }
                return lhs.exercise.name.localizedCaseInsensitiveCompare(rhs.exercise.name) == .orderedAscending
            }
            return ExerciseSection(area: area, items: sorted)
        }
    }
}
