//
//  HomeScriptRow.swift
//  Siboya
//

import SwiftUI

/// 태담 대표 이미지, 제목, 권장 임신 주차를 한 줄로 보여주는 선택 가능한 행입니다.
struct HomeScriptRow: View {
    /// 행에 표시할 태담 대본 정보입니다.
    let item: HomeScriptItem

    /// 행 선택 시 대본 식별자와 버전을 상위 화면에 전달하는 콜백입니다.
    let onSelect: (UUID, Int) -> Void

    /// 행 전체를 버튼으로 구성해 좁은 텍스트 영역이 아닌 한 줄 전체를 터치할 수 있게 합니다.
    var body: some View {
        Button(action: select) {
            HStack(spacing: 9) {
                // 목록에서 빠르게 대본을 구분할 수 있도록 정사각형 대표 이미지를 표시합니다.
                HomeArtworkView(
                    assetName: item.artworkAssetName,
                    cornerRadius: 17
                )
                .frame(width: 66, height: 66)

                // 제목과 권장 임신 주차를 정보 우선순위에 맞춰 세로로 배치합니다.
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

    /// 동일한 대본의 버전을 구분할 수 있도록 UUID와 버전을 함께 전달합니다.
    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}

// 이미지가 없는 경우에도 행의 크기와 텍스트 배치가 유지되는지 확인합니다.
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
