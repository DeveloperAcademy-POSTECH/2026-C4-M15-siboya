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
    let bucketListPrompt: String
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
                bucketListPrompt: bucketListPrompt.resolvingBabyNickname(babyNickname),
                bucketListGuide: bucketListGuide.resolvingBabyNickname(babyNickname)
            ),
            babyNickname: babyNickname
        )
    }
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
