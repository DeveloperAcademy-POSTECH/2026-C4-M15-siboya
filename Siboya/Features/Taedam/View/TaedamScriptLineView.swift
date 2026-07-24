//
//  TaedamScriptLineView.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI
import UIKit

struct TaedamScriptLineView: View {
    let line: TaedamLineDTO
    let currentLineIndex: Int?
    let progress: Double
    let bucketListGuide: String
    let bucketListSpeechPlaceholder: String
    let bucketListTranscript: String
    let showsBucketListSpeechPlaceholder: Bool
    @Binding var editedBucketListText: String
    let isBucketListEditing: Bool
    let bucketListEditorFocus: FocusState<Bool>.Binding
    let isSelectable: Bool
    let onSelect: () -> Void

    private var isCurrent: Bool {
        currentLineIndex == line.index
    }

    private var distanceFromCurrent: Int? {
        guard let currentLineIndex else { return nil }
        return abs(currentLineIndex - line.index)
    }

    var body: some View {
        Group {
            if isSelectable {
                Button {
                    bucketListEditorFocus.wrappedValue = false
                    onSelect()
                } label: {
                    lineContent
                }
                .buttonStyle(.plain)
            } else {
                lineContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(lineOpacity)
        .blur(radius: blurRadius)
        .accessibilityElement(
            children: isBucketListEditing ? .contain : .combine
        )
        .accessibilityIdentifier("taedam-line-\(line.index)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint(isSelectable ? "이 문장부터 다시 시작하려면 이중 탭하세요" : "")
    }

    @ViewBuilder
    private var lineContent: some View {
        Group {
            if line.kind == .bucketList, isCurrent {
                bucketListContent
            } else if isCurrent {
                KaraokeText(text: line.text, progress: progress)
                    .animation(
                        .linear(duration: KaraokeAnimation.duration),
                        value: progress
                    )
            } else {
                Text(line.text)
                    .taedamScriptTextStyle()
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var bucketListContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(spacing: 14) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.19))

                Text(bucketListGuide)
                    .font(TaedamBucketListGuideTypography.font)
                    .tracking(TaedamBucketListGuideTypography.tracking)
                    .lineSpacing(TaedamBucketListGuideTypography.lineSpacing)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .background(
                Color.textPrimary.opacity(0.025),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                bucketListEditorFocus.wrappedValue = false
            }

            VStack(alignment: .leading, spacing: 12) {
                // 버킷리스트 고정 도입문도 일반 대본과 같은 Karaoke 진행률로 채웁니다.
                KaraokeText(text: line.text, progress: progress)
                    .animation(
                        .linear(duration: KaraokeAnimation.duration),
                        value: progress
                    )

                bucketListSpeechArea

                if showsBucketListSpeechPlaceholder {
                    // 발화를 시작하기 전까지만 마지막 안내 문장을 흐리게 표시합니다.
                    Text(bucketListSpeechPlaceholder)
                        .taedamScriptTextStyle()
                        .foregroundStyle(Color.textPrimary.opacity(0.2))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var bucketListSpeechArea: some View {
        if showsBucketListSpeechPlaceholder {
            // 발화문 한 줄이 들어갈 자리를 미리 확보해 안내 문장의 위치를 고정합니다.
            Color.clear
                .frame(height: 42)
                .accessibilityHidden(true)
        } else if isBucketListEditing {
            TaedamBucketListEditor(
                text: $editedBucketListText,
                placeholder: "",
                focus: bucketListEditorFocus
            )
        } else if !bucketListTranscript.isEmpty {
            // STT가 전달한 사용자의 중간 문장만 강조색으로 실시간 표시합니다.
            Text(bucketListTranscript)
                .taedamScriptTextStyle()
                .foregroundStyle(Color.brandPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 42, alignment: .topLeading)
        } else {
            // STT가 시작되고 첫 전사문이 오기 전에도 발화 영역의 높이를 유지합니다.
            Color.clear
                .frame(height: 42)
                .accessibilityHidden(true)
        }
    }

    private var lineOpacity: Double {
        guard !isCurrent else { return 1 }

        switch distanceFromCurrent {
        case 1:
            return 0.11
        case 2:
            return 0.07
        default:
            return 0.045
        }
    }

    private var blurRadius: CGFloat {
        guard !isCurrent else { return 0 }

        switch distanceFromCurrent {
        case 1:
            return 1.1
        case 2:
            return 1.7
        default:
            return 2.2
        }
    }
}

private struct KaraokeText: View, Animatable {
    let text: String
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Text(animatedText)
            .taedamScriptTextStyle()
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }

    private var animatedText: AttributedString {
        let characters = Array(text)
        let normalizedProgress = min(max(progress, 0), 1)
        let filledPosition = Double(characters.count) * normalizedProgress

        return characters.enumerated().reduce(into: AttributedString()) { result, item in
            let characterProgress = min(
                max(filledPosition - Double(item.offset), 0),
                1
            )
            let opacity = KaraokeAnimation.inactiveTextOpacity +
                ((1 - KaraokeAnimation.inactiveTextOpacity) * characterProgress)
            var character = AttributedString(String(item.element))
            character.foregroundColor = Color.textPrimary.opacity(opacity)
            result.append(character)
        }
    }
}

private enum KaraokeAnimation {
    static let duration = 0.08
    static let inactiveTextOpacity = 0.15
}

private enum TaedamBucketListGuideTypography {
    static let font = Font.system(size: 20, weight: .regular)
    static let tracking: CGFloat = -1
    static let lineSpacing = max(
        0,
        30 - UIFont.systemFont(ofSize: 20, weight: .regular).lineHeight
    )
}
