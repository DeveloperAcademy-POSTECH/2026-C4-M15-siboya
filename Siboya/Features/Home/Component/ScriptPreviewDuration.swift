//
//  ScriptPreviewDuration.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// Home의 대본 미리보기에서 예상 소요 초를 읽기 쉬운 분 단위로 보여주는 컴포넌트입니다.
struct ScriptPreviewDuration: View {
    /// SSD가 승인한 세로 장식선의 고정 두께입니다.
    static let separatorThickness: CGFloat = 1

    /// Figma에서 양쪽 장식선이 차지하는 세로 길이입니다.
    static let separatorHeight: CGFloat = 35

    /// Figma에서 장식선과 중앙 텍스트 영역 사이에 둔 간격입니다.
    static let itemSpacing: CGFloat = 18

    /// 일반 글자 크기에서 중앙 정보 영역이 유지할 최소 너비입니다.
    static let contentMinimumWidth: CGFloat = 73

    /// 중앙 정보 영역이 텍스트 둘레에 제공하는 Figma 기준 여백입니다.
    static let contentPadding: CGFloat = 10

    /// 번들 대본이 제공하는 선택적 예상 소요 시간입니다.
    let estimatedDurationSeconds: Int?

    /// 초를 60초 단위로 올림해 만든 표시 문자열이며 값이 없으면 영역을 숨깁니다.
    var durationText: String? {
        guard let seconds = estimatedDurationSeconds else { return nil }

        // 나머지가 있을 때만 1분을 더해 61초가 2분으로 보이도록 합니다.
        let minutes = seconds / 60 + (seconds.isMultiple(of: 60) ? 0 : 1)
        return "약 \(minutes)분"
    }

    /// 값이 있을 때 확대된 중앙 텍스트 영역을 양쪽 세로선으로 감싸 가운데 정렬합니다.
    @ViewBuilder
    var body: some View {
        if let durationText {
            HStack(spacing: Self.itemSpacing) {
                separator

                VStack(spacing: 4) {
                    Text("소요시간")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)

                    Text(durationText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                }
                // 일반 크기에서는 Figma의 73pt를 지키고 접근성 글자 크기에서는 필요한 만큼 확장합니다.
                .padding(Self.contentPadding)
                .frame(minWidth: Self.contentMinimumWidth)
                // 현재 글꼴 메트릭이 작아도 Figma에서 정한 67pt 기본 높이를 유지합니다.
                .frame(minHeight: 67)

                separator
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Figma 높이와 SSD 두께를 함께 적용한 세로 장식선입니다.
    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(
                width: Self.separatorThickness,
                height: Self.separatorHeight
            )
            .accessibilityHidden(true)
    }
}

// 초 단위 올림 결과와 가운데 정렬을 확인합니다.
#Preview("61초") {
    ScriptPreviewDuration(estimatedDurationSeconds: 61)
        .padding()
}
