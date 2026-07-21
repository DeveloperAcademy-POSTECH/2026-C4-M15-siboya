//
//  BucketListDraftDTO.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

/// Speech로 인식한 원문과 사용자가 편집할 문장을 함께 전달하는 값 타입입니다.
///
/// `rawTranscript`는 STT가 끝난 시점의 원문이며 저장 데이터로 직접 사용하지 않습니다.
/// 화면은 `editedText`를 초기 편집값으로 보여주고, 사용자가 확정한 값만 저장해야 합니다.
struct BucketListDraftDTO: Equatable, Sendable {
    /// Speech가 반환한 최종 전사문입니다.
    let rawTranscript: String

    /// 키보드 편집 화면에서 수정할 문장입니다. 최초 값은 `rawTranscript`와 같습니다.
    var editedText: String
}
