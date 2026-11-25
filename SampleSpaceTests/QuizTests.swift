import Foundation
import Testing
@testable import SampleSpace

@Suite("Quiz progress")
struct QuizProgressTests {
    private let questions = [
        QuizQuestion(prompt: "one", choices: ["a", "b", "c"], answer: 1),
        QuizQuestion(prompt: "two", choices: ["x", "y"], answer: 0),
    ]

    @Test func rightFirstTimeCountsOneAttemptEach() {
        var quiz = QuizProgress(questions: questions)
        #expect(quiz.lockIn() == .ignored, "nothing selected yet")
        quiz.selection = 1
        #expect(quiz.lockIn() == .right)
        #expect(quiz.currentSolved && !quiz.finished)
        quiz.next()
        #expect(quiz.index == 1 && quiz.selection == nil)
        quiz.selection = 0
        #expect(quiz.lockIn() == .right)
        #expect(quiz.finished)
        #expect(quiz.attempts == 2)
    }

    @Test func wrongAnswersAreRememberedAndCount() {
        var quiz = QuizProgress(questions: questions)
        quiz.selection = 0
        #expect(quiz.lockIn() == .wrong)
        #expect(quiz.wrongChoices(0) == [0])
        #expect(quiz.selection == nil)
        quiz.selection = 0
        #expect(quiz.lockIn() == .ignored, "a wrong choice can't be locked in twice")
        quiz.next()
        #expect(quiz.index == 0, "can't move on before answering")
        quiz.selection = 1
        #expect(quiz.lockIn() == .right)
        #expect(quiz.attempts == 2)
    }

    @Test func canOnlyRevisitAnsweredQuestionsAndTheNextOne() {
        var quiz = QuizProgress(questions: questions)
        quiz.go(to: 1)
        #expect(quiz.index == 0)
        quiz.selection = 1
        quiz.lockIn()
        quiz.go(to: 1)
        #expect(quiz.index == 1)
        quiz.go(to: 0)
        #expect(quiz.index == 0 && quiz.selection == 1, "an answered question shows its answer")
    }
}

@Suite("Quiz levels")
@MainActor
struct QuizLevelTests {
    @Test func aPerfectBriefingEarnsThreeStars() throws {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: "launch-pad.reading-the-console"))
        let session = model.session(for: level)
        for (index, question) in (level.quiz ?? []).enumerated() {
            session.select(question.answer)
            session.lockInAnswer()
            if index < (level.quiz?.count ?? 0) - 1 { session.nextQuestion() }
        }
        session.finishQuiz()
        let completion = try #require(session.completion)
        #expect(completion.score.stars == 3)
        #expect(completion.score.criteria[2].text == "Solved in 4 answers (par 4)")
        #expect(model.bestStars(level.id) == 3)
        #expect(model.fuel.practisedToday)
    }

    @Test func aWrongAnswerCostsTheParStar() throws {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: "launch-pad.reading-the-console"))
        let session = model.session(for: level)
        let quiz = try #require(level.quiz)
        for (index, question) in quiz.enumerated() {
            if index == 0 {
                session.select((question.answer + 1) % question.choices.count)
                session.lockInAnswer()
            }
            session.select(question.answer)
            session.lockInAnswer()
            session.nextQuestion()
        }
        session.finishQuiz()
        #expect(session.completion?.score.stars == 2)
        session.replay()
        #expect(session.quiz.attempts == 0 && session.quiz.index == 0)
    }

    @Test func predictRunsTheCodeOnceAnswered() async throws {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: "vector-belt.coercion-forecast"))
        let session = model.session(for: level)
        let first = try #require(level.quiz?.first)
        session.select(first.answer)
        session.lockInAnswer()
        await session.waitForQuizRun()
        let output = try #require(session.quizOutputs[0])
        #expect(output.contains { $0.kind == .output && $0.text.contains("\"TRUE\"") })
    }
}
