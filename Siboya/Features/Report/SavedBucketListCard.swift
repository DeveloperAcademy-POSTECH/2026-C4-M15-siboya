//
//  SavedBucketListCard.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

/// 태담 직후 사용자가 최종 확정한 약속 하나를 표시합니다.
struct SavedBucketListCard: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle

            Text("방금 전 태담에서 아이와 함께하고 싶은 일을 담았어요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text(content)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("저장된 약속")
                .accessibilityValue(content)
                .accessibilityIdentifier("taedam-result-bucket-list")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            Color.background.opacity(0.96),
            in: RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 16,
            y: 6
        )
    }

    private var cardTitle: some View {
        Label {
            Text("저장된 약속")
        } icon: {
            Image(systemName: "list.bullet")
                .accessibilityHidden(true)
        }
        .font(.subheadline)
        .foregroundStyle(Color.brandPrimary)
    }
}

#Preview("Long Promise") {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()

        SavedBucketListCard(
            content: "일요일 아침마다 아빠가 직접 부드러운 계란말이와 따뜻한 빵을 준비해서 온 가족이 함께 천천히 아침을 먹고 싶어."
        )
        .padding(24)
    }
}
