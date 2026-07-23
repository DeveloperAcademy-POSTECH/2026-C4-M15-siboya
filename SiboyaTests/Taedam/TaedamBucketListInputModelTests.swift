//
//  TaedamBucketListInputModelTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Testing
@testable import Siboya

@MainActor
struct TaedamBucketListInputModelTests {
    @Test func silenceEventFinishesTranscriptionAndEntersEditing() async {
        let transcriber = MockBucketListTranscriber(
            draft: BucketListDraftDTO(
                rawTranscript: "아이와 바다에 가고 싶어",
                editedText: "아이와 바다에 가고 싶어"
            )
        )
        let model = TaedamBucketListInputModel(transcriber: transcriber)

        await model.start()
        transcriber.sendPartialTranscript("아이와 바다에")
        await waitUntil { model.liveTranscript == "아이와 바다에" }
        transcriber.sendAutomaticEnd(reason: .silence)
        await waitUntil { model.phase == .editing }

        #expect(model.automaticEndReason == .silence)
        #expect(model.draft?.rawTranscript == "아이와 바다에 가고 싶어")
        #expect(model.editedText == "아이와 바다에 가고 싶어")
        #expect(transcriber.finishCallCount == 1)
    }

    @Test func manualFinishEntersEditingWithoutAutomaticReason() async {
        let transcriber = MockBucketListTranscriber(
            draft: BucketListDraftDTO(
                rawTranscript: "아이와 산책하고 싶어",
                editedText: "아이와 산책하고 싶어"
            )
        )
        let model = TaedamBucketListInputModel(transcriber: transcriber)

        await model.start()
        await model.finish()

        #expect(model.phase == .editing)
        #expect(model.automaticEndReason == nil)
        #expect(model.editedText == "아이와 산책하고 싶어")
    }

    @Test func recognitionFailureStillProvidesEmptyEditor() async {
        let transcriber = MockBucketListTranscriber(
            finishError: .recognitionFailed
        )
        let model = TaedamBucketListInputModel(transcriber: transcriber)

        await model.start()
        transcriber.sendAutomaticEnd(reason: .recognitionFailed)
        await waitUntil { model.phase == .editing }

        #expect(model.error == .recognitionFailed)
        #expect(model.draft?.rawTranscript.isEmpty == true)
        #expect(model.editedText.isEmpty)
    }

    @Test func cancelDiscardsDraftAndReturnsToIdle() async {
        let transcriber = MockBucketListTranscriber()
        let model = TaedamBucketListInputModel(transcriber: transcriber)

        await model.start()
        transcriber.sendPartialTranscript("작성 중인 문장")
        await waitUntil { model.liveTranscript == "작성 중인 문장" }
        await model.cancel()

        #expect(model.phase == .idle)
        #expect(model.liveTranscript.isEmpty)
        #expect(model.draft == nil)
        #expect(model.editedText.isEmpty)
        #expect(transcriber.cancelCallCount == 1)
    }

    @Test func startingAgainWhileEditingPreservesEditedText() async {
        let transcriber = MockBucketListTranscriber(
            draft: BucketListDraftDTO(
                rawTranscript: "아이와 산책하고 싶어",
                editedText: "아이와 산책하고 싶어"
            )
        )
        let model = TaedamBucketListInputModel(transcriber: transcriber)

        await model.start()
        await model.finish()
        model.editedText = "아이와 매일 산책하고 싶어"

        await model.start()

        #expect(model.phase == .editing)
        #expect(model.editedText == "아이와 매일 산책하고 싶어")
        #expect(transcriber.startedDurations == [.seconds(20)])
    }

    @Test func sttVoiceMotionIsForwardedWhileTranscribing() async {
        let transcriber = MockBucketListTranscriber()
        let model = TaedamBucketListInputModel(transcriber: transcriber)
        let sample = VoiceMotionSampleDTO(
            normalizedValue: 0.8,
            isVoiceActive: true
        )

        await model.start()
        transcriber.sendVoiceMotion(sample)
        await waitUntil { model.voiceMotionSample == sample }

        #expect(model.voiceMotionSample == sample)
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

@MainActor
private final class MockBucketListTranscriber: BucketListTranscribing {
    nonisolated let partialTranscripts: AsyncStream<String>
    nonisolated let automaticEndEvents:
        AsyncStream<BucketListTranscriptionEndReason>
    nonisolated let voiceMotionSamples: AsyncStream<VoiceMotionSampleDTO>

    private let partialTranscriptContinuation: AsyncStream<String>.Continuation
    private let automaticEndContinuation:
        AsyncStream<BucketListTranscriptionEndReason>.Continuation
    private let voiceMotionContinuation:
        AsyncStream<VoiceMotionSampleDTO>.Continuation
    private let draft: BucketListDraftDTO
    private let finishError: BucketListTranscriptionError?

    private(set) var startedDurations: [Duration] = []
    private(set) var finishCallCount = 0
    private(set) var cancelCallCount = 0

    init(
        draft: BucketListDraftDTO = BucketListDraftDTO(
            rawTranscript: "",
            editedText: ""
        ),
        finishError: BucketListTranscriptionError? = nil
    ) {
        let partialTranscriptStream = AsyncStream.makeStream(
            of: String.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let automaticEndEventStream = AsyncStream.makeStream(
            of: BucketListTranscriptionEndReason.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let voiceMotionSampleStream = AsyncStream.makeStream(
            of: VoiceMotionSampleDTO.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        partialTranscripts = partialTranscriptStream.stream
        partialTranscriptContinuation = partialTranscriptStream.continuation
        automaticEndEvents = automaticEndEventStream.stream
        automaticEndContinuation = automaticEndEventStream.continuation
        voiceMotionSamples = voiceMotionSampleStream.stream
        voiceMotionContinuation = voiceMotionSampleStream.continuation
        self.draft = draft
        self.finishError = finishError
    }

    deinit {
        partialTranscriptContinuation.finish()
        automaticEndContinuation.finish()
        voiceMotionContinuation.finish()
    }

    func start(duration: Duration) async throws {
        startedDurations.append(duration)
    }

    func finish() async throws -> BucketListDraftDTO {
        finishCallCount += 1

        if let finishError {
            throw finishError
        }

        return draft
    }

    func cancel() async {
        cancelCallCount += 1
    }

    func sendPartialTranscript(_ transcript: String) {
        partialTranscriptContinuation.yield(transcript)
    }

    func sendAutomaticEnd(reason: BucketListTranscriptionEndReason) {
        automaticEndContinuation.yield(reason)
    }

    func sendVoiceMotion(_ sample: VoiceMotionSampleDTO) {
        voiceMotionContinuation.yield(sample)
    }
}
