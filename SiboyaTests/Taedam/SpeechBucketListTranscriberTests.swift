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
}
