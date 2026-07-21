//
//  BucketListAudioLevelProcessor.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// STT의 RMS dB 입력을 무음 종료 판정과 앰비언트 모션 샘플로 함께 변환합니다.
@MainActor
final class BucketListAudioLevelProcessor {
    nonisolated let voiceMotionSamples: AsyncStream<VoiceMotionSampleDTO>

    private let voiceMotionContinuation:
        AsyncStream<VoiceMotionSampleDTO>.Continuation
    private var silenceDetector: BucketListSilenceDetector
    private var voiceMotionAnalyzer: VoiceMotionAnalyzer

    init(silenceDetectionPolicy: BucketListSilenceDetectionPolicy) {
        let stream = AsyncStream.makeStream(
            of: VoiceMotionSampleDTO.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        voiceMotionSamples = stream.stream
        voiceMotionContinuation = stream.continuation
        silenceDetector = BucketListSilenceDetector(
            policy: silenceDetectionPolicy
        )
        voiceMotionAnalyzer = VoiceMotionAnalyzer()
    }

    deinit {
        voiceMotionContinuation.finish()
    }

    /// 음성 모션을 전달하고 무음 자동 종료 조건의 충족 여부를 반환합니다.
    func process(
        rmsDecibels: Float,
        duration: TimeInterval
    ) -> Bool {
        voiceMotionContinuation.yield(
            voiceMotionAnalyzer.process(
                rmsDecibels: rmsDecibels,
                duration: duration
            )
        )
        return silenceDetector.process(
            rmsDecibels: rmsDecibels,
            duration: duration
        )
    }

    /// 앰비언트를 정지 위치로 되돌리는 샘플을 전달합니다.
    func publishRestingSample() {
        voiceMotionContinuation.yield(
            VoiceMotionSampleDTO(
                normalizedValue: 0,
                isVoiceActive: false
            )
        )
    }

    /// 무음 판정과 모션 스무딩에 누적된 값을 초기화합니다.
    func reset() {
        silenceDetector.reset()
        voiceMotionAnalyzer.reset()
    }
}
