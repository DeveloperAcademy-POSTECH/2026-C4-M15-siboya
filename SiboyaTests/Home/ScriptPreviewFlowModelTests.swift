//
//  ScriptPreviewFlowModelTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Testing
@testable import Siboya

/// 준비자세 시트에서 태담 화면으로 이동하는 표시 상태 전이를 검증합니다.
@MainActor
struct ScriptPreviewFlowModelTests {
    /// 시작하기를 눌러도 시트 닫힘 완료 전에는 태담 전체 화면을 표시하지 않는지 검증합니다.
    @Test
    func startingSessionWaitsForSheetDismissalBeforePresentingSession() {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()

        model.startSession()

        #expect(model.shouldStartSessionAfterDismissal)
        #expect(!model.isSessionPresented)
        #expect(!model.isPreparationPresented)

        model.handlePreparationDismissed()

        #expect(model.isSessionPresented)
        #expect(!model.shouldStartSessionAfterDismissal)
    }

    /// 시작 예약 없이 시트가 닫히면 태담 화면을 열지 않는지 검증합니다.
    @Test
    func dismissingPreparationWithoutStartingDoesNotPresentSession() {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()

        model.dismissPreparation()
        model.handlePreparationDismissed()

        #expect(!model.isPreparationPresented)
        #expect(!model.shouldStartSessionAfterDismissal)
        #expect(!model.isSessionPresented)
    }

    /// 준비자세 시트가 열리지 않은 상태의 시작 요청은 무시하는지 검증합니다.
    @Test
    func startingWithoutPreparationDoesNotScheduleSession() {
        let model = ScriptPreviewFlowModel()

        model.startSession()
        model.handlePreparationDismissed()

        #expect(!model.shouldStartSessionAfterDismissal)
        #expect(!model.isSessionPresented)
    }

    /// 태담 전체 화면을 닫으면 다음 대본을 위한 표시 상태가 초기화되는지 검증합니다.
    @Test
    func dismissingSessionClearsFullScreenPresentation() {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()
        model.startSession()
        model.handlePreparationDismissed()

        model.dismissSession()

        #expect(!model.isSessionPresented)
    }

    /// 두 음성 권한이 허용된 경우에만 준비자세 sheet를 닫고 세션 시작을 예약하는지 검증합니다.
    @Test
    func authorizedRequestSchedulesSession() async {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()

        await model.requestSessionStart {
            TaedamSpeechAuthorization(
                microphone: .authorized,
                speechRecognition: .authorized
            )
        }

        #expect(model.shouldStartSessionAfterDismissal)
        #expect(!model.isPreparationPresented)
        #expect(model.authorizationIssue == nil)
    }

    /// 마이크 권한이 거부되면 준비자세를 유지하고 설정 안내 상태를 제공하는지 검증합니다.
    @Test
    func deniedMicrophoneKeepsPreparationPresented() async {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()

        await model.requestSessionStart {
            TaedamSpeechAuthorization(
                microphone: .denied,
                speechRecognition: .authorized
            )
        }

        #expect(model.isPreparationPresented)
        #expect(!model.shouldStartSessionAfterDismissal)
        #expect(model.authorizationIssue == .microphone)
    }

    /// Report 닫힘 중에는 최종 문장을 유지하고 닫힘 완료 시 명시적으로 초기화하는지 검증합니다.
    @Test
    func resultContentLivesUntilSessionDismissal() {
        let model = ScriptPreviewFlowModel()
        model.presentPreparation()
        model.startSession()
        model.handlePreparationDismissed()

        model.presentResult(bucketListContent: "같이 바다에 가고 싶어")

        #expect(model.resultBucketListContent == "같이 바다에 가고 싶어")

        model.dismissResult()

        #expect(model.resultBucketListContent == "같이 바다에 가고 싶어")
        #expect(!model.isSessionPresented)

        model.clearResult()

        #expect(model.resultBucketListContent == nil)
    }
}
