//
//  TaedamPreparationStartButton.swift
//  Siboya
//
//  Created by Codex on 7/23/26.
//

import SwiftUI

/// 준비자세 sheet 하단에서 시작 callback과 권한 요청 로딩 상태를 표시합니다.
struct TaedamPreparationStartButton: View {
    /// Figma ready 버튼의 고정 높이입니다.
    static let height: CGFloat = 52

    /// 권한 요청 중 버튼을 비활성화하고 진행 표시로 바꿀 상태입니다.
    let isLoading: Bool

    /// 실제 권한 확인을 상위 흐름에 요청할 callback입니다.
    let action: () -> Void

    /// 로딩 중 중복 탭을 막기 위해 계산한 입력 가능 상태입니다.
    var isEnabled: Bool {
        !isLoading
    }

    /// 버튼 입력을 별도 메서드로 전달해 View가 권한 API를 직접 소유하지 않게 합니다.
    func start() {
        action()
    }

    /// Figma의 52pt capsule과 프로젝트 강조색으로 시작 동작을 표시합니다.
    var body: some View {
        Button(action: start) {
            Group {
                if isLoading {
                    // 시스템 권한 응답을 기다리는 동안 현재 처리가 진행 중임을 알립니다.
                    ProgressView()
                        .tint(.white)
                        .accessibilityHidden(true)
                } else {
                    Text("시작하기")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .foregroundStyle(Color.white)
        .background(
            isEnabled ? Color.primaryRed : Color.gray.opacity(0.4),
            in: Capsule()
        )
        .disabled(!isEnabled)
        .accessibilityLabel("시작하기")
        .accessibilityValue(isLoading ? "처리 중" : "")
        .accessibilityIdentifier("TaedamPreparationStartButton")
    }
}

// 일반 상태와 권한 요청 중 표시를 함께 확인합니다.
#Preview("준비자세 시작") {
    VStack(spacing: 16) {
        TaedamPreparationStartButton(isLoading: false, action: {})
        TaedamPreparationStartButton(isLoading: true, action: {})
    }
    .padding()
}
