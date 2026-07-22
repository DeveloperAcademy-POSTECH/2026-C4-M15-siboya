//
//  ScriptPreviewFlowModel.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Observation

/// 준비자세 시트, 권한 안내, 태담 전체 화면 사이의 순서를 한곳에서 관리합니다.
@MainActor
@Observable
final class ScriptPreviewFlowModel {
    /// 실제 권한 확인을 담당하며 테스트에서는 고정 결과를 반환하는 대역으로 바꿀 수 있습니다.
    private let authorizer: any TaedamPermissionAuthorizing

    /// 준비자세 안내와 시작 버튼을 담은 바텀 시트의 표시 여부입니다.
    private(set) var isPreparationPresented = false

    /// 중복 탭으로 시스템 권한 알림이 겹쳐 열리는 것을 막기 위한 진행 상태입니다.
    private(set) var isRequestingPermission = false

    /// 거부된 기능에 맞는 설정 안내 알림을 표시하기 위한 원인입니다.
    private(set) var permissionAlertIssue: TaedamPermissionIssue?

    /// 시트 닫힘 애니메이션 뒤에만 전체 화면을 열도록 시작을 예약하는 플래그입니다.
    private(set) var shouldStartSessionAfterDismissal = false

    /// 실제 태담 화면을 `fullScreenCover`로 표시할지 결정하는 상태입니다.
    private(set) var isSessionPresented = false

    /// 권한 요청 서비스를 주입해 화면 상태만 독립적으로 검증할 수 있게 초기화합니다.
    /// - Parameter authorizer: 마이크와 음성 인식 권한을 순서대로 확인할 서비스입니다.
    init(authorizer: any TaedamPermissionAuthorizing = TaedamPermissionAuthorizer()) {
        self.authorizer = authorizer
    }

    /// 사용자가 태담 시작을 선택했을 때 준비자세 시트를 열고 이전 경고를 초기화합니다.
    func presentPreparation() {
        // 이전에 거부된 안내가 남아 있으면 새 시트에서 잘못된 알림이 바로 보일 수 있어 함께 비웁니다.
        permissionAlertIssue = nil
        shouldStartSessionAfterDismissal = false
        isPreparationPresented = true
    }

    /// 닫기 버튼 또는 drag dismiss로 준비자세 시트만 닫고 세션 시작 여부는 별도 상태로 유지합니다.
    func dismissPreparation() {
        // 권한 승인 직후에는 이미 예약된 세션 시작이 있으므로 그 플래그는 지우지 않아 onDismiss 전환을 보존합니다.
        isPreparationPresented = false
    }

    /// 사용자가 닫기나 설정을 선택한 권한 안내를 해제해 같은 경고가 다시 열리지 않게 합니다.
    func dismissPermissionAlert() {
        // 시트는 계속 표시해 사용자가 설정을 확인한 뒤 다시 시작하기를 선택할 수 있게 합니다.
        permissionAlertIssue = nil
    }

    /// 진행 중이 아닌 경우에만 권한을 요청하고 결과에 따라 시트 유지 또는 시작 예약을 처리합니다.
    func requestPermissions() async {
        // 시스템 권한 알림은 하나씩만 표시되어야 하므로 빠른 중복 탭을 무시합니다.
        guard !isRequestingPermission else { return }

        isRequestingPermission = true
        let result = await authorizer.requestRequiredPermissions()
        isRequestingPermission = false

        switch result {
        case .granted:
            // 시트와 전체 화면이 겹치지 않도록 먼저 시트를 닫고 onDismiss에서 세션을 엽니다.
            shouldStartSessionAfterDismissal = true
            isPreparationPresented = false
        case .denied(let issue):
            // 사용자가 다시 시도하거나 설정으로 이동할 수 있도록 시트는 닫지 않고 원인만 표시합니다.
            permissionAlertIssue = issue
        }
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
