//
//  TaedamPreparationArtwork.swift
//  Siboya
//
//  Created by Codex on 7/23/26.
//

import SwiftUI
import UIKit

/// 준비자세 sheet에서 프로필 일러스트 또는 같은 크기의 대체 박스를 표시합니다.
struct TaedamPreparationArtwork: View {
    /// Figma가 지정한 프로필 일러스트 너비입니다.
    static let width: CGFloat = 90

    /// Figma가 지정한 프로필 일러스트 높이입니다.
    static let height: CGFloat = 88

    /// 에셋을 지정하지 않았을 때 사용할 준비자세 기본 이미지 이름입니다.
    static let defaultAssetName = "img_profile"

    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 기본 프로필 에셋 또는 테스트용 에셋 이름을 주입합니다.
    /// - Parameter assetName: Asset Catalog에서 찾을 이미지 이름입니다.
    init(assetName: String = Self.defaultAssetName) {
        self.assetName = assetName
    }

    /// 이미지 존재 여부와 무관하게 Figma의 90×88pt 레이아웃을 유지합니다.
    @ViewBuilder
    var body: some View {
        if let image = UIImage(named: assetName) {
            // 실제 일러스트 비율을 바꾸지 않고 지정된 프레임 안에 온전히 표시합니다.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: Self.width, height: Self.height)
                .accessibilityHidden(true)
        } else {
            // 아직 등록되지 않은 에셋도 화면 배치를 바꾸지 않도록 같은 크기의 박스로 대체합니다.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: Self.width, height: Self.height)
                .accessibilityHidden(true)
        }
    }
}

// 등록된 준비자세 이미지의 Figma 크기와 비율을 확인합니다.
#Preview("준비자세 이미지") {
    TaedamPreparationArtwork()
        .padding()
}
