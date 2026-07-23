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

    /// Hero 제목의 레이아웃 경계 다음에 소요시간이 Figma 기준 8pt만큼 떨어지는지 검증합니다.
    @Test
    func previewUsesEightPointHeroToDurationSpacing() {
        #expect(ScriptPreviewView.heroToDurationSpacing == 8)
    }

    /// 준비자세 안내 문구에 전달받은 태명이 포함되고 프로필 에셋 이름을 유지하는지 검증합니다.
    @Test
    func preparationMessageIncludesResolvedBabyNickname() {
        let view = TaedamPreparationView(
            babyNickname: "꾹꾹이",
            isStarting: false,
            onClose: {},
            onStart: {}
        )

        #expect(view.instructionText.contains("꾹꾹이"))
        #expect(view.profileAssetName == "img_profile")
    }

    /// 준비자세 sheet가 Figma의 detent와 주요 세로·하단 배치 수치를 사용하는지 검증합니다.
    @Test
    func preparationUsesFigmaSheetMetrics() {
        #expect(TaedamPreparationView.sheetDetentFraction == 0.95)
        #expect(TaedamPreparationView.headerHeight == 44)
        // Figma close control은 36pt symbol container를 44pt 원형 glass 영역 가운데에 배치합니다.
        #expect(TaedamPreparationView.closeButtonSize == 44)
        #expect(TaedamPreparationView.closeLabelSize == 36)
        #expect(TaedamPreparationView.closeButtonInset == 16)
        #expect(TaedamPreparationView.artworkTopSpacing == 52)
        #expect(TaedamPreparationView.guidanceTopSpacing == 67)
        #expect(TaedamPreparationView.horizontalPadding == 20)
        #expect(TaedamPreparationView.bottomPadding == 22)
    }

    /// 준비자세 View가 닫기와 시작 동작을 직접 처리하지 않고 상위 callback으로 한 번씩 전달하는지 검증합니다.
    @Test
    func preparationForwardsCloseAndStartActions() {
        var closeCount = 0
        var startCount = 0
        let view = TaedamPreparationView(
            babyNickname: "꾹꾹이",
            isStarting: false,
            onClose: { closeCount += 1 },
            onStart: { startCount += 1 }
        )

        view.close()
        view.start()

        #expect(closeCount == 1)
        #expect(startCount == 1)
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
            saveBucketList: { _ in
                SavedBucketListDTO(bucketListItemID: UUID())
            }
        )

        #expect(view.route == route)
        #expect(view.route.artworkSeries == .seven)
    }
}
