//
//  BucketListTranscribing.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

/// 버킷리스트 음성을 텍스트 초안으로 변환하는 객체의 공통 계약입니다.
///
/// 구현체는 한 번에 하나의 전사만 실행해야 하며, 부분 전사문은 저장하지 않고 화면 표시용으로만 사용합니다.
protocol BucketListTranscribing: Sendable {
    /// 인식 중 가장 최근의 전체 전사문을 전달하는 스트림입니다.
    ///
    /// `start(duration:)` 호출 전에 구독할 수 있으며, 새 결과가 생길 때마다 문자열 전체를 전달합니다.
    var partialTranscripts: AsyncStream<String> { get }

    /// 마이크 입력과 실시간 음성 인식을 시작합니다.
    ///
    /// - Parameter duration: 마이크를 열어둘 최대 시간입니다. 태담에서는 `.seconds(20)`을 사용합니다.
    /// - Throws: 권한, Speech 서비스 또는 오디오 입력을 사용할 수 없으면
    ///   ``BucketListTranscriptionError``를 던집니다.
    func start(duration: Duration) async throws

    /// 현재 입력을 종료하고 키보드 편집에 사용할 초안을 반환합니다.
    ///
    /// 전사문이 없으면 두 문자열이 모두 빈 ``BucketListDraftDTO``를 반환할 수 있습니다.
    func finish() async throws -> BucketListDraftDTO

    /// 현재 입력과 인식 작업을 즉시 취소하고 수집한 전사문을 폐기합니다.
    func cancel() async
}

/// 버킷리스트 STT를 시작하거나 종료할 수 없는 원인을 나타냅니다.
enum BucketListTranscriptionError: Error, Equatable {
    /// 최대 입력 시간이 0초 이하입니다.
    case invalidDuration

    /// 이미 전사 중인 객체에 `start(duration:)`를 다시 호출했습니다.
    case alreadyTranscribing

    /// 전사를 시작하지 않은 객체에 `finish()`를 호출했습니다.
    case notTranscribing

    /// 마이크 권한이 허용되지 않았습니다.
    case microphonePermissionDenied

    /// Speech 음성 인식 권한이 허용되지 않았거나 시스템 정책으로 제한됐습니다.
    case speechRecognitionPermissionDenied

    /// 권한은 있지만 현재 Speech 인식기를 사용할 수 없습니다.
    case recognizerUnavailable

    /// 마이크가 유효한 샘플레이트나 채널을 제공하지 않았습니다.
    case invalidAudioFormat

    /// 오디오 세션 설정 또는 Speech 인식 과정에서 복구할 수 없는 오류가 발생했습니다.
    case recognitionFailed
}

/// 마이크 또는 Speech 권한의 현재 상태입니다.
enum SpeechPermissionState: Equatable, Sendable {
    /// 아직 사용자에게 권한을 요청하지 않았습니다.
    case undetermined

    /// 사용자가 권한을 거부했습니다.
    case denied

    /// 보호자 제어 또는 기기 정책으로 권한 사용이 제한됐습니다.
    case restricted

    /// 사용자가 권한을 허용했습니다.
    case authorized
}

/// 태담 STT에 필요한 마이크 권한과 Speech 권한을 묶은 결과입니다.
struct TaedamSpeechAuthorization: Equatable, Sendable {
    /// 마이크 녹음 권한입니다.
    let microphone: SpeechPermissionState

    /// Speech 음성 인식 권한입니다.
    let speechRecognition: SpeechPermissionState

    /// 두 권한을 모두 사용할 수 있을 때만 `true`입니다.
    var isAuthorized: Bool {
        microphone == .authorized && speechRecognition == .authorized
    }
}
