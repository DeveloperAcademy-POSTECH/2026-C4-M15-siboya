//
//  ScriptPreviewFlowModelTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Testing
@testable import Siboya

/// 준비자세 시트에서 권한 요청 결과에 따라 태담 화면으로 이동하는 상태 전이를 검증합니다.
@MainActor
struct ScriptPreviewFlowModelTests {
    /// 마이크 권한이 거부되면 준비자세 시트는 유지하고 같은 종류의 안내만 저장하는지 검증합니다.
    @Test
    func permissionDenialStoresMatchingAlertAndKeepsPreparationSheet() async {
        let model = ScriptPreviewFlowModel(
            authorizer: PermissionAuthorizerStub(result: .denied(.microphone))
        )
        model.presentPreparation()

        await model.requestPermissions()

        #expect(model.isPreparationPresented)
        #expect(model.permissionAlertIssue == .microphone)
        #expect(!model.isSessionPresented)
        #expect(!model.isRequestingPermission)
    }

    /// 모든 권한을 허용해도 시트 닫힘 완료 전에는 태담 전체 화면을 표시하지 않는지 검증합니다.
    @Test
    func grantedPermissionsWaitForSheetDismissalBeforePresentingSession() async {
        let model = ScriptPreviewFlowModel(
            authorizer: PermissionAuthorizerStub(result: .granted)
        )
        model.presentPreparation()

        await model.requestPermissions()

        #expect(model.shouldStartSessionAfterDismissal)
        #expect(!model.isSessionPresented)
        #expect(!model.isPreparationPresented)

        model.handlePreparationDismissed()

        #expect(model.isSessionPresented)
        #expect(!model.shouldStartSessionAfterDismissal)
    }

    /// 시작 예약 없이 시트를 닫으면 이전 권한 상태와 관계없이 태담 화면을 열지 않는지 검증합니다.
    @Test
    func dismissingPreparationWithoutStartingDoesNotPresentSession() {
        let model = ScriptPreviewFlowModel(
            authorizer: PermissionAuthorizerStub(result: .granted)
        )
        model.presentPreparation()

        model.handlePreparationDismissed()

        #expect(!model.isSessionPresented)
    }

    /// 권한 요청이 진행 중일 때 다시 시작을 눌러도 시스템 권한 요청을 한 번만 수행하는지 검증합니다.
    @Test
    func repeatedPermissionRequestsWhileRequestIsInFlightAreIgnored() async {
        let authorizer = WaitingPermissionAuthorizer()
        let model = ScriptPreviewFlowModel(authorizer: authorizer)
        model.presentPreparation()

        let firstRequest = Task { @MainActor in
            await model.requestPermissions()
        }
        await authorizer.waitUntilRequestStarts()

        await model.requestPermissions()

        #expect(await authorizer.requestCount() == 1)
        await authorizer.finish(with: .granted)
        await firstRequest.value
    }

    /// 태담 전체 화면을 닫으면 다음 대본을 위한 표시 상태가 초기화되는지 검증합니다.
    @Test
    func dismissingSessionClearsFullScreenPresentation() async {
        let model = ScriptPreviewFlowModel(
            authorizer: PermissionAuthorizerStub(result: .granted)
        )
        model.presentPreparation()
        await model.requestPermissions()
        model.handlePreparationDismissed()

        model.dismissSession()

        #expect(!model.isSessionPresented)
    }
}

/// 고정된 권한 결과를 반환해 준비자세 화면의 상태 전이만 독립적으로 검증하는 테스트 대역입니다.
private struct PermissionAuthorizerStub: TaedamPermissionAuthorizing {
    /// 각 테스트가 재현하려는 권한 요청 결과입니다.
    let result: TaedamPermissionResult

    /// 시스템 권한 창 없이 미리 정한 결과를 비동기로 반환합니다.
    func requestRequiredPermissions() async -> TaedamPermissionResult {
        result
    }
}

/// 첫 권한 요청을 보류해 중복 탭을 안전하게 무시하는지 확인하는 동기화 가능한 테스트 대역입니다.
private actor WaitingPermissionAuthorizer: TaedamPermissionAuthorizing {
    /// 실제 권한 서비스가 호출된 횟수를 보관합니다.
    private var requests = 0

    /// 첫 호출이 시작됐음을 알리는 대기자 목록입니다.
    private var startContinuations: [CheckedContinuation<Void, Never>] = []

    /// 테스트가 허용 결과를 전달할 때까지 대기하는 호출자입니다.
    private var resultContinuation: CheckedContinuation<TaedamPermissionResult, Never>?

    /// 호출 횟수를 늘린 뒤 테스트가 결과를 제공할 때까지 요청을 보류합니다.
    func requestRequiredPermissions() async -> TaedamPermissionResult {
        requests += 1
        startContinuations.forEach { $0.resume() }
        startContinuations.removeAll()

        return await withCheckedContinuation { continuation in
            resultContinuation = continuation
        }
    }

    /// 첫 권한 요청이 시작될 때까지 기다려 중복 요청 검증의 순서를 안정화합니다.
    func waitUntilRequestStarts() async {
        guard requests == 0 else { return }

        await withCheckedContinuation { continuation in
            startContinuations.append(continuation)
        }
    }

    /// 현재까지 서비스에 도달한 권한 요청 횟수를 반환합니다.
    func requestCount() -> Int {
        requests
    }

    /// 보류 중인 첫 요청에 테스트가 정한 권한 결과를 전달합니다.
    func finish(with result: TaedamPermissionResult) {
        resultContinuation?.resume(returning: result)
        resultContinuation = nil
    }
}
