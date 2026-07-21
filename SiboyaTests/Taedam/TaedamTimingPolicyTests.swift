//
//  TaedamTimingPolicyTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/21/26.
//

import Testing
@testable import Siboya

struct TaedamTimingPolicyTests {
    private let policy = TaedamTimingPolicy()

    @Test func minimumDurationAppliesToShortSentence() {
        #expect(policy.durationSeconds(for: "안녕") == 2.5)
    }

    @Test func durationUsesNonWhitespaceCharacterCount() {
        let durationWithoutSpaces = policy.durationSeconds(for: "가나다라마바사아")
        let durationWithSpaces = policy.durationSeconds(for: "가나 다라 마바 사아")

        #expect(durationWithoutSpaces == durationWithSpaces)
    }

    @Test func maximumDurationCapsLongSentence() {
        let text = String(repeating: "태담", count: 100)

        #expect(policy.durationSeconds(for: text) == 10)
    }

    @Test func progressStepCountIsNeverZero() {
        let zeroDurationPolicy = TaedamTimingPolicy(
            countdownSeconds: 0,
            minimumDurationSeconds: 0,
            maximumDurationSeconds: 0,
            progressUpdatesPerSecond: 1
        )

        #expect(zeroDurationPolicy.progressStepCount(for: "") == 1)
    }
}
