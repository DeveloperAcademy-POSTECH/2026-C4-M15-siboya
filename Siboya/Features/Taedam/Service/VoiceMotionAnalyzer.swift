//
//  VoiceMotionAnalyzer.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// 마이크 음량을 배경 모션 값으로 바꾸는 정책입니다.
struct VoiceMotionAnalysisPolicy: Equatable, Sendable {
    let minimumDecibels: Double
    let maximumDecibels: Double
    let risingSmoothingFactor: Double
    let fallingSmoothingFactor: Double
    let activationThreshold: Double
    let deactivationThreshold: Double
    let deactivationDelay: TimeInterval

    nonisolated init(
        minimumDecibels: Double = -55,
        maximumDecibels: Double = -15,
        risingSmoothingFactor: Double = 0.35,
        fallingSmoothingFactor: Double = 0.12,
        activationThreshold: Double = 0.15,
        deactivationThreshold: Double = 0.08,
        deactivationDelay: TimeInterval = 0.25
    ) {
        self.minimumDecibels = minimumDecibels
        self.maximumDecibels = max(minimumDecibels + 1, maximumDecibels)
        self.risingSmoothingFactor = risingSmoothingFactor.clamped(to: 0...1)
        self.fallingSmoothingFactor = fallingSmoothingFactor.clamped(to: 0...1)
        self.activationThreshold = activationThreshold.clamped(to: 0...1)
        self.deactivationThreshold = min(
            self.activationThreshold,
            deactivationThreshold.clamped(to: 0...1)
        )
        self.deactivationDelay = max(0, deactivationDelay)
    }
}

/// 연속된 RMS dB 값을 시각 효과에 사용할 부드러운 값으로 변환합니다.
struct VoiceMotionAnalyzer: Sendable {
    private let policy: VoiceMotionAnalysisPolicy
    private var smoothedValue = 0.0
    private var inactiveDuration: TimeInterval = 0
    private var isVoiceActive = false

    nonisolated init(policy: VoiceMotionAnalysisPolicy = .init()) {
        self.policy = policy
    }

    /// 새 오디오 구간을 반영해 `0...1` 범위의 모션 샘플을 반환합니다.
    nonisolated mutating func process(
        rmsDecibels: Float,
        duration: TimeInterval
    ) -> VoiceMotionSampleDTO {
        let target = normalizedTarget(for: Double(rmsDecibels))
        let smoothingFactor = target > smoothedValue
            ? policy.risingSmoothingFactor
            : policy.fallingSmoothingFactor

        smoothedValue += smoothingFactor * (target - smoothedValue)
        updateVoiceActivity(target: target, duration: max(0, duration))

        let easedValue = smoothedValue * smoothedValue * (3 - (2 * smoothedValue))
        return VoiceMotionSampleDTO(
            normalizedValue: easedValue.clamped(to: 0...1),
            isVoiceActive: isVoiceActive
        )
    }

    /// 이전 버퍼에서 누적한 스무딩과 음성 활성 상태를 초기화합니다.
    nonisolated mutating func reset() {
        smoothedValue = 0
        inactiveDuration = 0
        isVoiceActive = false
    }

    private nonisolated func normalizedTarget(for decibels: Double) -> Double {
        let range = policy.maximumDecibels - policy.minimumDecibels
        return ((decibels - policy.minimumDecibels) / range).clamped(to: 0...1)
    }

    private nonisolated mutating func updateVoiceActivity(
        target: Double,
        duration: TimeInterval
    ) {
        if target >= policy.activationThreshold {
            isVoiceActive = true
            inactiveDuration = 0
            return
        }

        guard isVoiceActive else { return }

        if target <= policy.deactivationThreshold {
            inactiveDuration += duration
            if inactiveDuration >= policy.deactivationDelay {
                isVoiceActive = false
                inactiveDuration = 0
            }
        } else {
            inactiveDuration = 0
        }
    }
}

private extension Double {
    nonisolated func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
