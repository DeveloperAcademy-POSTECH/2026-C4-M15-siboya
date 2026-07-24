//
//  TaedamScriptDocumentTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/21/26.
//

import Foundation
import Testing
@testable import Siboya

struct TaedamScriptDocumentTests {
    @Test func bundledDocumentContainsSixCategorizedScripts() throws {
        let scripts = try BundledTaedamScriptLoader.load().scripts
        let scriptsByCategory = Dictionary(grouping: scripts, by: \TaedamScriptContent.category)

        #expect(scripts.count == 6)
        #expect(Set(scriptsByCategory.keys) == [
            "집에서 소소하게",
            "밖으로 한 걸음",
            "멀리멀리 대모험"
        ])
        #expect(scriptsByCategory.values.allSatisfy { $0.count == 2 })
        #expect(scripts.allSatisfy { $0.metadata.targetGestationalWeek == 20 })
    }

    @Test func bucketListContentIsSeparatedFromScriptAndExamples() throws {
        let scripts = try BundledTaedamScriptLoader.load().scripts
        let excludedClosings = [
            "오늘도 좋은 꿈꿔",
            "오늘도 건강하게 잘 자렴",
            "아빠 목소리 잊지 말고",
            "아빠랑 약속한 거다",
            "아빠가 항상 네 곁에 있을게"
        ]

        for script in scripts {
            let scriptText = script.sentences.joined(separator: " ")

            #expect(!script.bucketListPrompt.leadIn.isEmpty)
            #expect(!script.bucketListPrompt.speechPlaceholder.isEmpty)
            #expect(!script.bucketListPrompt.leadIn.contains("[…]"))
            #expect(!script.bucketListPrompt.speechPlaceholder.contains("[…]"))
            #expect(!script.bucketListGuide.contains("예:"))
            #expect(!script.bucketListGuide.contains("예시"))
            #expect(!scriptText.contains("[…]"))
            #expect(excludedClosings.allSatisfy { !scriptText.contains($0) })
        }
    }

    @Test func sessionInputResolvesNicknameInEveryDisplayedText() throws {
        let document = try BundledTaedamScriptLoader.load()
        let sessionInput = try #require(document.scripts.first)
            .makeSessionInput(babyNickname: "꼭꼭")
        let displayedText = (
            sessionInput.lines.map(\.text) + [
                sessionInput.script.bucketListPrompt.speechPlaceholder,
                sessionInput.script.bucketListGuide
            ]
        ).joined(separator: " ")

        #expect(displayedText.contains("꼭꼭"))
        #expect(!displayedText.contains("{{babyNickname}}"))
    }

    @Test func previewPromptComposesLeadInBlankAndSpeechPlaceholder() throws {
        let script = try #require(BundledTaedamScriptLoader.load().scripts.first)
        let prompt = script.makeSessionInput(babyNickname: "꼭꼭")
            .script
            .bucketListPrompt

        #expect(prompt.previewText == "\(prompt.leadIn) […] \(prompt.speechPlaceholder)")
    }
}
