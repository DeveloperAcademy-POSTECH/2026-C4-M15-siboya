//
//  ScriptPreviewViewTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import Testing
@testable import Siboya

/// 대본 미리보기와 준비자세 View가 화면 조립에 필요한 표시 데이터를 보존하는지 검증합니다.
@MainActor
struct ScriptPreviewViewTests {
    /// 미리보기 화면이 상위 설정과 무관하게 시스템 navigation bar 표시를 요청하는지 검증합니다.
    @Test
    func previewKeepsSystemNavigationBarVisible() {
        #expect(ScriptPreviewView.navigationBarVisibility == .visible)
    }

    /// 미리보기 ScrollView가 Hero와 같은 기준으로 상단만 확장하는지 검증합니다.
    @Test
    func previewExtendsScrollThroughOnlyTopSafeArea() {
        #expect(ScriptPreviewView.ignoredSafeAreaEdges.contains(.top))
        #expect(!ScriptPreviewView.ignoredSafeAreaEdges.contains(.bottom))
    }

    /// 준비자세 안내 문구에 전달받은 태명이 포함되고 프로필 에셋 이름을 유지하는지 검증합니다.
    @Test
    func preparationMessageIncludesResolvedBabyNickname() {
        let view = TaedamPreparationView(
            babyNickname: "꾹꾹이",
            isRequestingPermission: false,
            onClose: {},
            onStart: {}
        )

        #expect(view.instructionText.contains("꾹꾹이"))
        #expect(view.profileAssetName == "img_profile")
    }

    /// 이동 데이터가 태담 실행 입력과 선택된 대표 이미지 시리즈를 변경 없이 보관하는지 검증합니다.
    @Test
    func previewRouteKeepsSessionInputAndArtworkSeries() {
        let route = ScriptPreviewRoute(
            sessionInput: .mock,
            artworkSeries: .seven
        )
        let view = ScriptPreviewView(
            route: route,
            authorizer: PermissionAuthorizerStub(result: .granted)
        )

        #expect(view.route == route)
        #expect(view.route.artworkSeries == .seven)
    }
}

/// 시스템 권한 창 없이 허용 결과를 반환해 View의 주입 경로만 확인하는 테스트 대역입니다.
private struct PermissionAuthorizerStub: TaedamPermissionAuthorizing {
    /// 각 테스트가 재현할 권한 확인 결과입니다.
    let result: TaedamPermissionResult

    /// View가 흐름 모델에 전달한 권한 서비스의 결과를 비동기로 반환합니다.
    func requestRequiredPermissions() async -> TaedamPermissionResult {
        result
    }
}
