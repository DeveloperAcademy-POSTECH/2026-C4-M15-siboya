//
//  ScriptPreviewHero.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// Home의 대본 미리보기 상단 배경, 대표 이미지, 주차와 제목을 하나의 시각적 영역으로 구성합니다.
struct ScriptPreviewHero: View {
    /// Hero 배경과 대표 이미지가 상태바 영역까지 이어지도록 무시할 안전 영역 방향입니다.
    static let ignoredSafeAreaEdges: Edge.Set = .top

    /// Figma에서 지정한 대표 이미지 한 변의 길이입니다.
    static let thumbnailSize: CGFloat = 132

    /// Figma에서 지정한 대표 이미지 모서리 반경입니다.
    static let thumbnailCornerRadius: CGFloat = 32

    /// 상단 배경이 차지하는 Figma 기준 높이입니다.
    private static let backgroundHeight: CGFloat = 396

    /// 표시 위치별 에셋 이름을 제공하는 대본 이미지 시리즈입니다.
    let artworkSeries: ScriptArtworkSeries

    /// Back 배경의 일러스트 상단을 보존하기 위해 Hero에서만 사용하는 이미지 채우기 기준입니다.
    let backgroundArtworkAlignment: Alignment = .top

    /// 사용자에게 보여줄 권장 임신 주차입니다.
    let targetGestationalWeek: Int

    /// 대표 이미지 아래에 보여줄 대본 제목입니다.
    let title: String

    /// 숫자 주차를 한국어 표시 문자열로 변환합니다.
    var weekText: String {
        "\(targetGestationalWeek)주차"
    }

    /// Back 이미지를 상단에 두고 Thumbnail과 텍스트를 전면에 배치합니다.
    var body: some View {
        ZStack(alignment: .top) {
            // 배경 이미지를 Hero 최상단에서 시작해 선택한 대본의 시각적 맥락을 제공합니다.
            ScriptArtworkView(
                assetName: artworkSeries.backgroundAssetName,
                cornerRadius: 0,
                imageAlignment: backgroundArtworkAlignment
            )
            .frame(maxWidth: .infinity)
            .frame(height: Self.backgroundHeight)

            // 아래 본문이 자연스럽게 이어지도록 시스템 배경색으로 점차 전환합니다.
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.backgroundHeight)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // 396px 1x 에셋을 디자인의 132pt 대표 이미지 프레임에 맞춰 축소합니다.
                ScriptArtworkView(
                    assetName: artworkSeries.thumbnailAssetName,
                    cornerRadius: Self.thumbnailCornerRadius
                )
                .frame(
                    width: Self.thumbnailSize,
                    height: Self.thumbnailSize
                )
                .padding(.top, 76)

                Text(weekText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryRed)
                    .padding(.top, 16)

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        // 기본 디자인 높이는 유지하되 접근성 글자 크기에서는 제목이 차지하는 만큼 확장합니다.
        .frame(minHeight: Self.backgroundHeight, alignment: .top)
        // 상위 화면과 단독 Preview 모두에서 Back 배경이 화면 물리적 최상단부터 이어지게 합니다.
        .ignoresSafeArea(edges: Self.ignoredSafeAreaEdges)
    }
}

// 실제 Thumbnail과 Back 에셋의 기본 배치를 확인합니다.
#Preview("기본 Hero") {
    ScriptPreviewHero(
        artworkSeries: .one,
        targetGestationalWeek: 22,
        title: "일요일 아침 냄새"
    )
    .frame(width: 402)
}

// 긴 제목과 접근성 글자 크기에서도 중앙 정보 계층을 확인합니다.
#Preview("긴 제목과 접근성 글자") {
    ScriptPreviewHero(
        artworkSeries: .seven,
        targetGestationalWeek: 22,
        title: "함께 맞이하고 싶은 평화로운 일요일 아침의 긴 이야기"
    )
    .frame(width: 402)
    .environment(\.dynamicTypeSize, .accessibility2)
    .preferredColorScheme(.dark)
}
