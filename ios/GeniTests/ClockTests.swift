import Foundation
import Testing
@testable import Geni

@MainActor
struct ClockTests {
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private let formats: [ExerciseFormat] = [.clockRead, .clockSet]

    @Test func handAnglesIncludeMinuteOffset() {
        for hour in 0..<12 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                #expect(abs(time.hourAngle - (Double(hour) * 30 + Double(minute) * 0.5)) < 0.0001)
                #expect(time.minuteAngle == Double(minute) * 6)
                #expect(time.settingHour(angle: time.hourAngle) == time)
            }
        }
        #expect(ClockTime(hour: 3, minute: 30).hourAngle == 105)
        #expect(ClockTime(hour: 12, minute: 0).hourAngle == 0)
        #expect(ClockTime(hour: 11, minute: 59).hourAngle == 359.5)
    }

    @Test func digitalTimesUseTwelveHourClockInEveryLanguage() {
        #expect(ClockTime(hour: 0, minute: 0).digital == "12:00")
        #expect(ClockTime(hour: 15, minute: 5).digital == "3:05")
        #expect(ClockTime(hour: 3, minute: 30).digital == "3:30")
        #expect(ClockTime(totalMinutes: -1).digital == "11:59")
        let keys: [LocaleKey] = [.clockRead, .clockSet, .clockMatch, .clockCheck, .clockHourHand, .clockMinuteHand]
        for language in AppLanguage.allCases {
            for key in keys { #expect(!L.s(key, lang: language).isEmpty) }
        }
    }

    @Test func distractorsAreUniqueAndNeverTheAnswer() {
        for step in [60, 30, 15, 5, 1] {
            for minute in stride(from: 0, to: 720, by: step) {
                let time = ClockTime(totalMinutes: minute)
                for _ in 0..<5 {
                    let options = ClockRules.options(for: time, step: step)
                    #expect(options.count == 4)
                    #expect(Set(options).count == 4)
                    #expect(options.filter { $0 == minute }.count == 1)
                    #expect(options.filter { $0 != minute }.count == 3)
                    #expect(options.allSatisfy { (0..<720).contains($0) && $0 % step == 0 })
                }
            }
        }
    }

    @Test func exactAgeDeterminesMinuteSteps() {
        let expected = [6: [60, 30, 30, 30], 7: [30, 15, 5, 5], 8: [30, 15, 5, 5],
                        9: [5, 5, 5, 1], 10: [5, 5, 5, 1]]
        for (age, steps) in expected {
            for (difficulty, step) in zip(difficulties, steps) {
                #expect(ClockRules.minuteStep(age: age, difficulty: difficulty) == step)
                for format in formats {
                    let exercise = ExerciseGenerator.generateClockExercise(format: format, age: age, difficulty: difficulty)
                    let formatStep = age == 6 && format == .clockSet ? 60 : step
                    #expect(exercise.clockMinuteStep == formatStep)
                    #expect(exercise.clockTimes?.allSatisfy { $0.totalMinutes % formatStep == 0 } == true)
                }
            }
        }
    }

    @Test func childrenUnderSixNeverGetClockFormats() {
        for age in 4...5 {
            let profile = ChildProfile(nickname: "Young", age: age, avatarId: "lion")
            #expect(!MathTopic.timeAndCalendar.formats(for: age).contains { $0.isClock })
            for difficulty in difficulties {
                #expect(ClockRules.minuteStep(age: age, difficulty: difficulty) == nil)
                for format in formats {
                    #expect(!ExerciseGenerator.generateClockExercise(format: format, age: age, difficulty: difficulty).format.isClock)
                }
            }
            for _ in 0..<10 {
                #expect(!ExerciseGenerator.generateTopicChapter(profile: profile, topic: .timeAndCalendar).contains { $0.format.isClock })
                #expect(!ExerciseGenerator.generateChapter(profile: profile).contains { $0.format.isClock })
            }
        }
    }

    @Test func timeChaptersAreCompleteAndClockPairsAreValid() throws {
        for age in 6...10 {
            let profile = ChildProfile(nickname: "Clock", age: age, avatarId: "lion")
            for _ in 0..<20 {
                let exercises = ExerciseGenerator.generateTopicChapter(profile: profile, topic: .timeAndCalendar)
                #expect(exercises.count == 20)
                #expect(exercises.filter { $0.format.isClock }.count == 16)
                #expect(Set(exercises.map(\.format)).isSuperset(of: formats))
                for exercise in exercises {
                    #expect(!exercise.options.isEmpty)
                    #expect(exercise.difficulty == ExerciseDifficulty.forIndex(exercises.firstIndex { $0.id == exercise.id }!))
                    guard exercise.format.isClock else { continue }
                    let times = try #require(exercise.clockTimes)
                    #expect(!times.isEmpty)
                    #expect(Set(times).count == times.count)
                    #expect(times.allSatisfy { $0.totalMinutes % exercise.clockMinuteStep == 0 })
                    if age == 6 && exercise.format == .clockSet {
                        #expect(times.allSatisfy { $0.minute == 0 })
                        #expect(exercise.difficulty == .warmup)
                    }
                    #expect(exercise.format != .clockMatch)
                    #expect(exercise.options.contains(exercise.correctAnswer))
                }
            }
        }
    }

    @Test func generatedChaptersNeverContainClockMatch() {
        for age in [6, 7, 9] {
            let profile = ChildProfile(nickname: "Clock", age: age, avatarId: "lion")
            for _ in 0..<20 {
                #expect(!ExerciseGenerator.generateChapter(profile: profile).contains { $0.format == .clockMatch })
                #expect(!ExerciseGenerator.generateTopicChapter(profile: profile, topic: .timeAndCalendar).contains { $0.format == .clockMatch })
            }
        }
    }

    @Test func formatsRemainCodableAndOldRawValuesDecode() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for format in formats + [.clockMatch, .solveResult, .matchConnect, .trueFalse, .multiStep] {
            #expect(try decoder.decode(ExerciseFormat.self, from: encoder.encode(format)) == format)
        }
        #expect(try decoder.decode(ExerciseFormat.self, from: Data("\"solveResult\"".utf8)) == .solveResult)
        #expect(try decoder.decode(ExerciseFormat.self, from: Data("\"matchConnect\"".utf8)) == .matchConnect)
    }

    @Test func draggedHandsSnapAndKeepRealisticHourPosition() {
        let time = ClockTime(hour: 3, minute: 0)
        #expect(time.settingMinute(angle: 176, step: 5) == ClockTime(hour: 3, minute: 30))
        #expect(time.settingMinute(angle: 176, step: 5).hourAngle == 105)
        #expect(time.settingMinute(angle: 354, step: 5) == time)
        #expect(time.settingMinute(angle: -90, step: 15) == ClockTime(hour: 3, minute: 45))
        #expect(time.settingMinute(angle: 90, step: 60).minute == 0)
        #expect(ClockTime(hour: 3, minute: 30).settingHour(angle: 125) == ClockTime(hour: 4, minute: 30))
        #expect(ClockTime(hour: 11, minute: 59).snapped(to: 5) == ClockTime(hour: 12, minute: 0))
    }

    private func viewModel(_ exercise: Exercise) -> ChapterViewModel {
        let profile = ChildProfile(nickname: "Clock", age: 8, avatarId: "lion")
        return ChapterViewModel(profile: profile, chapter: ChapterProgress(childId: profile.id, date: "2026-10-25"), exercises: [exercise])
    }

    @Test func clockSetChecksSnappedTimeAndRecordsFirstAttempt() throws {
        let suite = "geni.clock-tests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = PersistenceService(defaults: defaults)
        let exercise = Exercise(clockFormat: .clockSet, times: [ClockTime(hour: 3, minute: 30)], minuteStep: 5, difficulty: .harder)
        let vm = viewModel(exercise)
        vm.submitClockTime(ClockTime(hour: 3, minute: 28), persistence: persistence)
        let result = try #require(vm.chapter.exerciseResults.first)
        #expect(result.firstAttemptCorrect)
        #expect(result.attemptsUsed == 1)
        #expect(vm.feedbackCorrect)
        #expect(vm.isAwaitingAdvance)
        vm.submitClockTime(ClockTime(hour: 3, minute: 30), persistence: persistence)
        #expect(vm.chapter.exerciseResults.count == 1)
    }

    @Test func clockSetWrongAnswersRevealDigitalTime() throws {
        let suite = "geni.clock-tests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = PersistenceService(defaults: defaults)
        let exercise = Exercise(clockFormat: .clockSet, times: [ClockTime(hour: 3, minute: 30)], minuteStep: 5, difficulty: .harder)
        let vm = viewModel(exercise)
        vm.submitClockTime(ClockTime(hour: 3, minute: 20), persistence: persistence)
        #expect(vm.attempts == 1)
        #expect(vm.chapter.exerciseResults.isEmpty)
        vm.showFeedback = false
        vm.submitClockTime(ClockTime(hour: 4, minute: 30), persistence: persistence)
        #expect(vm.feedbackMessage == "3:30")
        #expect(vm.showAnswer)
        #expect(vm.chapter.exerciseResults.first?.attemptsUsed == 2)
        #expect(vm.chapter.exerciseResults.first?.wasCorrect == false)
    }

    @Test func clockReadAndMatchingUseNormalResultRecording() throws {
        let suite = "geni.clock-tests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = PersistenceService(defaults: defaults)
        let read = ExerciseGenerator.generateClockExercise(format: .clockRead, age: 7, difficulty: .normal)
        let readVM = viewModel(read)
        readVM.submitAnswer(read.correctAnswer, persistence: persistence)
        #expect(readVM.chapter.exerciseResults.first?.firstAttemptCorrect == true)
        let match = ExerciseGenerator.generateClockExercise(format: .clockMatch, age: 7, difficulty: .normal)
        let matchVM = viewModel(match)
        let indices = try #require(match.correctMatchIndices)
        matchVM.submitMatch(leftIndex: 0, rightIndex: (indices[0] + 1) % indices.count, pathPoints: [], persistence: persistence)
        for (left, right) in indices.enumerated() { matchVM.submitMatch(leftIndex: left, rightIndex: right, pathPoints: [], persistence: persistence) }
        #expect(matchVM.chapter.exerciseResults.first?.firstAttemptCorrect == false)
        #expect(matchVM.chapter.exerciseResults.first?.attemptsUsed == 2)
        #expect(matchVM.chapter.exerciseResults.first?.wasCorrect == true)
    }
}

struct AgeSixDailyClockTests {
    @Test func ageSixDailyChapterIncludesClocks() {
        let profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        let exercises = ExerciseGenerator.generateChapter(profile: profile)
        #expect(exercises.count == 20)
        #expect(exercises[6].format == .clockRead)
        #expect(exercises[14].format == .clockRead)
    }

    @Test func ageFiveDailyChapterHasNoClocks() {
        let profile = ChildProfile(nickname: "Bo", age: 5, avatarId: "lion")
        let clockFormats: Set<ExerciseFormat> = [.clockRead, .clockMatch, .clockSet]
        #expect(ExerciseGenerator.generateChapter(profile: profile).allSatisfy { !clockFormats.contains($0.format) })
    }
}
