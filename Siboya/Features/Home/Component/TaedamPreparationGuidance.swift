//
//  TaedamPreparationGuidance.swift
//  Siboya
//
//  Created by Codex on 7/23/26.
//

import SwiftUI

/// 준비자세 제목과 태명이 치환된 행동 안내를 Figma의 텍스트 계층으로 표시합니다.
struct TaedamPreparationGuidance: View {
    /// Figma에서 제목과 안내 사이에 둔 간격입니다.
    static let textSpacing: CGFloat = 8

    /// Figma Title1/Emphasized에 해당하는 제목 글자 크기입니다.
    static let titleFontSize: CGFloat = 28

    /// Figma Title2/Regular에 해당하는 안내 글자 크기입니다.
    static let instructionFontSize: CGFloat = 22

    /// 실제 사용자에게 전달할 태명을 포함한 안내 문구입니다.
    let instructionText: String

    /// 태명을 한 번 치환해 화면 갱신 동안 같은 안내를 유지합니다.
    /// - Parameter babyNickname: 준비 안내 두 번째 줄에 표시할 태명입니다.
    init(babyNickname: String) {
        instructionText = "아내의 배에 손을 얹고\n\(babyNickname)와 교감할 준비가 되면\n시작 버튼을 눌러주세요"
    }

    /// 제목과 세 줄 안내를 가운데 정렬해 읽기 순서를 유지합니다.
    var body: some View {
        VStack(spacing: Self.textSpacing) {
            Text("태담 준비하기")
                .font(.system(size: Self.titleFontSize, weight: .bold))
                .tracking(0.38)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier("TaedamPreparationTitle")

            Text(instructionText)
                .font(.system(size: Self.instructionFontSize, weight: .regular))
                .tracking(-0.26)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("TaedamPreparationInstruction")
        }
        .frame(maxWidth: .infinity)
    }
}

// 태명이 치환된 제목과 세 줄 안내의 균형을 확인합니다.
#Preview("준비자세 안내") {
    TaedamPreparationGuidance(babyNickname: "꾹꾹이")
        .padding()
}
