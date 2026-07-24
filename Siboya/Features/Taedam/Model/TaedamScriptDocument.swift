//
//  TaedamScriptDocument.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

struct TaedamScriptDocument: Decodable, Sendable {
    let scripts: [TaedamScriptContent]
}

struct TaedamScriptContent: Decodable, Sendable {
    let id: UUID
    let version: Int
    let category: String
    let title: String
    let metadata: ScriptMetadataContent
    let sentences: [String]
    let bucketListPrompt: BucketListPromptContent
    let bucketListGuide: String

    func makeSessionInput(babyNickname: String) -> TaedamSessionInputDTO {
        let resolvedSentences = sentences.enumerated().map { index, text in
            ScriptSentenceDTO(
                index: index,
                text: text.resolvingBabyNickname(babyNickname)
            )
        }

        return TaedamSessionInputDTO(
            script: ScriptPreviewDTO(
                scriptID: id,
                scriptVersion: version,
                category: category,
                title: title,
                targetGestationalWeek: metadata.targetGestationalWeek,
                artworkAssetName: metadata.artworkAssetName,
                estimatedDurationSeconds: metadata.estimatedDurationSeconds,
                sentences: resolvedSentences,
                bucketListPrompt: BucketListPromptDTO(
                    leadIn: bucketListPrompt.leadIn.resolvingBabyNickname(babyNickname),
                    speechPlaceholder: bucketListPrompt.speechPlaceholder
                        .resolvingBabyNickname(babyNickname)
                ),
                bucketListGuide: bucketListGuide.resolvingBabyNickname(babyNickname)
            ),
            babyNickname: babyNickname
        )
    }
}

/// 버킷리스트 발화 전 고정문장과 발화 시작 전 안내 문구를 분리해 디코딩합니다.
struct BucketListPromptContent: Decodable, Sendable {
    /// 일반 대본처럼 먼저 채워지며 STT 중에도 화면에 남는 고정 도입문입니다.
    let leadIn: String

    /// 도입문 아래에 표시했다가 STT가 시작되면 제거하는 짧은 안내 문구입니다.
    let speechPlaceholder: String
}

struct ScriptMetadataContent: Decodable, Sendable {
    let targetGestationalWeek: Int
    let artworkAssetName: String
    let estimatedDurationSeconds: Int?
}

private extension String {
    func resolvingBabyNickname(_ babyNickname: String) -> String {
        replacingOccurrences(of: "{{babyNickname}}", with: babyNickname)
    }
}
