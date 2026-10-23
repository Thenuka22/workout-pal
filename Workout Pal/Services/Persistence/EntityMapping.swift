import CoreData
import Foundation

enum EntityMapping {
    static func split(_ joined: String) -> [String] {
        joined.split(separator: "|").map(String.init)
    }

    static func join(_ values: [String]) -> String {
        values.joined(separator: "|")
    }

    static func load(isBodyweight: Bool, kilograms: Double) -> Load {
        isBodyweight ? .bodyweight : .kilograms(kilograms)
    }

    static func data(from pauses: [PauseInterval]) -> Data? {
        guard !pauses.isEmpty else {
            return nil
        }
        return try? JSONEncoder().encode(pauses)
    }

    static func pauses(from data: Data?) -> [PauseInterval] {
        guard let data else {
            return []
        }
        return (try? JSONDecoder().decode([PauseInterval].self, from: data)) ?? []
    }
}

extension ExerciseEntity {
    func toExercise() -> Exercise {
        Exercise(
            id: Int(id),
            uuid: uuid,
            name: name,
            summary: summary,
            category: category,
            primaryMuscles: EntityMapping.split(primaryMuscles),
            secondaryMuscles: EntityMapping.split(secondaryMuscles),
            equipment: EntityMapping.split(equipment),
            imageURL: imageURL.flatMap { URL(string: $0) },
            license: ContentLicense(
                name: licenseName,
                url: licenseURL.flatMap { URL(string: $0) },
                author: licenseAuthor
            ),
            updatedAt: updatedAt
        )
    }

    func apply(_ exercise: Exercise) {
        id = Int64(exercise.id)
        uuid = exercise.uuid
        name = exercise.name
        summary = exercise.summary
        category = exercise.category
        primaryMuscles = EntityMapping.join(exercise.primaryMuscles)
        secondaryMuscles = EntityMapping.join(exercise.secondaryMuscles)
        equipment = EntityMapping.join(exercise.equipment)
        imageURL = exercise.imageURL?.absoluteString
        licenseName = exercise.license.name
        licenseURL = exercise.license.url?.absoluteString
        licenseAuthor = exercise.license.author
        updatedAt = exercise.updatedAt
    }
}

