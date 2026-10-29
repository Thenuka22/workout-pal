import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct ProgressHomeViewModelTests {
    private let health = FakeHealthService()
    private let permissions = FakePermissions()

    private func makeModel(
        sessions: [WorkoutSession] = [],
        activities: [ActivitySession] = []
    ) -> ProgressHomeViewModel {
        ProgressHomeViewModel(
            repository: InMemoryWorkoutSessionRepository(sessions),
            activityRepository: InMemoryActivitySessionRepository(activities),
            health: health,
            permissions: permissions,
            settings: AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID),
            now: { SampleData.now },
            calendar: SampleData.calendar
        )
    }

    @Test func historyMixesWorkoutsAndWalks() async {
        let model = makeModel(
            sessions: [SampleData.session(startedAt: SampleData.daysAgo(1))],
            activities: [SampleData.activity(startedAt: SampleData.now)]
        )
        await model.load()
        #expect(model.hasHistory)
        #expect(model.subtitle == "2 sessions logged so far.")
        #expect(model.historyGroups.first?.entries.first?.title == "Walk")
    }

    @Test func todayMinutesCountBothKindsOfSession() async {
        let model = makeModel(
            sessions: [SampleData.session(startedAt: SampleData.now, minutes: 30), SampleData.session(startedAt: SampleData.daysAgo(2), minutes: 50)],
            activities: [SampleData.activity(startedAt: SampleData.now, minutes: 12)]
        )
        await model.load()
        #expect(model.todayActiveMinutes == 42)
    }

    @Test func theRangeLimitsTheExerciseChartButNotRecords() async {
        let recent = SampleData.session(
            startedAt: SampleData.daysAgo(3),
            exercises: [SampleData.exercise(sets: [SampleData.set(load: .kilograms(40))])]
        )
        let old = SampleData.session(
            startedAt: SampleData.daysAgo(60),
            exercises: [SampleData.exercise(sets: [SampleData.set(load: .kilograms(60))])]
        )
        let model = makeModel(sessions: [recent, old])
        await model.load()
        model.range = .fourWeeks
        #expect(model.exerciseChartPoints.map(\.value) == [40])
        #expect(model.exerciseSummary == "Squats: best load 40 kg across 1 workout in the last 4 weeks, latest 40 kg.")
        model.range = .twelveWeeks
        #expect(model.exerciseChartPoints.map(\.value) == [60, 40])
        #expect(model.records.first { $0.kind == .heaviestLoad }?.value == 60)
    }

    @Test func theExerciseChartNamesItsUnit() async {
        let model = makeModel(sessions: [SampleData.session(startedAt: SampleData.daysAgo(1))])
        await model.load()
        #expect(model.exerciseChartLabel == "Best load (kg)")
    }

    @Test func anExerciseWithNothingInRangeSaysSo() async {
        let model = makeModel(sessions: [SampleData.session(startedAt: SampleData.daysAgo(60))])
        await model.load()
        model.range = .fourWeeks
        #expect(model.exerciseChartPoints.isEmpty)
        #expect(model.exerciseSummary == "No Squats sets in the last 4 weeks.")
    }

    @Test func theCalendarMovesBackButNotIntoTheFuture() async {
        let model = makeModel(sessions: [SampleData.session(startedAt: SampleData.daysAgo(1))])
        await model.load()
        #expect(!model.canShowNextMonth)
        #expect(model.trainingMonth.trainingDays == 1)
        model.showPreviousMonth()
        #expect(model.canShowNextMonth)
        #expect(model.trainingMonth.trainingDays == 0)
        model.showNextMonth()
        #expect(!model.canShowNextMonth)
        model.showNextMonth()
        #expect(model.trainingMonth.trainingDays == 1)
    }

    @Test func choosingADayFiltersTheHistory() async throws {
        let model = makeModel(
            sessions: [SampleData.session(startedAt: SampleData.daysAgo(1)), SampleData.session(startedAt: SampleData.daysAgo(8))],
            activities: [SampleData.activity(startedAt: SampleData.daysAgo(1))]
        )
        await model.load()
        let yesterday = SampleData.calendar.startOfDay(for: SampleData.daysAgo(1))
        let day = try #require(model.trainingMonth.days.first { $0.date == yesterday })
        #expect(model.accessibilityLabel(for: day).hasSuffix("1 workout, 1 walk or run"))
        model.select(day)
        #expect(model.historyGroups.flatMap(\.entries).count == 2)
        #expect(model.selectedDayTitle != nil)
        model.select(day)
        #expect(model.historyGroups.flatMap(\.entries).count == 3)
        model.select(day)
        model.clearSelectedDay()
        #expect(model.selectedDay == nil)
    }

    @Test func walkTrendsSumTheRange() async {
        let model = makeModel(activities: [
            SampleData.activity(startedAt: SampleData.daysAgo(2), steps: 2_000, distanceMeters: 1_500),
            SampleData.activity(startedAt: SampleData.daysAgo(9), steps: 3_000, distanceMeters: nil),
            SampleData.activity(startedAt: SampleData.daysAgo(120), steps: 9_000),
        ])
        await model.load()
        model.range = .fourWeeks
        #expect(model.totalActivities == 2)
        #expect(model.totalSteps == 5_000)
        #expect(model.totalDistanceMeters == 1_500)
        #expect(model.walksSummary.hasPrefix("2 walks and runs in the last 4 weeks"))
        #expect(model.walksSummary.contains("estimated"))
    }

    @Test func healthIsNotReadUntilConnected() async {
        let model = makeModel()
        await model.loadHealth()
        #expect(model.healthState == .notConnected)
    }

    @Test func connectingLoadsTodaysHealthData() async {
        let model = makeModel()
        model.connectHealth()
        #expect(await eventually {
            if case .loaded(let summary, _) = model.healthState {
                return summary.steps == 6_320
            }
            return false
        })
        #expect(permissions.requested == [.health])
    }

    @Test func devicesWithoutHealthSayItIsUnavailable() async {
        health.isAvailable = false
        let model = makeModel()
        await model.loadHealth()
        #expect(model.healthState == .unavailable)
    }

    @Test func healthErrorsAreShownWithoutBreakingProgress() async {
        permissions.statuses[.health] = .granted
        health.failure = CocoaError(.featureUnsupported)
        let model = makeModel(sessions: [SampleData.session()])
        await model.load()
        await model.loadHealth()
        if case .failed = model.healthState {
            #expect(model.hasHistory)
        } else {
            Issue.record("Expected a failed Health state")
        }
    }

    @Test func stepProgressIsCappedAtTheGoal() {
        let summary = HealthDaySummary(steps: 20_000, distanceMeters: nil, otherWorkouts: [])
        #expect(summary.stepProgress == 1)
        #expect(HealthDaySummary(steps: nil, distanceMeters: nil, otherWorkouts: []).stepProgress == 0)
    }
}
