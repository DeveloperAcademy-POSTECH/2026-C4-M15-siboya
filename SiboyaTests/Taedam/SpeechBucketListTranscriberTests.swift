//
//  SpeechBucketListTranscriberTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/21/26.
//

import Foundation
import Testing
@testable import Siboya

@MainActor
struct SpeechBucketListTranscriberTests {
    @Test func authorizationRequiresBothPermissions() {
        let authorized = TaedamSpeechAuthorization(
            microphone: .authorized,
            speechRecognition: .authorized
        )
        let microphoneDenied = TaedamSpeechAuthorization(
            microphone: .denied,
            speechRecognition: .authorized
        )
        let speechDenied = TaedamSpeechAuthorization(
            microphone: .authorized,
            speechRecognition: .denied
        )

        #expect(authorized.isAuthorized)
        #expect(!microphoneDenied.isAuthorized)
        #expect(!speechDenied.isAuthorized)
    }

    @Test func startRejectsNonPositiveDurationBeforeUsingMicrophone() async {
        let transcriber = SpeechBucketListTranscriber()

        await #expect(throws: BucketListTranscriptionError.invalidDuration) {
            try await transcriber.start(duration: .zero)
        }
    }

    @Test func finishBeforeStartThrowsNotTranscribing() async {
        let transcriber = SpeechBucketListTranscriber()

        await #expect(throws: BucketListTranscriptionError.notTranscribing) {
            try await transcriber.finish()
        }
    }

    @Test func cancelBeforeStartIsSafe() async {
        let transcriber = SpeechBucketListTranscriber()
        await transcriber.cancel()

        await #expect(throws: BucketListTranscriptionError.notTranscribing) {
            try await transcriber.finish()
        }
    }

    @Test func silenceBeforeFirstSpeechDoesNotEndInput() {
        var detector = BucketListSilenceDetector(
            policy: BucketListSilenceDetectionPolicy(
                minimumInputDuration: 2,
                trailingSilenceDuration: 1.5
            )
        )

        let didEnd = detector.process(rmsDecibels: -60, duration: 3)

        #expect(!didEnd)
    }

    @Test func silenceAfterSpeechEndsInputAtConfiguredDuration() {
        var detector = BucketListSilenceDetector(
            policy: BucketListSilenceDetectionPolicy(
                minimumInputDuration: 2,
                trailingSilenceDuration: 1.5
            )
        )

        let didEndWhileSpeaking = detector.process(
            rmsDecibels: -35,
            duration: 0.5
        )
        let didEndBeforeLimit = detector.process(
            rmsDecibels: -50,
            duration: 1.4
        )
        let didEndAtLimit = detector.process(
            rmsDecibels: -50,
            duration: 0.1
        )
        let didEndAgain = detector.process(
            rmsDecibels: -50,
            duration: 1
        )

        #expect(!didEndWhileSpeaking)
        #expect(!didEndBeforeLimit)
        #expect(didEndAtLimit)
        #expect(!didEndAgain)
    }

    @Test func resumedSpeechResetsTrailingSilenceDuration() {
        var detector = BucketListSilenceDetector(
            policy: BucketListSilenceDetectionPolicy(
                minimumInputDuration: 0,
                trailingSilenceDuration: 1.5
            )
        )

        let firstSpeech = detector.process(rmsDecibels: -35, duration: 0.2)
        let firstSilence = detector.process(rmsDecibels: -50, duration: 1)
        let resumedSpeech = detector.process(rmsDecibels: -35, duration: 0.2)
        let secondSilence = detector.process(rmsDecibels: -50, duration: 1)
        let completedSilence = detector.process(rmsDecibels: -50, duration: 0.5)

        #expect(!firstSpeech)
        #expect(!firstSilence)
        #expect(!resumedSpeech)
        #expect(!secondSilence)
        #expect(completedSilence)
    }
}
