//
//  TaedamSpeechAuthorizationService.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import AVFAudio
import Speech

/// 태담 STT에 필요한 마이크와 Speech 권한을 확인하고 요청하는 서비스입니다.
///
/// 태담 화면에 진입하기 직전에 `requestAuthorization()`을 호출하고, 두 권한이 모두 허용된 경우에만
/// ``SpeechBucketListTranscriber``를 시작합니다. 이미 결정된 권한은 시스템 팝업을 다시 띄우지 않고 즉시 반환됩니다.
///
/// 사용 예시:
/// ```swift
/// let authorizationService = TaedamSpeechAuthorizationService()
/// let authorization = await authorizationService.requestAuthorization()
///
/// guard authorization.isAuthorized else {
///     // 권한 설명 또는 설정 앱 이동 안내를 표시합니다.
///     return
/// }
///
/// // 권한이 확인된 뒤 태담 화면으로 이동합니다.
/// ```
///
/// 앱 타깃에는 `NSMicrophoneUsageDescription`과 `NSSpeechRecognitionUsageDescription`이 필요합니다.
struct TaedamSpeechAuthorizationService: Sendable {
    /// 시스템 팝업을 표시하지 않고 현재 권한 상태만 반환합니다.
    ///
    /// 화면 표시를 갱신하거나 설정 앱에서 돌아온 뒤 권한을 다시 확인할 때 사용합니다.
    func currentAuthorization() -> TaedamSpeechAuthorization {
        TaedamSpeechAuthorization(
            microphone: Self.microphonePermissionState,
            speechRecognition: Self.speechPermissionState
        )
    }

    /// 결정되지 않은 마이크와 Speech 권한을 요청하고 최종 상태를 반환합니다.
    ///
    /// 시스템 팝업이 겹치지 않도록 마이크 권한을 먼저 요청한 뒤 Speech 권한을 요청합니다.
    /// 이미 허용되거나 거부된 권한은 팝업 없이 기존 상태를 반환합니다.
    func requestAuthorization() async -> TaedamSpeechAuthorization {
        let microphoneGranted = await Self.requestMicrophoneAuthorization()
        let speechStatus = await Self.requestSpeechAuthorization()

        return TaedamSpeechAuthorization(
            microphone: microphoneGranted ? .authorized : .denied,
            speechRecognition: Self.permissionState(for: speechStatus)
        )
    }

    private static var microphonePermissionState: SpeechPermissionState {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            .undetermined
        case .denied:
            .denied
        case .granted:
            .authorized
        @unknown default:
            .denied
        }
    }

    private static var speechPermissionState: SpeechPermissionState {
        permissionState(for: SFSpeechRecognizer.authorizationStatus())
    }

    private static func permissionState(
        for status: SFSpeechRecognizerAuthorizationStatus
    ) -> SpeechPermissionState {
        switch status {
        case .notDetermined:
            .undetermined
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .authorized:
            .authorized
        @unknown default:
            .denied
        }
    }

    private static func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