extension RoutineEntity {
    func toRoutine() -> Routine {
        let items = (exercises as? Set<RoutineExerciseEntity> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.toRoutineExercise() }
        return Routine(
            id: id,
            ownerID: ownerID,
            name: name,
            notes: notes,
            exercises: items,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(_ routine: Routine, in context: NSManagedObjectContext) {
        id = routine.id
        ownerID = routine.ownerID
        name = routine.name
        notes = routine.notes
        createdAt = routine.createdAt
        updatedAt = routine.updatedAt
        if let existing = exercises as? Set<RoutineExerciseEntity> {
            for entity in existing {
                context.delete(entity)
            }
        }
        for (index, item) in routine.exercises.enumerated() {
            let entity = RoutineExerciseEntity(context: context)
            entity.apply(item, sortOrder: index)
            entity.routine = self
        }
    }
}

extension RoutineExerciseEntity {
    func toRoutineExercise() -> RoutineExercise {
        RoutineExercise(
            id: id,
            exerciseID: Int(exerciseID),
            exerciseName: exerciseName,
            plannedSets: Int(plannedSets),
            plannedReps: Int(plannedReps),
            plannedLoad: EntityMapping.load(isBodyweight: isBodyweight, kilograms: plannedLoadKilograms),
            restSeconds: Int(restSeconds)
        )
    }

    func apply(_ item: RoutineExercise, sortOrder order: Int) {
        id = item.id
        exerciseID = Int64(item.exerciseID)
        exerciseName = item.exerciseName
        sortOrder = Int16(order)
        plannedSets = Int16(item.plannedSets)
        plannedReps = Int16(item.plannedReps)
        plannedLoadKilograms = item.plannedLoad.kilograms ?? 0
        isBodyweight = item.plannedLoad.isBodyweight
        restSeconds = Int16(item.restSeconds)
    }
}

extension WorkoutSessionEntity {
    func toSession() -> WorkoutSession {
        let items = (exercises as? Set<SessionExerciseEntity> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.toSessionExercise() }
        return WorkoutSession(
            id: id,
            ownerID: ownerID,
            routineID: routineID,
            routineName: routineName,
            startedAt: startedAt,
            endedAt: endedAt,
            activeSeconds: activeSeconds,
            status: SessionStatus(rawValue: status) ?? .completed,
            notes: notes,
            exercises: items,
            pauses: EntityMapping.pauses(from: pausesData),
            healthExport: HealthExportStatus(rawValue: healthExportStatus) ?? .notExported
        )
    }

    func apply(_ session: WorkoutSession, in context: NSManagedObjectContext) {
        id = session.id
        ownerID = session.ownerID
        routineID = session.routineID
        routineName = session.routineName
        startedAt = session.startedAt
        endedAt = session.endedAt
        activeSeconds = session.activeSeconds
        status = session.status.rawValue
        notes = session.notes
        pausesData = EntityMapping.data(from: session.pauses)
        healthExportStatus = session.healthExport.rawValue
        if let existing = exercises as? Set<SessionExerciseEntity> {
            for entity in existing {
                context.delete(entity)
            }
        }
        for (index, item) in session.exercises.enumerated() {
            let entity = SessionExerciseEntity(context: context)
            entity.apply(item, sortOrder: index, in: context)
            entity.session = self
        }
    }
}

extension SessionExerciseEntity {
    func toSessionExercise() -> SessionExercise {
        let items = (sets as? Set<WorkoutSetEntity> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.toWorkoutSet() }
        return SessionExercise(
            id: id,
            exerciseID: Int(exerciseID),
            exerciseName: exerciseName,
            restSeconds: Int(restSeconds),
            sets: items
        )
    }

    func apply(_ item: SessionExercise, sortOrder order: Int, in context: NSManagedObjectContext) {
        id = item.id
        exerciseID = Int64(item.exerciseID)
        exerciseName = item.exerciseName
        restSeconds = Int16(item.restSeconds)
        sortOrder = Int16(order)
        for (index, set) in item.sets.enumerated() {
            let entity = WorkoutSetEntity(context: context)
            entity.apply(set, sortOrder: index)
            entity.exercise = self
        }
    }
}

extension WorkoutSetEntity {
    func toWorkoutSet() -> WorkoutSet {
        WorkoutSet(
            id: id,
            reps: Int(reps),
            load: EntityMapping.load(isBodyweight: isBodyweight, kilograms: loadKilograms),
            isCompleted: isCompleted,
            completedAt: completedAt,
            source: SetSource(rawValue: source) ?? .manual
        )
    }

    func apply(_ set: WorkoutSet, sortOrder order: Int) {
        id = set.id
        sortOrder = Int16(order)
        reps = Int16(set.reps)
        loadKilograms = set.load.kilograms ?? 0
        isBodyweight = set.load.isBodyweight
        isCompleted = set.isCompleted
        completedAt = set.completedAt
        source = set.source.rawValue
    }
}

extension ActivitySessionEntity {
    func toActivity() -> ActivitySession {
        ActivitySession(
            id: id,
            ownerID: ownerID,
            kind: ActivityKind(rawValue: kind) ?? .walk,
            status: SessionStatus(rawValue: status) ?? .completed,
            startedAt: startedAt,
            endedAt: endedAt,
            pauses: EntityMapping.pauses(from: pausesData),
            steps: Int(steps),
            distanceMeters: hasDistance ? distanceMeters : nil,
            detectedMotion: detectedMotion.flatMap { DetectedMotion(rawValue: $0) },
            healthExport: HealthExportStatus(rawValue: healthExportStatus) ?? .notExported
        )
    }

    func apply(_ activity: ActivitySession) {
        id = activity.id
        ownerID = activity.ownerID
        kind = activity.kind.rawValue
        status = activity.status.rawValue
        startedAt = activity.startedAt
        endedAt = activity.endedAt
        pausesData = EntityMapping.data(from: activity.pauses)
        steps = Int64(activity.steps)
        distanceMeters = activity.distanceMeters ?? 0
        hasDistance = activity.distanceMeters != nil
        detectedMotion = activity.detectedMotion?.rawValue
        healthExportStatus = activity.healthExport.rawValue
    }
}
