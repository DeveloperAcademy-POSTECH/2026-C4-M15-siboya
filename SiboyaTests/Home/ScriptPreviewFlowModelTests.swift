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
}
