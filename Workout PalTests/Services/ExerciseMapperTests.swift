import Foundation
import Testing
@testable import Workout_Pal

struct ExerciseMapperTests {
    private func decodedPage() throws -> ExercisePageDTO {
        try WgerClient.decodePage(from: WgerFixtures.page)
    }

    @Test func decodesThePaginationFields() throws {
        let page = try decodedPage()
        #expect(page.count == 2)
        #expect(page.next == nil)
        #expect(page.results.map(\.id) == [73, 74])
    }

    @Test func keepsOnlyExercisesWithAnEnglishTranslation() throws {
        let exercises = try decodedPage().results.compactMap { ExerciseMapper.exercise(from: $0, now: SampleData.now) }
        #expect(exercises.map(\.name) == ["Crunches"])
    }

    @Test func mapsMusclesEquipmentImageAndText() throws {
        let dto = try decodedPage().results[0]
        let exercise = try #require(ExerciseMapper.exercise(from: dto, now: SampleData.now))
        #expect(exercise.category == "Abs")
        #expect(exercise.primaryMuscles == ["Abs"])
        #expect(exercise.secondaryMuscles == ["Obliquus externus abdominis"])
        #expect(exercise.equipment == ["none (bodyweight exercise)"])
        #expect(exercise.summary == "Lie on your back & curl up.")
        #expect(exercise.imageURL?.lastPathComponent == "main.png")
        #expect(exercise.updatedAt == SampleData.now)
    }

    @Test func keepsTheLicenceAttribution() throws {
        let dto = try decodedPage().results[0]
        let exercise = try #require(ExerciseMapper.exercise(from: dto, now: SampleData.now))
        #expect(exercise.license.name == "CC-BY-SA 4")
        #expect(exercise.license.author == "wger.de")
        #expect(exercise.license.attribution == "wger.de, CC-BY-SA 4")
        #expect(exercise.license.url != nil)
    }

    @Test func rejectsAResponseWithoutResults() {
        #expect(throws: DecodingError.self) {
            try WgerClient.decodePage(from: Data("{\"count\": 0}".utf8))
        }
    }
}
