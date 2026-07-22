//
//  ScriptArtworkView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import UIKit

/// Home에서 대본 이미지를 표시하고 찾지 못하면 같은 영역을 박스로 유지하는 공통 뷰입니다.
struct ScriptArtworkView: View {
    /// 카드·행·썸네일이 기존과 같은 중앙 기준으로 이미지를 잘라 보이도록 하는 기본 정렬값입니다.
    static let defaultImageAlignment: Alignment = .center

    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 실제 이미지와 플레이스홀더에 동일하게 적용할 모서리 반경입니다.
    let cornerRadius: CGFloat

    /// 프레임보다 큰 이미지를 채울 때 기준이 되는 위치이며, Hero만 상단 정렬을 전달합니다.
    let imageAlignment: Alignment

    /// 에셋 이름·모서리·이미지 정렬 기준으로 공통 이미지를 생성합니다.
    /// - Parameters:
    ///   - assetName: Asset Catalog에서 조회할 이미지 이름입니다.
    ///   - cornerRadius: 실제 이미지와 플레이스홀더에 적용할 모서리 반경입니다.
    ///   - imageAlignment: 채우기 과정에서 남는 이미지를 배치할 기준이며 기본값은 중앙입니다.
    init(
        assetName: String,
        cornerRadius: CGFloat,
        imageAlignment: Alignment = Self.defaultImageAlignment
    ) {
        self.assetName = assetName
        self.cornerRadius = cornerRadius
        self.imageAlignment = imageAlignment
    }

    /// 공백 이름으로 이미지 조회를 시도하지 않도록 정리한 에셋 이름입니다.
    var resolvedAssetName: String? {
        let trimmedName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    /// 정리된 이름으로 불러온 이미지이며 등록되지 않았으면 `nil`입니다.
    var resolvedImage: UIImage? {
        guard let resolvedAssetName else { return nil }
        return UIImage(named: resolvedAssetName)
    }

    /// 이미지 존재 여부에 따라 실제 이미지 또는 중립적인 플레이스홀더를 표시합니다.
    var body: some View {
        Group {
            if let resolvedImage {
                // 부모가 정한 프레임을 채우고 넘치는 부분을 잘라 표시 위치별 크기 차이를 흡수합니다.
                Image(uiImage: resolvedImage)
                    .resizable()
                    .scaledToFill()
                    // 기본은 중앙 크롭을 유지하고, Hero가 전달한 경우에만 Back 이미지의 상단을 보존합니다.
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: imageAlignment
                    )
            } else {
                // 에셋이 준비되지 않아도 화면의 크기와 배치가 유지되도록 박스로 대체합니다.
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

// 실제 등록된 132pt Thumbnail 에셋을 확인합니다.
#Preview("등록된 이미지") {
    ScriptArtworkView(
        assetName: "TitleImage2Thumbnail",
        cornerRadius: 32
    )
    .frame(width: 132, height: 132)
    .padding()
}

// 누락 에셋이 동일 크기의 플레이스홀더로 대체되는지 확인합니다.
#Preview("없는 이미지") {
    ScriptArtworkView(
        assetName: "missing-script-artwork",
        cornerRadius: 32
    )
    .frame(width: 132, height: 132)
    .padding()
}
