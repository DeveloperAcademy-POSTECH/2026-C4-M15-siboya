//
//  TaedamResultView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

/// 방금 완료한 태담 정보와 사용자가 확정한 약속 하나를 보여주는 일회성 결과 화면입니다.
struct TaedamResultView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSnackbarPresented = false

    private let headerContent: ResultHeaderContent
    private let bucketListContent: String
    private let onComplete: () -> Void

    init(
        targetGestationalWeek: Int,
        title: String,
        artworkAssetName: String,
        bucketListContent: String,
        onComplete: @escaping () -> Void
    ) {
        headerContent = ResultHeaderContent(
            targetGestationalWeek: targetGestationalWeek,
            title: title,
            artworkAssetName: artworkAssetName
        )
        self.bucketListContent = bucketListContent
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            resultBackground

            resultContent
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(
                        title: "완료",
                        action: onComplete
                    )
                    .accessibilityIdentifier("taedam-result-complete")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
        }
        .overlay(alignment: .bottom) {
            if isSnackbarPresented {
                SavedBucketListSnackbar(
                    message: "소원 탭에 저장되었어요"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 92)
                .transition(snackbarTransition)
            }
        }
        .task {
            await presentSnackbar()
        }
        .accessibilityIdentifier("taedam-result")
    }

    private var resultBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Color.background

                Image("Taedam-BG")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .opacity(colorScheme == .dark ? 0.18 : 0.38)
            }
        }
        .ignoresSafeArea()
    }

    private var resultContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ResultHeaderView(content: headerContent)

                Color.clear
                    .frame(width: 1, height: 36)

                SavedBucketListCard(content: bucketListContent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 24)
        }
    }

    private var snackbarTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 8)),
            removal: .opacity
                .combined(
                    with: .scale(
                        scale: 0.98,
                        anchor: .center
                    )
                )
        )
    }

    @MainActor
    private func presentSnackbar() async {
        let showAnimation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(
                response: 0.35,
                dampingFraction: 0.82
            )

        withAnimation(showAnimation) {
            isSnackbarPresented = true
        }

        AccessibilityNotification
            .Announcement("소원 탭에 저장되었어요")
            .post()

        do {
            try await Task.sleep(for: .seconds(2))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: 0.2)) {
            isSnackbarPresented = false
        }
    }
}

#Preview("Long Promise") {
    TaedamResultView(
        targetGestationalWeek: 22,
        title: "일요일 아침 냄새",
        artworkAssetName: "TitleImage",
        bucketListContent: "일요일 아침마다 아빠가 직접 부드러운 계란말이와 따뜻한 빵을 준비해서 온 가족이 천천히 아침을 먹고 싶어.",
        onComplete: {}
    )
}

#Preview("Long Promise - Dark") {
    TaedamResultView(
        targetGestationalWeek: 22,
        title: "일요일 아침 냄새",
        artworkAssetName: "TitleImage",
        bucketListContent: "일요일 아침마다 아빠가 직접 부드러운 계란말이를 준비해 주고 싶어.",
        onComplete: {}
    )
    .preferredColorScheme(.dark)
}
