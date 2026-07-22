//
//  HomeComponentsTests.swift
//  SiboyaTests
//

import Foundation
import SwiftUI
import Testing
@testable import Siboya

struct HomeComponentsTests {
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

    @Test
    func gestationalWeekTextUsesInjectedWeek() {
        #expect(makeItem(week: 20).gestationalWeekText == "20주차")
        #expect(makeItem(week: 40).gestationalWeekText == "40주차")
    }

    @Test
    @MainActor
    func artworkIgnoresBlankAssetName() {
        let artwork = HomeArtworkView(assetName: "  \n", cornerRadius: 17)

        #expect(artwork.resolvedAssetName == nil)
        #expect(artwork.resolvedImage == nil)
    }

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
