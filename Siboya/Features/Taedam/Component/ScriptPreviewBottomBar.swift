//
//  ScriptPreviewBottomBar.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// 스크롤 본문 위에 고정될 그라데이션과 준비하기 버튼을 제공하는 하단 컴포넌트입니다.
struct ScriptPreviewBottomBar: View {
    /// 준비자세 모달 등 다음 흐름을 결정할 상위 계층 callback입니다.
    let onPrepare: () -> Void

    /// 투명 그라데이션 아래에 기존 공통 `PrimaryButton`을 배치합니다.
    var body: some View {
        VStack(spacing: 0) {
            // 스크롤 끝과 고정 버튼이 갑자기 끊겨 보이지 않도록 시스템 배경으로 전환합니다.
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)
            .accessibilityHidden(true)

            PrimaryButton(
                title: "준비하기",
                action: prepare
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
        }
    }

    /// 버튼 선택을 저장·권한 로직 없이 상위 흐름에 그대로 전달합니다.
    func prepare() {
        onPrepare()
    }
}

// 실제 공통 버튼과 하단 그라데이션 배치를 확인합니다.
#Preview("준비하기 하단 바") {
    ScriptPreviewBottomBar(onPrepare: {})
        .frame(width: 402)
}
