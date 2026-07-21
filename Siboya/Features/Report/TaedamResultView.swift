//
//  TaedamResultView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftData
import SwiftUI

struct TaedamResultView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    
    // result가 전달한 ID와 같은 BucketListItem 하나만 관리한다
    // SwiftData의 값이 변경되면 화면도 자동으로 다시 그려진다
    @Query private var bucketListItems: [BucketListItem]
    
    @State private var isSnackbarPresented = false
    
    let headerContent: ResultHeaderContent
    let onComplete: () -> Void
    
    init(
        result: SavedBucketListDTO,
        headerContent: ResultHeaderContent,
        onComplete: @escaping () -> Void
    ) {
        let savedItemID = result.bucketListItemID
        
        // Repository가 반환한 ID와 같은 약속 하나만 조회합니다.
        _bucketListItems = Query(
            filter: #Predicate<BucketListItem> { item in
                item.id == savedItemID
            }
        )
        self.headerContent = headerContent
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            resultBackground
            
            if let savedItem {
                loadedContent(item: savedItem)
            } else {
                notFoundContent
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
                SavedBucketListSnackbar(
                    message: "약속 탭에 저장되었어요"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 92)
                .transition(snackbarTransition)
            }
        }
        .task(id: savedItem?.id) {
            // 저장된 모델을 실제로 찾은 경우에만
            // 저장 성공 메시지를 표시합니다.
            guard savedItem != nil else {
                return
            }
            
            await presentSnackbar()
        }
    }
    
    // ID는 unique이므로 조회 결과는 최대 하나여야 합니다.
    private var savedItem: BucketListItem? {
        bucketListItems.first
    }
    
    private var resultBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("Taedam-BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.38)
        }
    }
    
    private func loadedContent(
        item: BucketListItem
    ) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ResultHeaderView(
                    content: headerContent
                )
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 36)
                
                SavedBucketListCard(
                    item: item
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 24)
        }
    }
    
    private var notFoundContent: some View {
        ContentUnavailableView(
            "저장된 약속을 찾을 수 없어요",
            systemImage: "exclamationmark.triangle",
            description: Text(
                "저장된 약속이 삭제되었거나 불러오지 못했어요."
            )
        )
    }
    
    private var snackbarTransition: AnyTransition {
        if reduceMotion {
                return .opacity
            }

            return .asymmetric(
                insertion: .opacity
                    .combined(
                        with: .offset(y: 8)
                    ),
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
        
        // VoiceOver 사용자에게도 저장 완료 사실을 알립니다.
        AccessibilityNotification
            .Announcement("약속 탭에 저장되었어요")
            .post()
        
        do {
            try await Task.sleep(
                for: .seconds(2)
            )
        } catch {
            // 화면이 닫혀 Task가 취소되면
            // 이후 상태 변경을 실행하지 않습니다.
            return
        }
        
        guard !Task.isCancelled else {
            return
        }
        
        withAnimation(
            .easeIn(duration: 0.2)
        ) {
            isSnackbarPresented = false
        }
    }
}

#Preview {
    let container = PersistenceContainer.makeContainer(
        inMemory: true
    )

    let savedItem = BucketListItem(
        category: "멀리멀리 대모험",
        content: "메론빵 만들어주기"
    )

    container.mainContext.insert(savedItem)

    return TaedamResultView(
        result: SavedBucketListDTO(
            bucketListItemID: savedItem.id
        ),
        headerContent: ResultHeaderContent(
            targetGestationalWeek: 22,
            title: "일요일 아침 냄새",
            artworkAssetName: "TitleImage"
        ),
        onComplete: {}
    )
    .modelContainer(container)
}
