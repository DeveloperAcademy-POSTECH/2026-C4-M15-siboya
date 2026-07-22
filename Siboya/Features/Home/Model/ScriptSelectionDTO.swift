//
//  ScriptSelectionDTO.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// Home에서 사용자가 누른 대본을 UUID와 수정 버전까지 포함해 전달하는 값 객체입니다.
struct ScriptSelectionDTO: Equatable, Sendable {
    /// 같은 제목의 대본과도 구분할 수 있는 대본 고유 식별자입니다.
    let scriptID: UUID

    /// 같은 UUID로 갱신된 대본 중 사용자가 선택한 정확한 수정본 번호입니다.
    let scriptVersion: Int
}
