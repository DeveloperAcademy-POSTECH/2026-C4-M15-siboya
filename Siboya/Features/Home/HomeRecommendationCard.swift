//
//  HomeRecommendationCard.swift
//  Siboya
//

import SwiftUI

struct HomeRecommendationCard: View {
    let item: HomeScriptItem
    let onSelect: (UUID, Int) -> Void

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottomLeading) {
                HomeArtworkView(
                    assetName: item.artworkAssetName,
                    cornerRadius: 20
                )

                LinearGradient(
                    colors: [
                        .clear,
                        Color(.systemBackground).opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 230)
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

    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}

#Preview("Recommendation with placeholder") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
}

#Preview("Recommendation in dark mode") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
    .preferredColorScheme(.dark)
}

#Preview("Recommendation with accessibility text") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리가 들리는 긴 여행 이야기",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
    .environment(\.dynamicTypeSize, .accessibility3)
}
