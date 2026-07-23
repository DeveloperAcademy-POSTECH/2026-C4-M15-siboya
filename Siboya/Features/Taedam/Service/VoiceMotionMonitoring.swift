//
//  VoiceMotionMonitoring.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// 마이크 음량을 태담 배경 모션에 사용할 수 있는 값으로 변환한 샘플입니다.
struct VoiceMotionSampleDTO: Equatable, Sendable {
    /// 음량을 시각 효과에 맞게 보간한 `0...1` 범위의 값입니다.
    let normalizedValue: Double

    /// 최근 입력에서 사용자의 발화가 감지되고 있는지 나타냅니다.
    let isVoiceActive: Bool
}

/// 태담 대본 진행 중 마이크 음량을 관찰하는 객체의 공통 계약입니다.
protocol VoiceMotionMonitoring: Sendable {
    /// 새 마이크 버퍼가 들어올 때마다 가장 최근의 음성 모션 값을 전달합니다.
    var samples: AsyncStream<VoiceMotionSampleDTO> { get }

    /// 마이크 입력 감시를 시작합니다.
    ///
    /// 버킷리스트 STT를 시작하기 전에는 반드시 ``stopMonitoring()``을 호출해
    /// input node에 설치한 tap을 제거해야 합니다.
    func startMonitoring() async throws

    /// 마이크 tap과 오디오 세션을 정리하고 정지 상태의 샘플을 전달합니다.
    func stopMonitoring() async
}

/// 음성 모션 모니터를 시작할 수 없는 원인입니다.
enum VoiceMotionMonitoringError: Error, Equatable {
    /// 마이크 권한이 허용되지 않았습니다.
    case microphonePermissionDenied

    /// 마이크가 유효한 샘플레이트나 채널을 제공하지 않았습니다.
    case invalidAudioFormat

    /// 오디오 세션을 활성화하거나 오디오 엔진을 시작하지 못했습니다.
    case audioSessionUnavailable
}
