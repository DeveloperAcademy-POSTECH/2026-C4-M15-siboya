//
//  TaedamResultView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct TaedamResultView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isSnackbarPresented = false

    let result: SavedBucketListDTO
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image("Taedam-BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.38)

            ScrollView {
                VStack(spacing: 0) {
                    ResultHeaderView(
                        week: result.week,
                        theme: result.theme,
                        imageName: result.imageName
                    )

                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 36)

                    SavedPromiseCard(
                        summary: result.summary,
                        promise: result.promise
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "완료",
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .overlay(alignment: .bottom) {
            if isSnackbarPresented {
                SavedPromiseSnackbar(
                    message: "약속탭에 저장되었어요"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 92)
                .transition(snackbarTransition)
                .zIndex(1)
            }
        }
        .task {
            await presentSnackbar()
        }
    }

    private var snackbarTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .move(edge: .bottom)
            .combined(with: .opacity)
    }

    @MainActor
    private func presentSnackbar() async {
        let showAnimation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.35, dampingFraction: 0.82)

        withAnimation(showAnimation) {
            isSnackbarPresented = true
        }

        AccessibilityNotification
            .Announcement("약속탭에 저장되었어요")
            .post()

        do {
            try await Task.sleep(for: .seconds(2))
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        withAnimation(.easeIn(duration: 0.2)) {
            isSnackbarPresented = false //true 
        }
    }
}

#Preview {
    TaedamResultView(
        result: TaedamResultData(
                    week: 22,
                    theme: "일요일 아침",
                    summary: "방금 전 태담 속 아이와 함께하고 싶은 일을 담았어요.",
                    promise:
                        TaedamActionItem(
                            id: UUID(),
                            title: "메론빵 만들어주기"
                        ),
                    imageName: "TitleImage"
                ),
                onComplete: {}
    )
}
