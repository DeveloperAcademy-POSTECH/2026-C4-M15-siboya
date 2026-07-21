//
//  BucketListSilenceDetector.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// 버킷리스트 STT에서 발화 시작과 연속 무음을 판정할 때 사용하는 정책입니다.
struct BucketListSilenceDetectionPolicy: Equatable, Sendable {
    /// STT 시작 후 자동 종료를 허용하기 전까지 확보할 최소 입력 시간입니다.
    let minimumInputDuration: TimeInterval

    /// 최초 발화 이후 자동 종료로 판정할 연속 무음 시간입니다.
    let trailingSilenceDuration: TimeInterval

    /// 비활성 상태에서 발화가 시작됐다고 판단하는 음량입니다.
    let speechThresholdDecibels: Float

    /// 활성 상태에서 발화가 끝났다고 판단하는 음량입니다.
    let silenceThresholdDecibels: Float

    nonisolated init(
        minimumInputDuration: TimeInterval = 2,
        trailingSilenceDuration: TimeInterval = 1.5,
        speechThresholdDecibels: Float = -40,
        silenceThresholdDecibels: Float = -45
    ) {
        self.minimumInputDuration = max(0, minimumInputDuration)
        self.trailingSilenceDuration = max(0, trailingSilenceDuration)
        self.speechThresholdDecibels = speechThresholdDecibels
        self.silenceThresholdDecibels = min(
            speechThresholdDecibels,
            silenceThresholdDecibels
        )
    }
}

/// 연속된 오디오 버퍼의 음량을 받아 발화 후 무음 종료 시점을 계산합니다.
///
/// 발화를 한 번도 감지하지 못한 경우에는 무음 종료를 발생시키지 않습니다. 두 임계값 사이에서는
/// 직전 음성 활성 상태를 유지하는 hysteresis를 적용해 경계 음량에서 상태가 반복해서 바뀌는 것을 줄입니다.
struct BucketListSilenceDetector: Sendable {
    private let policy: BucketListSilenceDetectionPolicy

    private var totalInputDuration: TimeInterval = 0
    private var trailingSilenceDuration: TimeInterval = 0
    private var hasDetectedSpeech = false
    private var isSpeechActive = false
    private var hasDetectedEnd = false

    nonisolated init(policy: BucketListSilenceDetectionPolicy = .init()) {
        self.policy = policy
    }

    /// 새 오디오 구간을 반영하고 자동 종료 조건을 처음 만족한 순간에만 `true`를 반환합니다.
    nonisolated mutating func process(
        rmsDecibels: Float,
        duration: TimeInterval
    ) -> Bool {
        guard !hasDetectedEnd else { return false }

        let duration = max(0, duration)
        totalInputDuration += duration
        updateSpeechActivity(rmsDecibels: rmsDecibels)

        guard hasDetectedSpeech else { return false }

        if isSpeechActive {
            trailingSilenceDuration = 0
        } else {
            trailingSilenceDuration += duration
        }

        guard totalInputDuration >= policy.minimumInputDuration,
              trailingSilenceDuration >= policy.trailingSilenceDuration else {
            return false
        }

        hasDetectedEnd = true
        return true
    }

    nonisolated mutating func reset() {
        totalInputDuration = 0
        trailingSilenceDuration = 0
        hasDetectedSpeech = false
        isSpeechActive = false
        hasDetectedEnd = false
    }

    private nonisolated mutating func updateSpeechActivity(rmsDecibels: Float) {
        if isSpeechActive {
            if rmsDecibels <= policy.silenceThresholdDecibels {
                isSpeechActive = false
            }
        } else if rmsDecibels >= policy.speechThresholdDecibels {
            isSpeechActive = true
            hasDetectedSpeech = true
        }
    }
}
