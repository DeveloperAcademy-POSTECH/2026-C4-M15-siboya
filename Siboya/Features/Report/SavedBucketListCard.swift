//
//  SavedPromiseCard.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

struct SavedBucketListCard: View {
    let summary: String
    let promise: TaedamActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle
            
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            Text(promise.title)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("저장된 약속")
                .accessibilityValue(promise.title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            Color(.systemBackground).opacity(0.96),
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
        .foregroundStyle(Color(.systemRed))
    }
}

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()
        
        SavedBucketListCard(
            summary: "방금 전 태담 속 아이와 함께하고 싶은 일을 담았어요",
            promise: TaedamActionItem(
                id: UUID(),
                title: "메론빵과 소금빵과 붕어빵 만들어주기"
            )
        )
        .padding(24)
    }
}
