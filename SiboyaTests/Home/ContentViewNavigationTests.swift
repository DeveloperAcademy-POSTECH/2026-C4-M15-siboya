//
//  ContentViewNavigationTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Testing
@testable import Siboya

/// Home 대본 선택값이 미리보기 이동 데이터로 손실 없이 변환되는지 검증합니다.
struct ContentViewNavigationTests {
    /// Home 카드와 행에서 전달된 UUID·버전이 선택 DTO에 그대로 보존되는지 검증합니다.
    @Test @MainActor
    func contentViewSelectionMappingPreservesUUIDAndVersion() {
        let id = UUID()
        let selection = ContentView.makeScriptSelection(scriptID: id, scriptVersion: 3)

        #expect(selection.scriptID == id)
        #expect(selection.scriptVersion == 3)
    }
}
