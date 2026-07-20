//
//  TaedamResultView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct TaedamResultView: View {
    @State private var viewModel: TaedamResultViewModel
    
    let onComplete: () -> Void
    
    init(
            result: TaedamResultData,
            onComplete: @escaping () -> Void
        ) {
            _viewModel = State(
                initialValue: TaedamResultViewModel(result: result)
            )
            self.onComplete = onComplete
        }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("Taedam-BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)
                .opacity(0.38)
            
            ScrollView {
                VStack(spacing: 0) {
                    ResultHeaderView(
                        // viewModel.result.week/question/imageName으로 수정하기
                        week: viewModel.result.week,
                        theme: viewModel.result.theme,
                        imageName: viewModel.result.imageName
                    )
                    
                    SavedActionListCard(
                        summary: viewModel.result.summary,
                        actionItems: viewModel.result.actionItems
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                        PrimaryButton(
                            title: "완료",
                            action: onComplete
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    .task {
                        await viewModel.showSavedToastIfNeeded()
                    }
        }
    }
}

#Preview {
    TaedamResultView(
        result: TaedamResultData(
                    week: 22,
                    theme: "일요일 아침",
                    summary: "방금 전 태담 속 아이와 함께하고 싶은 일을 담았어요.",
                    actionItems: [
                        TaedamActionItem(
                            id: UUID(),
                            title: "메론빵 만들어주기"
                        ),
                        TaedamActionItem(
                            id: UUID(),
                            title: "함께 축구 경기 보러 가기"
                        )
                    ],
                    imageName: "TitleImage"
                ),
                onComplete: {}
    )
}
