//
//  VoiceMotionAnalyzerTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Testing
@testable import Siboya

struct VoiceMotionAnalyzerTests {
    @Test func loudInputRaisesNormalizedMotionAndActivatesVoice() {
        var analyzer = VoiceMotionAnalyzer()

        let sample = analyzer.process(
            rmsDecibels: -20,
            duration: 0.02
        )

        #expect(sample.normalizedValue > 0)
        #expect(sample.normalizedValue <= 1)
        #expect(sample.isVoiceActive)
    }

    @Test func motionRisesFasterThanItFalls() {
        let policy = VoiceMotionAnalysisPolicy(
            risingSmoothingFactor: 0.35,
            fallingSmoothingFactor: 0.12
        )
        var analyzer = VoiceMotionAnalyzer(policy: policy)

        let risingSample = analyzer.process(
            rmsDecibels: -15,
            duration: 0.02
        )
        let fallingSample = analyzer.process(
            rmsDecibels: -55,
            duration: 0.02
        )

        #expect(risingSample.normalizedValue > 0)
        #expect(fallingSample.normalizedValue > 0)
        #expect(fallingSample.normalizedValue < risingSample.normalizedValue)
    }

    @Test func voiceDeactivatesOnlyAfterLowInputDelay() {
        var analyzer = VoiceMotionAnalyzer(
            policy: VoiceMotionAnalysisPolicy(deactivationDelay: 0.25)
        )

        _ = analyzer.process(rmsDecibels: -20, duration: 0.02)
        let shortSilence = analyzer.process(
            rmsDecibels: -60,
            duration: 0.2
        )
        let completedSilence = analyzer.process(
            rmsDecibels: -60,
            duration: 0.05
        )

        #expect(shortSilence.isVoiceActive)
        #expect(!completedSilence.isVoiceActive)
    }

    @Test func resetReturnsAnalyzerToInactiveBaseline() {
        var analyzer = VoiceMotionAnalyzer()

        _ = analyzer.process(rmsDecibels: -15, duration: 0.1)
        analyzer.reset()
        let sample = analyzer.process(rmsDecibels: -.infinity, duration: 0.02)

        #expect(sample.normalizedValue == 0)
        #expect(!sample.isVoiceActive)
    }
}
