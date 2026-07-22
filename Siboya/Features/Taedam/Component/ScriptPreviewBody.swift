//
//  ScriptPreviewBody.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// 대본 문장, 빈칸 문장과 생각힌트를 SSD 순서대로 보여주는 본문 컴포넌트입니다.
struct ScriptPreviewBody: View {
    /// 본문 항목마다 적용할 의미와 시각적 간격을 구분합니다.
    enum ContentRole: Equatable {
        /// 상위 계층에서 전달받은 일반 대본 문장입니다.
        case sentence

        /// 사용자가 직접 빈칸을 채워 읽을 문장입니다.
        case bucketListPrompt

        /// 빈칸 내용을 떠올릴 수 있도록 돕는 생각힌트입니다.
        case bucketListGuide
    }

    /// 표시 순서, 식별자, 역할과 실제 텍스트를 함께 보관하는 내부 모델입니다.
    struct ContentItem: Identifiable, Equatable {
        /// SwiftUI가 각 본문 항목을 안정적으로 구분할 식별자입니다.
        let id: String

        /// 문장 종류에 맞는 스타일과 접근성 처리를 선택할 역할입니다.
        let role: ContentRole

        /// 화면과 VoiceOver에 전달할 실제 문구입니다.
        let text: String
    }

    /// 상위 계층이 검증한 원래 순서의 대본 문장입니다.
    let sentences: [ScriptSentenceDTO]

    /// 사용자가 직접 완성해서 읽을 빈칸 문장입니다.
    let bucketListPrompt: String

    /// 빈칸을 떠올릴 수 있게 돕는 생각힌트입니다.
    let bucketListGuide: String

    /// 문장을 재정렬하지 않고 빈칸 문장과 생각힌트를 마지막에 결합합니다.
    var contentItems: [ContentItem] {
        let sentenceItems = sentences.map { sentence in
            ContentItem(
                id: "sentence-\(sentence.index)",
                role: .sentence,
                text: sentence.text
            )
        }

        return sentenceItems + [
            ContentItem(
                id: "bucket-list-prompt",
                role: .bucketListPrompt,
                text: bucketListPrompt
            ),
            ContentItem(
                id: "bucket-list-guide",
                role: .bucketListGuide,
                text: bucketListGuide
            )
        ]
    }

    /// 역할별 스타일과 간격을 적용하면서 계산된 순서대로 본문을 표시합니다.
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(contentItems) { item in
                contentView(for: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 항목 역할에 따라 일반 문장, 빈칸 문장 또는 이모지 생각힌트를 만듭니다.
    /// - Parameter item: 표시 역할과 문구를 포함한 본문 항목입니다.
    /// - Returns: 역할별 스타일과 접근성 의미가 적용된 SwiftUI View입니다.
    @ViewBuilder
    private func contentView(for item: ContentItem) -> some View {
        switch item.role {
        case .sentence:
            bodyText(item.text)
        case .bucketListPrompt:
            bodyText(item.text)
                .padding(.top, 20)
        case .bucketListGuide:
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("💡")
                    .accessibilityHidden(true)

                bodyText(item.text)

                Text("💡")
                    .accessibilityHidden(true)
            }
            .padding(.top, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("생각힌트: \(item.text)")
        }
    }

    /// 일반 문장과 빈칸 문장이 같은 semantic 본문 스타일을 공유하게 합니다.
    /// - Parameter text: 화면에 표시할 대본 문구입니다.
    /// - Returns: Dynamic Type과 다크 모드에 대응하는 본문 Text입니다.
    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// 실제 데이터 길이와 생각힌트 이모지 배치를 확인합니다.
#Preview("긴 본문") {
    ScrollView {
        ScriptPreviewBody(
            sentences: TaedamSessionInputDTO.mock.script.sentences,
            bucketListPrompt: TaedamSessionInputDTO.mock.script.bucketListPrompt,
            bucketListGuide: TaedamSessionInputDTO.mock.script.bucketListGuide
        )
        .padding(20)
    }
    .frame(width: 402, height: 430)
}

// 접근성 글자 크기와 다크 모드에서 semantic 본문 색과 줄바꿈을 확인합니다.
#Preview("접근성 글자와 다크 모드") {
    ScrollView {
        ScriptPreviewBody(
            sentences: TaedamSessionInputDTO.mock.script.sentences,
            bucketListPrompt: TaedamSessionInputDTO.mock.script.bucketListPrompt,
            bucketListGuide: TaedamSessionInputDTO.mock.script.bucketListGuide
        )
        .padding(20)
    }
    .frame(width: 402, height: 600)
    .environment(\.dynamicTypeSize, .accessibility2)
    .preferredColorScheme(.dark)
}
