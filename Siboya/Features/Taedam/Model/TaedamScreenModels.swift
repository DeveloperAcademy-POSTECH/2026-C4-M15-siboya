//
//  TaedamScreenModels.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

struct ScriptSentenceDTO: Identifiable, Equatable, Sendable {
    let index: Int
    let text: String

    var id: Int { index }
}

struct ScriptPreviewDTO: Equatable, Sendable {
    let scriptID: UUID
    let scriptVersion: Int
    let category: String
    let title: String
    let targetGestationalWeek: Int
    let artworkAssetName: String
    let estimatedDurationSeconds: Int?
    let sentences: [ScriptSentenceDTO]
    let bucketListPrompt: String
    let bucketListGuide: String
}

struct TaedamSessionInputDTO: Equatable, Sendable {
    let script: ScriptPreviewDTO
    let babyNickname: String

    var lines: [TaedamLineDTO] {
        let scriptLines = script.sentences.enumerated().map { offset, sentence in
            TaedamLineDTO(
                index: offset,
                kind: .script(sentenceIndex: sentence.index),
                text: sentence.text
            )
        }

        return scriptLines + [
            TaedamLineDTO(
                index: scriptLines.count,
                kind: .bucketList,
                text: script.bucketListPrompt
            )
        ]
    }
}

enum TaedamLineKindDTO: Equatable, Sendable {
    case script(sentenceIndex: Int)
    case bucketList
}

struct TaedamLineDTO: Identifiable, Equatable, Sendable {
    let index: Int
    let kind: TaedamLineKindDTO
    let text: String

    var id: Int { index }
}

enum TaedamScreenPhase: Equatable, Sendable {
    case ready
    case countingDown(remainingSeconds: Int)
    case readingScript(index: Int)
    case bucketList
}

extension TaedamSessionInputDTO {
    static var mock: TaedamSessionInputDTO {
        if let document = try? BundledTaedamScriptLoader.load(),
           let script = document.scripts.first {
            return script.makeSessionInput(babyNickname: "꼭꼭")
        }

        return fallbackMock
    }

    private static let fallbackMock = TaedamSessionInputDTO(
        script: ScriptPreviewDTO(
            scriptID: UUID(),
            scriptVersion: 1,
            category: "아기사랑",
            title: "평화로운 일요일 아침",
            targetGestationalWeek: 22,
            artworkAssetName: "script_baby_love_imagination_22w",
            estimatedDurationSeconds: 35,
            sentences: [
                ScriptSentenceDTO(index: 0, text: "안녕, 꼭꼭아."),
                ScriptSentenceDTO(index: 1, text: "아빠야. 오늘 하루도 잘 보냈지?"),
                ScriptSentenceDTO(
                    index: 2,
                    text: "아빠는 오늘 문득 우리가 함께 맞이할 일요일 아침을 상상해 봤어."
                ),
                ScriptSentenceDTO(
                    index: 3,
                    text: "알람 소리 대신에 기분 좋게 눈을 뜨고, 주방에서는 고소한 빵 굽는 냄새가 나는 그런 아침 말이야."
                ),
                ScriptSentenceDTO(
                    index: 4,
                    text: "셋이 머리도 안 감고 식탁에 둘러앉아 갓 구운 식빵에 잼을 발라 먹으면 참 평화롭겠다는 생각이 들었어."
                )
            ],
            bucketListPrompt: "꼭꼭아, 네가 태어나서 우리랑 집에서 같이 밥을 먹게 되면, 아빠는 주방에서 너를 위해 […] 해주고 싶어.",
            bucketListGuide: "집에서 아이에게 해주고 싶은 사소한 요리나 식사 시간의 모습을 말해보세요."
        ),
        babyNickname: "꼭꼭"
    )
}
