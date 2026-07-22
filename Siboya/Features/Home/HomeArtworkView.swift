//
//  HomeArtworkView.swift
//  Siboya
//

import SwiftUI
import UIKit

struct HomeArtworkView: View {
    let assetName: String
    let cornerRadius: CGFloat

    var resolvedAssetName: String? {
        let trimmedName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    var resolvedImage: UIImage? {
        guard let resolvedAssetName else { return nil }
        return UIImage(named: resolvedAssetName)
    }

    var body: some View {
        Group {
            if let resolvedImage {
                Image(uiImage: resolvedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .accessibilityHidden(true)
    }
}

#Preview("등록된 이미지") {
    HomeArtworkView(assetName: "TitleImage2", cornerRadius: 20)
        .frame(width: 353, height: 230)
        .padding()
}

#Preview("없는 이미지") {
    HomeArtworkView(assetName: "missing-home-artwork", cornerRadius: 20)
        .frame(width: 353, height: 230)
        .padding()
}
