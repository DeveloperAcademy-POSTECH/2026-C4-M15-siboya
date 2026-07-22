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
    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 실제 이미지와 플레이스홀더에 동일하게 적용할 모서리 반경입니다.
    let cornerRadius: CGFloat

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
