//
//  TaedamScriptTextStyle.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import UIKit

/// 일반 대본과 `bucketListPrompt`가 공통으로 사용하는 타이포그래피입니다.
private struct TaedamScriptTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 28, weight: .bold))
            .tracking(0.38)
            .lineSpacing(
                max(
                    0,
                    42 - UIFont.systemFont(
                        ofSize: 28,
                        weight: .bold
                    ).lineHeight
                )
            )
    }
}

extension View {
    /// SF Pro 28pt Bold, 42pt 행간과 0.38pt 자간을 적용합니다.
    func taedamScriptTextStyle() -> some View {
        modifier(TaedamScriptTextStyle())
    }
}
