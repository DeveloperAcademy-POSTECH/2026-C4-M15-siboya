//
//  TaedamScreenModelTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/21/26.
//

import Foundation
import Testing
@testable import Siboya

@MainActor
struct TaedamScreenModelTests {
    @Test func sessionInputAddsOneBucketListLineAtTheEnd() {
        let lines = TaedamSessionInputDTO.mock.lines

        #expect(lines.count == TaedamSessionInputDTO.mock.script.sentences.count + 1)
        #expect(lines.last?.kind == .bucketList)
        #expect(lines.last?.text == TaedamSessionInputDTO.mock.script.bucketListPrompt.leadIn)
        #expect(lines.filter { $0.kind == .bucketList }.count == 1)
    }

    @Test func bucketListLeadInIsReadBeforeTranscriptionPhase() async {
        let source = TaedamSessionInputDTO.mock
        let input = TaedamSessionInputDTO(
            script: ScriptPreviewDTO(
                scriptID: source.script.scriptID,
                scriptVersion: source.script.scriptVersion,
                category: source.script.category,
                title: source.script.title,
                targetGestationalWeek: source.script.targetGestationalWeek,
                artworkAssetName: source.script.artworkAssetName,
                estimatedDurationSeconds: source.script.estimatedDurationSeconds,
                sentences: [],
                bucketListPrompt: source.script.bucketListPrompt,
                bucketListGuide: source.script.bucketListGuide
            ),
            babyNickname: source.babyNickname
        )
        let model = TaedamScreenModel(
            input: input,
            timingPolicy: TaedamTimingPolicy(countdownSeconds: 0),
            sleeper: HoldingTaedamSleeper()
        )

        model.start()
        await waitUntil { model.phase == .readingBucketListPrompt }

        #expect(model.currentLineIndex == model.bucketListIndex)
        #expect(model.currentLineProgress == 0)

        model.cancel()
    }

    @Test func flowAutomaticallyReachesBucketList() async {
        let model = TaedamScreenModel(
            input: .mock,
            timingPolicy: TaedamTimingPolicy(
                countdownSeconds: 0,
                charactersPerSecond: 1_000,
                minimumDurationSeconds: 0,
                maximumDurationSeconds: 0,
                progressUpdatesPerSecond: 1
            ),
            sleeper: YieldingTaedamSleeper()
        )

        model.start()
        await waitUntil { model.phase == .bucketList }

        #expect(model.phase == .bucketList)
        #expect(model.currentLineIndex == model.bucketListIndex)
        #expect(model.currentLineProgress == 1)
    }

    @Test func selectingPreviousOrNextLineRestartsFromThatLine() async {
        let model = TaedamScreenModel(
            input: .mock,
            timingPolicy: TaedamTimingPolicy(countdownSeconds: 0),
            sleeper: HoldingTaedamSleeper()
        )

        model.start()
        await waitUntil { model.phase == .readingScript(index: 0) }

        #expect(model.isLineSelectable(at: 2))
        model.selectLine(at: 2)
        await waitUntil { model.phase == .readingScript(index: 2) }

        #expect(model.currentLineIndex == 2)
        #expect(model.currentLineProgress == 0)
        #expect(model.isLineSelectable(at: 0))

        model.selectLine(at: 0)
        await waitUntil { model.phase == .readingScript(index: 0) }

        #expect(model.currentLineIndex == 0)
        #expect(model.currentLineProgress == 0)
        #expect(
            model.bucketListIndex.map {
                model.isLineSelectable(at: $0)
            } == false
        )

        model.cancel()
    }

    @Test func bucketListStateAllowsRestartingFromScriptLine() async {
        let sleeper = ControllableTaedamSleeper()
        let model = TaedamScreenModel(
            input: .mock,
            timingPolicy: TaedamTimingPolicy(
                countdownSeconds: 0,
                charactersPerSecond: 1_000,
                minimumDurationSeconds: 0,
                maximumDurationSeconds: 0,
                progressUpdatesPerSecond: 1
            ),
            sleeper: sleeper
        )

        model.start()
        await waitUntil { model.phase == .bucketList }
        await sleeper.holdFutureSleeps()

        #expect(model.isLineSelectable(at: 2))
        model.selectLine(at: 2)
        await waitUntil { model.phase == .readingScript(index: 2) }

        #expect(model.currentLineIndex == 2)
        #expect(model.currentLineProgress == 0)

        model.cancel()
    }

    private func waitUntil(
        _ condition: @MainActor () -> Bool
    ) async {
        for _ in 0..<200 {
            if condition() {
                return
            }

            await Task.yield()
        }
    }
}

private struct YieldingTaedamSleeper: TaedamSleeping {
    func sleep(for duration: Duration) async throws {
        await Task.yield()
        try Task.checkCancellation()
    }
}

private struct HoldingTaedamSleeper: TaedamSleeping {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: .seconds(60))
    }
}

private actor ControllableTaedamSleeper: TaedamSleeping {
    private var shouldHold = false

    func holdFutureSleeps() {
        shouldHold = true
    }

    func sleep(for duration: Duration) async throws {
        if shouldHold {
            try await Task.sleep(for: .seconds(60))
        } else {
            await Task.yield()
            try Task.checkCancellation()
        }
    }
}
