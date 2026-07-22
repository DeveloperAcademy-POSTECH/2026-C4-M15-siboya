//
//  HomeScriptRow.swift
//  Siboya
//

import SwiftUI

struct HomeScriptRow: View {
    let item: HomeScriptItem
    let onSelect: (UUID, Int) -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 9) {
                HomeArtworkView(
                    assetName: item.artworkAssetName,
                    cornerRadius: 17
                )
                .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)

                    Text(item.gestationalWeekText)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 80,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.gestationalWeekText)
    }

    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}

#Preview("Script row with placeholder") {
    HomeScriptRow(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "조용한 도서관 구석에서",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(.horizontal, 20)
}
