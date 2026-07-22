//
//  HomeCategorySection.swift
//  Siboya
//

import SwiftUI

struct HomeCategorySection: View {
    let title: String
    let items: [HomeScriptItem]
    let onSelect: (UUID, Int) -> Void

    var hasContent: Bool {
        !items.isEmpty
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)

                VStack(spacing: 0) {
                    ForEach(
                        Array(items.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        HomeScriptRow(item: item, onSelect: onSelect)

                        if index < items.index(before: items.endIndex) {
                            Divider()
                                .padding(.leading, 75)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Category section") {
    HomeCategorySection(
        title: "멀리멀리 대모험",
        items: [
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "바다 냄새와 파도 소리",
                targetGestationalWeek: 20,
                artworkAssetName: "TitleImage2"
            ),
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "밤하늘의 불빛들",
                targetGestationalWeek: 20,
                artworkAssetName: "missing-script-artwork"
            )
        ],
        onSelect: { _, _ in }
    )
    .padding(20)
}
