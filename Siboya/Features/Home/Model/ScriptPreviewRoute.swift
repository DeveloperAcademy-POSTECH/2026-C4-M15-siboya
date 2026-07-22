//
//  ScriptPreviewRoute.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// 미리보기부터 태담 화면까지 유지할 대본 입력과 대표 이미지 시리즈를 묶는 이동 데이터입니다.
struct ScriptPreviewRoute: Identifiable, Equatable, Sendable {
    /// 태명이 치환되어 미리보기·준비자세·태담 화면이 함께 사용할 대본 실행 입력입니다.
    let sessionInput: TaedamSessionInputDTO

    /// 대본 JSON 배열 순서에서 결정한 `TitleImage` 이미지 시리즈입니다.
    let artworkSeries: ScriptArtworkSeries

    /// NavigationStack이 UUID와 버전이 모두 같은 화면 이동만 같은 항목으로 판단하도록 만드는 식별자입니다.
    var id: String {
        "\(sessionInput.script.scriptID.uuidString)-\(sessionInput.script.scriptVersion)"
    }
}

extension ScriptPreviewRoute: Hashable {
    /// NavigationStack이 같은 대본·버전의 화면을 일관되게 식별하도록 route ID만 해시 값으로 사용합니다.
    /// - Parameter hasher: NavigationStack 내부 경로 저장소가 제공하는 해시 누적 객체입니다.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
