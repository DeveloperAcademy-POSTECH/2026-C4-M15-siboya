//
//  HomeWeeklyContentDocumentTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/21/26.
//

import Foundation
import Testing
@testable import Siboya

struct HomeWeeklyContentDocumentTests {
    @Test func bundledDocumentContainsEveryWeekFromTwentyThroughForty() throws {
        let document = try BundledHomeWeeklyContentLoader.load()

        #expect(document.weeks.map(\.gestationalWeek) == Array(20...40))
        #expect(Set(document.weeks.map(\.gestationalWeek)).count == 21)
        #expect(document.weeks.allSatisfy {
            !$0.headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
        let scriptIDs = try BundledTaedamScriptLoader.load().scripts.map(\.id)
        try #require(!scriptIDs.isEmpty)
        let expectedRecommendedScriptIDs = document.weeks.indices.map {
            scriptIDs[$0 % scriptIDs.count]
        }

        #expect(document.weeks.map(\.recommendedScriptID) == expectedRecommendedScriptIDs)
    }

    @Test func documentReturnsContentForExactGestationalWeek() throws {
        let document = try BundledHomeWeeklyContentLoader.load()
        let content = try #require(document.content(forGestationalWeek: 20))

        #expect(content.headline == "아빠의 낮은 목소리가 잘 들리는 시기")
        let firstScriptID = try #require(BundledTaedamScriptLoader.load().scripts.first?.id)
        #expect(content.recommendedScriptID == firstScriptID)
        #expect(document.content(forGestationalWeek: 19) == nil)
        #expect(document.content(forGestationalWeek: 41) == nil)
    }

    @Test func recommendedScriptIDDecodesAsUUID() throws {
        let linkedID = try #require(
            UUID(uuidString: "57A07A17-20D6-440C-989F-0B1208B6ED01")
        )
        let data = Data(
            """
            {
              "weeks": [
                {
                  "gestationalWeek": 20,
                  "headline": "연결됨",
                  "recommendedScriptID": "\(linkedID.uuidString)"
                }
              ]
            }
            """.utf8
        )

        let document = try JSONDecoder().decode(HomeWeeklyContentDocument.self, from: data)

        #expect(document.weeks[0].recommendedScriptID == linkedID)
    }
}
