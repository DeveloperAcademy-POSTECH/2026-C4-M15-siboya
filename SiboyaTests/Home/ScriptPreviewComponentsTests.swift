//
//  ScriptPreviewComponentsTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import Testing
import UIKit
@testable import Siboya

/// Home의 대본 미리보기 컴포넌트가 표시 값과 사용자 동작 계약을 지키는지 검증합니다.
struct ScriptPreviewComponentsTests {
    /// Hero가 화면 최상단까지 확장하되 하단 안전 영역은 침범하지 않는지 검증합니다.
    @Test @MainActor
    func heroExtendsThroughOnlyTopSafeArea() {
        #expect(ScriptPreviewHero.ignoredSafeAreaEdges.contains(.top))
        #expect(!ScriptPreviewHero.ignoredSafeAreaEdges.contains(.bottom))
    }

    /// 초가 분 단위로 올림되고 값이 없으면 표시 문자열도 없는지 검증합니다.
    @Test @MainActor
    func durationBuildsOptionalRoundedMinuteText() {
        #expect(
            ScriptPreviewDuration(estimatedDurationSeconds: 35).durationText
                == "약 1분"
        )
        #expect(
            ScriptPreviewDuration(estimatedDurationSeconds: 60).durationText
                == "약 1분"
        )
        #expect(
            ScriptPreviewDuration(estimatedDurationSeconds: 61).durationText
                == "약 2분"
        )
        #expect(
            ScriptPreviewDuration(estimatedDurationSeconds: nil).durationText
                == nil
        )
    }

    /// 소요시간 영역이 SSD의 선 두께와 Figma의 높이·간격·중앙 크기를 함께 유지하는지 검증합니다.
    @Test @MainActor
    func durationUsesApprovedLayoutMetrics() {
        #expect(ScriptPreviewDuration.separatorThickness == 1)
        #expect(ScriptPreviewDuration.separatorHeight == 35)
        #expect(ScriptPreviewDuration.itemSpacing == 18)
        #expect(ScriptPreviewDuration.contentMinimumWidth == 73)
        #expect(ScriptPreviewDuration.contentPadding == 10)
    }

    /// 소요시간 두 텍스트가 Figma의 4pt 간격과 tertiary/secondary 의미 색상을 사용하는지 검증합니다.
    @Test @MainActor
    func durationUsesFigmaTextHierarchy() {
        #expect(ScriptPreviewDuration.textSpacing == 4)
        #expect(ScriptPreviewDuration.labelColor == Color(.tertiaryLabel))
        #expect(ScriptPreviewDuration.durationColor == Color.secondary)
    }

    /// 일반 글자 크기에서 Figma 기본 크기를 확보하고 접근성 글자 크기에서는 잘리지 않게 확장되는지 검증합니다.
    @Test @MainActor
    func durationMeetsFigmaSizeAndGrowsForAccessibilityText() {
        let regularSize = fittingSize(
            of: ScriptPreviewDuration(estimatedDurationSeconds: 61)
                .environment(\.dynamicTypeSize, .medium)
        )
        let accessibilitySize = fittingSize(
            of: ScriptPreviewDuration(estimatedDurationSeconds: 61)
                .environment(\.dynamicTypeSize, .accessibility3)
        )

        #expect(regularSize.width >= 111)
        #expect(regularSize.height >= 67)
        #expect(accessibilitySize.width > regularSize.width)
        #expect(accessibilitySize.height > regularSize.height)
    }

    /// Hero가 주차 문구와 Figma에서 지정한 Thumbnail 규격을 유지하는지 검증합니다.
    @Test @MainActor
    func heroBuildsWeekTextAndThumbnailMetrics() {
        let hero = ScriptPreviewHero(
            artworkSeries: .three,
            targetGestationalWeek: 22,
            title: "일요일 아침 냄새"
        )

        #expect(hero.weekText == "22주차")
        #expect(ScriptPreviewHero.thumbnailSize == 132)
        #expect(ScriptPreviewHero.thumbnailCornerRadius == 32)
    }

    /// Hero 전경이 Figma의 세로 좌표를 사용하고 장식 배경이 전경 레이아웃 높이를 늘리지 않는지 검증합니다.
    @Test @MainActor
    func heroUsesFigmaForegroundSpacingWithoutBackgroundLayoutGap() {
        let regularHeight = fittingSize(
            of: ScriptPreviewHero(
                artworkSeries: .one,
                targetGestationalWeek: 22,
                title: "일요일 아침 냄새"
            )
            .environment(\.dynamicTypeSize, .medium)
        ).height

        #expect(ScriptPreviewHero.foregroundTopSpacing == 140)
        #expect(ScriptPreviewHero.thumbnailToWeekSpacing == 16)
        #expect(ScriptPreviewHero.weekToTitleSpacing == 6)
        #expect(regularHeight < ScriptPreviewHero.backgroundHeight)
    }

    /// Hero 배경은 일러스트 상단이 잘리지 않도록 위쪽 기준으로 채우고, 일반 공통 이미지는 기존 중앙 기준을 유지하는지 검증합니다.
    @Test @MainActor
    func heroUsesTopArtworkAlignmentWhileDefaultArtworkStaysCentered() {
        let hero = ScriptPreviewHero(
            artworkSeries: .one,
            targetGestationalWeek: 22,
            title: "일요일 아침 냄새"
        )
        let defaultArtwork = ScriptArtworkView(
            assetName: "TitleImage1",
            cornerRadius: 0
        )

        #expect(hero.backgroundArtworkAlignment == .top)
        #expect(defaultArtwork.imageAlignment == .center)
    }

    /// 접근성 글자 크기에서는 긴 제목이 다음 영역과 겹치지 않도록 Hero 높이가 확장되는지 검증합니다.
    @Test @MainActor
    func heroGrowsForAccessibilityText() {
        let regularHeight = fittingSize(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .medium)
        ).height
        let accessibilityHeight = fittingSize(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .accessibility3)
        ).height

        #expect(accessibilityHeight > regularHeight)
    }

    /// 문장을 재정렬하지 않고 빈칸 문장과 생각힌트를 뒤에 붙이는지 검증합니다.
    @Test @MainActor
    func bodyPreservesSentenceOrderBeforePromptAndGuide() {
        let body = ScriptPreviewBody(
            sentences: [
                ScriptSentenceDTO(index: 9, text: "먼저 전달된 문장"),
                ScriptSentenceDTO(index: 1, text: "나중에 전달된 문장")
            ],
            bucketListPrompt: "빈칸 문장",
            bucketListGuide: "생각힌트"
        )

        #expect(body.contentItems.map(\.text) == [
            "먼저 전달된 문장",
            "나중에 전달된 문장",
            "빈칸 문장",
            "생각힌트"
        ])
        #expect(body.contentItems.map(\.role) == [
            .sentence,
            .sentence,
            .bucketListPrompt,
            .bucketListGuide
        ])
    }

    /// 준비하기 선택이 외부 흐름을 직접 실행하지 않고 상위 callback을 한 번 전달하는지 검증합니다.
    @Test @MainActor
    func bottomBarForwardsPrepareOnce() {
        var prepareCount = 0
        let bottomBar = ScriptPreviewBottomBar {
            prepareCount += 1
        }

        bottomBar.prepare()

        #expect(prepareCount == 1)
    }

    /// 접근성 높이 검증에서 같은 긴 제목 Hero를 재사용해 글자 크기만 비교합니다.
    /// - Returns: 402pt 화면 너비에서 측정할 긴 제목 Hero입니다.
    @MainActor
    private func makeLongTitleHero() -> ScriptPreviewHero {
        ScriptPreviewHero(
            artworkSeries: .seven,
            targetGestationalWeek: 22,
            title: "함께 맞이하고 싶은 평화로운 일요일 아침의 긴 이야기"
        )
    }

    /// 주어진 SwiftUI View가 402×1000pt 제약 안에서 선택한 적정 크기를 계산합니다.
    /// - Parameter view: 크기를 측정할 SwiftUI View입니다.
    /// - Returns: 402×1000pt 제약 안에서 View가 선택한 적정 크기입니다.
    @MainActor
    private func fittingSize<Content: View>(of view: Content) -> CGSize {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 402, height: 1000))
    }
}
