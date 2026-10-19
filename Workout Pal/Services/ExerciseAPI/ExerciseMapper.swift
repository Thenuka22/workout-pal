import Foundation

enum ExerciseMapper {
    static let englishLanguageID = 2

    static func exercise(from dto: ExerciseInfoDTO, now: Date) -> Exercise? {
        guard let translation = dto.translations?.first(where: { $0.language == englishLanguageID }) else {
            return nil
        }
        let name = translation.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }
        let images = dto.images ?? []
        let mainImage = images.first(where: { $0.isMain == true }) ?? images.first
        return Exercise(
            id: dto.id,
            uuid: dto.uuid ?? "",
            name: name,
            summary: HTMLText.plainText(from: translation.description ?? ""),
            category: dto.category?.name ?? "",
            primaryMuscles: (dto.muscles ?? []).map(muscleName),
            secondaryMuscles: (dto.musclesSecondary ?? []).map(muscleName),
            equipment: (dto.equipment ?? []).map(\.name),
            imageURL: mainImage.flatMap { URL(string: $0.image) },
            license: ContentLicense(
                name: dto.license?.shortName ?? "",
                url: dto.license?.url.flatMap { URL(string: $0) },
                author: dto.licenseAuthor ?? ""
            ),
            updatedAt: now
        )
    }

    private static func muscleName(_ muscle: MuscleDTO) -> String {
        if let english = muscle.nameEn, !english.isEmpty {
            return english
        }
        return muscle.name
    }
}
