//
//  HomeComponentsTests.swift
//  SiboyaTests
//

import Foundation
import SwiftUI
import Testing
@testable import Siboya

/// Home 모델과 컴포넌트가 표시 및 선택 계약을 지키는지 검증합니다.
struct HomeComponentsTests {
    /// 같은 대본이라도 버전이 다르면 서로 다른 화면 항목 ID를 만드는지 검증합니다.
    @Test
    func scriptItemIDIncludesVersion() throws {
        let scriptID = try #require(
            UUID(uuidString: "57A07A17-20D6-440C-989F-0B1208B6ED01")
        )
        let firstVersion = makeItem(scriptID: scriptID, version: 1)
        let secondVersion = makeItem(scriptID: scriptID, version: 2)

        #expect(firstVersion.id != secondVersion.id)
        #expect(firstVersion.id == "57A07A17-20D6-440C-989F-0B1208B6ED01-1")
    }

    /// 주입한 임신 주차가 사용자에게 보여줄 한국어 문자열로 변환되는지 검증합니다.
    @Test
    func gestationalWeekTextUsesInjectedWeek() {
        #expect(makeItem(week: 20).gestationalWeekText == "20주차")
        #expect(makeItem(week: 40).gestationalWeekText == "40주차")
    }

    /// 공백뿐인 에셋 이름을 유효한 이미지 이름으로 취급하지 않는지 검증합니다.
    @Test
    @MainActor
    func artworkIgnoresBlankAssetName() {
        let artwork = HomeArtworkView(assetName: "  \n", cornerRadius: 17)

        #expect(artwork.resolvedAssetName == nil)
        #expect(artwork.resolvedImage == nil)
    }

    /// 등록되지 않은 에셋 이름일 때 이미지 대신 플레이스홀더 조건이 만들어지는지 검증합니다.
    @Test
    @MainActor
    func artworkUsesPlaceholderWhenAssetDoesNotExist() {
        let artwork = HomeArtworkView(
            assetName: "missing-\(UUID().uuidString)",
            cornerRadius: 17
        )

        #expect(artwork.resolvedAssetName != nil)
        #expect(artwork.resolvedImage == nil)
    }

    /// 추천 카드를 선택하면 대본 UUID와 정확한 버전이 상위 화면으로 전달되는지 검증합니다.
    @Test
    @MainActor
    func recommendationCardForwardsScriptSelection() {
        let item = makeItem(version: 3)
        var receivedID: UUID?
        var receivedVersion: Int?
        let card = HomeRecommendationCard(item: item) { scriptID, version in
            receivedID = scriptID
            receivedVersion = version
        }

        card.select()

        #expect(receivedID == item.scriptID)
        #expect(receivedVersion == 3)
    }

    /// 디자인 규격에 따라 추천 카드 높이가 230pt로 고정되어 있는지 검증합니다.
    @Test
    func recommendationCardHeightIsFixedAt230Points() {
        #expect(HomeRecommendationCard.height == 230)
    }

    /// 대본 행을 선택하면 대본 UUID와 정확한 버전이 상위 화면으로 전달되는지 검증합니다.
    @Test
    @MainActor
    func scriptRowForwardsScriptSelection() {
        let item = makeItem(version: 4)
        var receivedID: UUID?
        var receivedVersion: Int?
        let row = HomeScriptRow(item: item) { scriptID, version in
            receivedID = scriptID
            receivedVersion = version
        }

        row.select()

        #expect(receivedID == item.scriptID)
        #expect(receivedVersion == 4)
    }

    /// 항목이 없는 카테고리는 숨기고 항목이 있는 카테고리만 표시하는지 검증합니다.
    @Test
    @MainActor
    func categorySectionHidesEmptyItems() {
        let emptySection = HomeCategorySection(
            title: "멀리멀리 대모험",
            items: [],
            onSelect: { _, _ in }
        )
        let populatedSection = HomeCategorySection(
            title: "멀리멀리 대모험",
            items: [makeItem()],
            onSelect: { _, _ in }
        )

        #expect(!emptySection.hasContent)
        #expect(populatedSection.hasContent)
    }

    /// 각 테스트가 필요한 값만 바꿀 수 있도록 기본 Home 대본 모델을 생성합니다.
    private func makeItem(
        scriptID: UUID = UUID(),
        version: Int = 1,
        week: Int = 20
    ) -> HomeScriptItem {
        HomeScriptItem(
            scriptID: scriptID,
            scriptVersion: version,
            title: "일요일 아침 냄새",
            targetGestationalWeek: week,
            artworkAssetName: "script_home_sunday_morning_20w"
        )
    }
}
