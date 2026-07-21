//
//  ResultHeaderView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct ResultHeaderContent: Equatable, Sendable {
    let targetGestationalWeek: Int
    let title: String
    let artworkAssetName: String
}

struct ResultHeaderView: View {
    let content: ResultHeaderContent

    var body: some View {
        VStack(spacing: 12) {
            Image(content.artworkAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 144, height: 144)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 32,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            Text("\(content.targetGestationalWeek)주차")
                .font(.title3)
                .foregroundStyle(Color.primaryRed)

            Text(content.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

#Preview("Existing Artwork") {
    ResultHeaderView(
        content: ResultHeaderContent(
            targetGestationalWeek: 22,
            title: "일요일 아침 냄새",
            artworkAssetName: "TitleImage"
        )
    )
}
