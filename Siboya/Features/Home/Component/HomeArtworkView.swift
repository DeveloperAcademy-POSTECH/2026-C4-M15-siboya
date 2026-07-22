//
//  HomeArtworkView.swift
//  Siboya
//

import SwiftUI
import UIKit

/// Asset Catalog의 이미지를 표시하고, 이미지를 찾지 못하면 같은 영역을 플레이스홀더로 채우는 공통 뷰입니다.
struct HomeArtworkView: View {
    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 실제 이미지와 플레이스홀더에 동일하게 적용할 모서리 반경입니다.
    let cornerRadius: CGFloat

    /// 공백뿐인 이름으로 이미지 조회를 시도하지 않도록 정리한 에셋 이름입니다.
    var resolvedAssetName: String? {
        let trimmedName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    /// 정리된 에셋 이름으로 불러온 이미지이며, 등록되지 않은 이름이면 `nil`입니다.
    var resolvedImage: UIImage? {
        guard let resolvedAssetName else { return nil }
        return UIImage(named: resolvedAssetName)
    }

    /// 이미지의 존재 여부에 따라 실제 이미지 또는 중립적인 플레이스홀더를 표시합니다.
    var body: some View {
        Group {
            if let resolvedImage {
                // 부모가 정한 프레임을 채우도록 이미지를 확대하고 넘치는 영역은 잘라냅니다.
                Image(uiImage: resolvedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // 이미지가 아직 준비되지 않아도 화면의 크기와 배치가 유지되도록 박스로 대체합니다.
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

// 실제 등록된 에셋이 카드 크기에서 어떻게 보이는지 확인합니다.
#Preview("등록된 이미지") {
    HomeArtworkView(assetName: "TitleImage2", cornerRadius: 20)
        .frame(width: 353, height: 230)
        .padding()
}

// 존재하지 않는 에셋이 플레이스홀더로 대체되는지 확인합니다.
#Preview("없는 이미지") {
    HomeArtworkView(assetName: "missing-home-artwork", cornerRadius: 20)
        .frame(width: 353, height: 230)
        .padding()
}
