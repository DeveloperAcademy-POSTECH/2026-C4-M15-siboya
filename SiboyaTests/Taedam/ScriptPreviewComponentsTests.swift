//
//  ScriptPreviewComponentsTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import Testing
@testable import Siboya

/// 대본 미리보기 컴포넌트가 표시 값과 사용자 동작 계약을 지키는지 검증합니다.
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
}
