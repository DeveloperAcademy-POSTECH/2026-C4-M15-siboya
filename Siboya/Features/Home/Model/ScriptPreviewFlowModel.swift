//
//  ScriptPreviewFlowModel.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Observation

/// 준비자세 화면에서 설정 안내가 필요한 음성 권한을 구분합니다.
enum TaedamAuthorizationIssue: Equatable, Sendable {
    case microphone
    case speechRecognition
}

/// 준비자세 시트와 태담 전체 화면 사이의 표시 순서를 한곳에서 관리합니다.
@MainActor
@Observable
final class ScriptPreviewFlowModel {
    /// 준비자세 안내와 시작 버튼을 담은 바텀 시트의 표시 여부입니다.
    private(set) var isPreparationPresented = false

    /// 시트 닫힘 애니메이션 뒤에만 전체 화면을 열도록 시작을 예약하는 플래그입니다.
    private(set) var shouldStartSessionAfterDismissal = false

    /// 실제 태담 화면을 `fullScreenCover`로 표시할지 결정하는 상태입니다.
    private(set) var isSessionPresented = false

    /// 중복 시작 요청을 막고 준비자세 버튼에 진행 상태를 표시합니다.
    private(set) var isRequestingAuthorization = false

    /// 거부되거나 제한된 권한에 맞는 설정 안내 Alert를 표시합니다.
    private(set) var authorizationIssue: TaedamAuthorizationIssue?

    /// 저장 성공 후 같은 전체 화면 안에서 Report에 전달할 최종 소원 문장입니다.
    private(set) var resultBucketListContent: String?

    /// 권한 요청 도중 sheet가 닫혔다 다시 열려도 오래된 응답이 새 흐름을 시작하지 않게 구분합니다.
    private var preparationGeneration = 0

    /// 사용자가 태담 준비를 선택했을 때 준비자세 시트를 엽니다.
    func presentPreparation() {
        preparationGeneration += 1
        shouldStartSessionAfterDismissal = false
        authorizationIssue = nil
        isPreparationPresented = true
    }

    /// 닫기 버튼 또는 drag dismiss로 준비자세 시트만 닫습니다.
    func dismissPreparation() {
        if isPreparationPresented {
            preparationGeneration += 1
        }
        isPreparationPresented = false

        guard !shouldStartSessionAfterDismissal else { return }

        shouldStartSessionAfterDismissal = false
    }

    /// 시작 요청을 받으면 시트를 먼저 닫고, 닫힘 애니메이션 이후 태담 화면을 열도록 예약합니다.
    func startSession() {
        guard isPreparationPresented else { return }

        shouldStartSessionAfterDismissal = true
        isPreparationPresented = false
    }

    /// 시작하기를 누를 때 마이크와 Speech 권한을 확인하고 모두 허용된 경우에만 세션을 예약합니다.
    /// - Parameter requestAuthorization: 시스템 권한 확인·요청을 수행하는 비동기 동작입니다.
    func requestSessionStart(
        using requestAuthorization: () async -> TaedamSpeechAuthorization
    ) async {
        guard isPreparationPresented,
              !isRequestingAuthorization else {
            return
        }

        let requestGeneration = preparationGeneration
        isRequestingAuthorization = true
        let authorization = await requestAuthorization()
        isRequestingAuthorization = false

        // 권한 요청 중 사용자가 sheet를 닫았다면 뒤늦게 태담 화면을 열지 않습니다.
        guard isPreparationPresented,
              preparationGeneration == requestGeneration else {
            return
        }

        guard authorization.isAuthorized else {
            authorizationIssue = authorization.microphone == .authorized
                ? .speechRecognition
                : .microphone
            return
        }

        authorizationIssue = nil
        startSession()
    }

    /// 설정 안내 Alert만 닫고 준비자세 sheet는 그대로 유지합니다.
    func dismissAuthorizationIssue() {
        authorizationIssue = nil
    }

    /// 준비자세 시트의 닫힘 애니메이션이 끝난 뒤 예약된 태담 전체 화면을 표시합니다.
    func handlePreparationDismissed() {
        guard shouldStartSessionAfterDismissal else { return }

        shouldStartSessionAfterDismissal = false
        isSessionPresented = true
    }

    /// 저장에 성공한 최종 문장을 Report 입력으로 보관하고 태담 화면 대신 결과 화면을 표시합니다.
    func presentResult(bucketListContent: String) {
        guard isSessionPresented else { return }

        resultBucketListContent = bucketListContent
    }

    /// Report 완료 시 결과 내용을 유지한 채 전체 화면 닫힘 애니메이션만 시작합니다.
    func dismissResult() {
        guard resultBucketListContent != nil else { return }

        isSessionPresented = false
    }

    /// Report가 완전히 닫힌 뒤 다음 태담을 위해 일회성 결과 문장을 제거합니다.
    func clearResult() {
        resultBucketListContent = nil
    }

    /// 태담 화면에서 뒤로 가기나 결과 완료를 선택했을 때 전체 화면 상태를 초기화합니다.
    func dismissSession() {
        resultBucketListContent = nil
        isSessionPresented = false
    }
}
