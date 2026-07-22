//
//  ScriptPreviewDuration.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// Home의 대본 미리보기에서 예상 소요 초를 읽기 쉬운 분 단위로 보여주는 컴포넌트입니다.
struct ScriptPreviewDuration: View {
    /// 세로 장식선이 차지하는 고정 두께입니다.
    static let separatorThickness: CGFloat = 1

    /// 번들 대본이 제공하는 선택적 예상 소요 시간입니다.
    let estimatedDurationSeconds: Int?

    /// 초를 60초 단위로 올림해 만든 표시 문자열이며 값이 없으면 영역을 숨깁니다.
    var durationText: String? {
        guard let seconds = estimatedDurationSeconds else { return nil }

        // 나머지가 있을 때만 1분을 더해 61초가 2분으로 보이도록 합니다.
        let minutes = seconds / 60 + (seconds.isMultiple(of: 60) ? 0 : 1)
        return "약 \(minutes)분"
    }

    /// 값이 있을 때 두 텍스트 전체를 양쪽 세로선으로 감싸 가운데 정렬합니다.
    @ViewBuilder
    var body: some View {
        if let durationText {
            VStack(spacing: 4) {
                Text("소요시간")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                Text(durationText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
            }
            // 텍스트와 선 사이에 여백을 두고 양쪽 선은 텍스트 묶음의 전체 높이를 따릅니다.
            .padding(.horizontal, 12)
            .overlay(alignment: .leading) { separator }
            .overlay(alignment: .trailing) { separator }
            .accessibilityElement(children: .combine)
        }
    }

    /// 부모 텍스트 묶음이 제안한 전체 높이를 채우는 1pt 세로 장식선입니다.
    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: Self.separatorThickness)
            .accessibilityHidden(true)
    }
}

// 초 단위 올림 결과와 가운데 정렬을 확인합니다.
#Preview("61초") {
    ScriptPreviewDuration(estimatedDurationSeconds: 61)
        .padding()
}
