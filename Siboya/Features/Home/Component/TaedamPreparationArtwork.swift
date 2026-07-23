//
//  TaedamPreparationArtwork.swift
//  Siboya
//
//  Created by Codex on 7/23/26.
//

import SwiftUI

/// 준비자세 sheet에서 Asset Catalog의 프로필 일러스트를 표시합니다.
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

    /// `defaultAssetName`의 `img_profile` 이미지를 Figma의 90×88pt 영역에 표시합니다.
    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: Self.width, height: Self.height)
            .accessibilityHidden(true)
    }
}

// 등록된 준비자세 이미지의 Figma 크기와 비율을 확인합니다.
#Preview("준비자세 이미지") {
    TaedamPreparationArtwork()
        .padding()
}
