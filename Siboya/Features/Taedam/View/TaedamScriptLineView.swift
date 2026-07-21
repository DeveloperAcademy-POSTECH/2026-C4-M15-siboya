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
                    .font(TaedamScriptTypography.font)
                    .tracking(TaedamScriptTypography.tracking)
                    .lineSpacing(TaedamScriptTypography.lineSpacing)
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(lineOpacity)
        .blur(radius: blurRadius)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectable else { return }
            onSelect()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("taedam-line-\(line.index)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint(isSelectable ? "이 문장부터 다시 시작하려면 이중 탭하세요" : "")
    }

    private var bucketListContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(spacing: 14) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.19))

                Text(bucketListGuide)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))

            Text(line.text)
                .font(TaedamScriptTypography.font)
                .tracking(TaedamScriptTypography.tracking)
                .lineSpacing(TaedamScriptTypography.lineSpacing)
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
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
            .font(TaedamScriptTypography.font)
            .tracking(TaedamScriptTypography.tracking)
            .lineSpacing(TaedamScriptTypography.lineSpacing)
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

private enum TaedamScriptTypography {
    static let font = Font.system(size: 28, weight: .bold)
    static let tracking: CGFloat = 0.38
    static let lineSpacing = max(
        0,
        42 - UIFont.systemFont(ofSize: 28, weight: .bold).lineHeight
    )
}
