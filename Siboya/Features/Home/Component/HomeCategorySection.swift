//
//  HomeCategorySection.swift
//  Siboya
//

import SwiftUI

/// 같은 카테고리에 속한 태담 대본을 제목과 행 목록으로 묶어 표시하는 섹션입니다.
struct HomeCategorySection: View {
    /// 섹션 상단에 표시할 카테고리 이름입니다.
    let title: String

    /// 입력 순서대로 표시할 태담 대본 목록입니다.
    let items: [HomeScriptItem]

    /// 사용자가 행을 선택했을 때 대본 식별자와 버전을 전달하는 콜백입니다.
    let onSelect: (UUID, Int) -> Void

    /// 빈 카테고리의 제목만 화면에 남지 않도록 섹션 표시 여부를 결정합니다.
    var hasContent: Bool {
        !items.isEmpty
    }

    /// 내용이 있을 때만 카테고리 제목과 대본 행 목록을 구성합니다.
    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                // 사용자가 목록의 주제를 먼저 파악할 수 있도록 카테고리 제목을 표시합니다.
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)

                VStack(spacing: 0) {
                    // 원본 배열의 순서와 행 위치를 함께 사용해 행 사이에만 구분선을 넣습니다.
                    ForEach(
                        Array(items.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        HomeScriptRow(item: item, onSelect: onSelect)

                        if index < items.index(before: items.endIndex) {
                            // 첫 번째 이미지 영역을 피하도록 구분선의 시작점을 본문 쪽으로 이동합니다.
                            Divider()
                                .padding(.leading, 75)
                        }
                    }
                }
            }
        }
    }
}

// 서로 다른 실제 에셋을 사용하는 두 행의 카테고리 배치를 확인합니다.
#Preview("Category section") {
    HomeCategorySection(
        title: "멀리멀리 대모험",
        items: [
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "바다 냄새와 파도 소리",
                targetGestationalWeek: 20,
                artworkSeries: .two
            ),
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "밤하늘의 불빛들",
                targetGestationalWeek: 20,
                artworkSeries: .seven
            )
        ],
        onSelect: { _, _ in }
    )
    .padding(20)
}
