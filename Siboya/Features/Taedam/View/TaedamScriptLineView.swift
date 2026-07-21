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
    let bucketListText: String
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
                    .foregroundStyle(.black)
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
                    .foregroundStyle(
                        Color(
                            red: 60.0 / 255.0,
                            green: 60.0 / 255.0,
                            blue: 67.0 / 255.0
                        )
                        .opacity(0.6)
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture {
                bucketListEditorFocus.wrappedValue = false
            }

            if isBucketListEditing {
                TaedamBucketListEditor(
                    text: $editedBucketListText,
                    placeholder: line.text,
                    focus: bucketListEditorFocus
                )
            } else {
                Text(bucketListText)
                    .taedamScriptTextStyle()
                    .foregroundStyle(
                        Color(
                            red: 38.0 / 255.0,
                            green: 38.0 / 255.0,
                            blue: 38.0 / 255.0
                        )
                        .opacity(0.2)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
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
            character.foregroundColor = .black.opacity(opacity)
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
