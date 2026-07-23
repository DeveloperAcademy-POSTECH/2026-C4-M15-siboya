//
//  PrimaryBottomButton.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .accessibilityHidden(true)
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            // 버튼 레이블 자체를 시각적 캡슐 크기로 확장해 빈 여백도 터치 영역에 포함합니다.
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .foregroundStyle(.white)
            .background(
                isEnabled ? Color.brandPrimary : Color.textDisabled,
                in: Capsule()
            )
            .contentShape([.interaction, .accessibility], Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "처리 중" : "")
    }
}

#Preview {
    PrimaryButton(
        title: "완료",
        action: {}
    )
    .padding()
}
