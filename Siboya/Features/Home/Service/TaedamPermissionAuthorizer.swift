//
//  TaedamPermissionAuthorizer.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import AVFoundation
import Foundation
import Speech

/// 태담 시작에 필요한 권한 중 사용자가 허용하지 않은 기능을 구분합니다.
enum TaedamPermissionIssue: Equatable, Sendable {
    /// 음성을 녹음하기 위한 마이크 접근이 허용되지 않은 상태입니다.
    case microphone

    /// 말한 내용을 텍스트로 바꾸기 위한 음성 인식 접근이 허용되지 않은 상태입니다.
    case speechRecognition
}

/// 마이크와 음성 인식 권한을 모두 확인한 최종 결과입니다.
enum TaedamPermissionResult: Equatable, Sendable {
    /// 태담 화면을 시작하는 데 필요한 모든 권한이 허용된 상태입니다.
    case granted

    /// 특정 기능 권한이 거부되었거나 시스템에서 제한한 상태입니다.
    case denied(TaedamPermissionIssue)
}

/// UIKit이나 SwiftUI와 분리해 준비자세 화면이 필요한 권한만 비동기로 요청하는 계약입니다.
protocol TaedamPermissionAuthorizing: Sendable {
    /// 마이크를 먼저 확인한 뒤 음성 인식 권한까지 순서대로 요청하고 최종 결과를 반환합니다.
    func requestRequiredPermissions() async -> TaedamPermissionResult
}

/// iOS 시스템 API를 사용해 태담의 마이크·음성 인식 권한을 실제로 확인하고 요청합니다.
struct TaedamPermissionAuthorizer: TaedamPermissionAuthorizing {
    /// 마이크와 음성 인식 권한을 순서대로 확인해 첫 번째 거부 원인을 반환합니다.
    func requestRequiredPermissions() async -> TaedamPermissionResult {
        // 음성을 수집할 수 없으면 이후 음성 인식 요청은 의미가 없으므로 마이크부터 확인합니다.
        guard await hasMicrophonePermission() else {
            return .denied(.microphone)
        }

        // 마이크 허용 후에만 음성 인식 권한을 확인해 사용자가 보는 시스템 알림 수를 최소화합니다.
        guard await hasSpeechRecognitionPermission() else {
            return .denied(.speechRecognition)
        }

        return .granted
    }

    /// iOS 17부터 제공되는 `AVAudioApplication` 상태를 읽고 미결정일 때만 시스템 알림을 요청합니다.
    private func hasMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { isGranted in
                    continuation.resume(returning: isGranted)
                }
            }
        case .denied:
            return false
        @unknown default:
            // 새 권한 상태가 추가되어도 녹음 권한이 확인되기 전 태담을 시작하지 않도록 안전하게 막습니다.
            return false
        }
    }

    /// 음성 인식 상태를 읽고 미결정일 때만 시스템 알림을 요청합니다.
    private func hasSpeechRecognitionPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            // 새 음성 인식 상태도 명시적으로 허용된 경우에만 통과시켜 권한 누락을 방지합니다.
            return false
        }
    }
}
