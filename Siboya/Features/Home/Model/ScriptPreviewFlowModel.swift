//
//  ScriptPreviewFlowModel.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Observation

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

    /// 사용자가 태담 준비를 선택했을 때 준비자세 시트를 엽니다.
    func presentPreparation() {
        shouldStartSessionAfterDismissal = false
        isPreparationPresented = true
    }

    /// 닫기 버튼 또는 drag dismiss로 준비자세 시트만 닫습니다.
    func dismissPreparation() {
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

    /// 준비자세 시트의 닫힘 애니메이션이 끝난 뒤 예약된 태담 전체 화면을 표시합니다.
    func handlePreparationDismissed() {
        guard shouldStartSessionAfterDismissal else { return }

        shouldStartSessionAfterDismissal = false
        isSessionPresented = true
    }

    /// 태담 화면에서 뒤로 가기나 완료를 선택했을 때 전체 화면 표시 상태를 해제합니다.
    func dismissSession() {
        isSessionPresented = false
    }
}
