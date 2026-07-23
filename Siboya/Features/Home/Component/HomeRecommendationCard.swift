//
//  HomeRecommendationCard.swift
//  Siboya
//

import SwiftUI

/// 이번 주 추천 태담을 이미지와 제목으로 강조해 보여주는 전체 너비 카드입니다.
struct HomeRecommendationCard: View {
    /// 디자인 규격에 따라 카드가 항상 유지해야 하는 고정 높이입니다.
    static let height: CGFloat = 230

    /// 카드에 표시할 태담 대본 정보입니다.
    let item: HomeScriptItem

    /// 카드 선택 시 대본 식별자와 버전을 상위 화면에 전달하는 콜백입니다.
    let onSelect: (UUID, Int) -> Void

    /// 카드 전체를 하나의 버튼으로 구성해 이미지나 제목 어느 곳을 눌러도 선택되게 합니다.
    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottomLeading) {
                // 추천 대본의 대표 이미지를 카드 배경 전체에 표시합니다.
                ScriptArtworkView(
                    assetName: item.cardArtworkAssetName,
                    cornerRadius: 20
                )

                // 이미지 위에서도 하단 제목이 읽히도록 시스템 배경색으로 자연스럽게 덮습니다.
                LinearGradient(
                    colors: [
                        .clear,
                        Color.background.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 추천 대본 제목을 카드의 주요 정보로 하단에 배치합니다.
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .clipShape(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .contentShape(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: .black.opacity(0.06), radius: 9)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
    }

    /// 선택된 대본을 정확한 버전으로 열 수 있도록 UUID와 버전을 함께 전달합니다.
    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}

// 등록된 카드 전용 이미지와 하단 제목 배치를 확인합니다.
#Preview("Recommendation with image") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리",
            targetGestationalWeek: 20,
            artworkSeries: .one
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
}

// 시스템 배경색 그라데이션과 제목이 다크 모드에서도 구분되는지 확인합니다.
#Preview("Recommendation in dark mode") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리",
            targetGestationalWeek: 20,
            artworkSeries: .two
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
    .preferredColorScheme(.dark)
}

// 접근성 글자 크기에서 고정 높이 카드의 제목 배치를 확인합니다.
#Preview("Recommendation with accessibility text") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리가 들리는 긴 여행 이야기",
            targetGestationalWeek: 20,
            artworkSeries: .three
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
    .environment(\.dynamicTypeSize, .accessibility3)
}
