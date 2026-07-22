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

    /// 소요시간 장식선이 가로선이 아닌 1pt 세로선으로 구성되는지 검증합니다.
    @Test @MainActor
    func durationUsesVerticalSeparatorThickness() {
        #expect(ScriptPreviewDuration.separatorThickness == 1)
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

    /// 접근성 글자 크기에서는 긴 제목이 다음 영역과 겹치지 않도록 Hero 높이가 확장되는지 검증합니다.
    @Test @MainActor
    func heroGrowsForAccessibilityText() {
        let regularHeight = fittingHeight(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .medium)
        )
        let accessibilityHeight = fittingHeight(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .accessibility3)
        )

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

    /// 주어진 SwiftUI View를 402pt 화면 너비에 배치했을 때 필요한 세로 길이를 계산합니다.
    /// - Parameter view: Dynamic Type 환경이 주입된 미리보기 컴포넌트입니다.
    /// - Returns: 402×1000pt 제약 안에서 View가 선택한 적정 높이입니다.
    @MainActor
    private func fittingHeight<Content: View>(of view: Content) -> CGFloat {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 402, height: 1000))
            .height
    }
}
