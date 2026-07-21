//
//  SavedPromiseCard.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

struct SavedBucketListCard: View {
    // SwiftData에 저장된 실제 약속 모델, 값을 수정하지 않고 읽기만 한다.
    let item: BucketListItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle
            
            // 약속이 만들어진 태담의 카데고리
            Text(item.category)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // STT 이후 사용자가 키보드로 최종 확인한 문장
            Text(item.content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(
                    horizontal: false, vertical: true
                )
                .accessibilityLabel("저장된 약속")
                .accessibilityValue(item.content)
        
            completionStatus
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
    
    private var completionStatus: some View {
        Label(
            item.isCompleted ? "완료한 약속" : "진행 전",
            systemImage: item.isCompleted
            ? "checkmark.circle.fill" : "circle"
        )
        .font(.subheadline)
        .foregroundStyle(item.isCompleted ? Color.blue : Color.secondary)
    }
}

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()

        SavedBucketListCard(
            item: BucketListItem(
                category: "아기사랑",
                content: "메론빵 만들어주기"
            )
        )
        .padding(24)
    }
}
