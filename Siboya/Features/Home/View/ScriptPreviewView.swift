//
//  ScriptPreviewView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import UIKit

/// 태담에서 확정한 소원을 저장하는 앱 조립 계층의 비동기 동작입니다.
typealias SaveBucketListAction =
    @MainActor (SaveBucketListCommandDTO) async throws -> SavedBucketListDTO

/// 준비자세 화면에서 마이크와 Speech 권한을 확인·요청하는 비동기 동작입니다.
typealias RequestTaedamAuthorizationAction =
    @MainActor () async -> TaedamSpeechAuthorization

/// 선택한 대본을 미리 보여주고 준비자세 안내를 거쳐 기존 태담 화면으로 연결하는 화면입니다.
struct ScriptPreviewView: View {
    /// ScrollView가 Hero의 full-bleed 배치를 보존하도록 무시할 안전 영역 방향입니다.
    static let ignoredSafeAreaEdges: Edge.Set = .top

    /// 상위 화면 설정과 무관하게 시스템 뒤로가기 버튼을 제공하도록 요청할 navigation bar 상태입니다.
    static let navigationBarVisibility: Visibility = .visible

    /// Hero 제목과 소요시간 정보 사이에 유지할 Figma 기준 간격입니다.
    static let heroToDurationSpacing: CGFloat = 8

    /// 미리보기와 태담 실행이 같은 대본 입력을 유지하도록 보관하는 이동 데이터입니다.
    let route: ScriptPreviewRoute

    /// 준비자세 시트와 전체 화면 전환 순서를 관찰하는 화면 전용 상태 모델입니다.
    @State private var flowModel: ScriptPreviewFlowModel

    /// Report 닫힘 애니메이션이 끝난 뒤에만 NavigationStack을 Home으로 초기화합니다.
    @State private var shouldCompleteAfterSessionDismissal = false

    /// 최종 수정 문장을 저장한 뒤에만 Report 화면으로 전환하기 위한 동작입니다.
    private let saveBucketList: SaveBucketListAction

    /// 실제 세션 진입 직전에 시스템 음성 권한을 확인하는 동작입니다.
    private let requestAuthorization: RequestTaedamAuthorizationAction

    /// Report 완료 후 앱 루트가 Home으로 복귀하도록 알리는 동작입니다.
    private let onFlowComplete: () -> Void

    /// 제목·본문·태명·대표 이미지 시리즈를 포함한 이동 데이터로 화면을 초기화합니다.
    /// - Parameters:
    ///   - route: 미리보기와 태담 실행에 함께 사용할 데이터입니다.
    ///   - saveBucketList: 최종 수정 문장을 영구 저장하는 동작입니다.
    ///   - requestAuthorization: 마이크와 Speech 권한을 확인·요청하는 동작입니다.
    ///   - onFlowComplete: 결과 화면 완료 후 앱 루트에 알릴 동작입니다.
    init(
        route: ScriptPreviewRoute,
        saveBucketList: @escaping SaveBucketListAction,
        requestAuthorization: @escaping RequestTaedamAuthorizationAction = {
            await TaedamSpeechAuthorizationService().requestAuthorization()
        },
        onFlowComplete: @escaping () -> Void = {}
    ) {
        self.route = route
        self.saveBucketList = saveBucketList
        self.requestAuthorization = requestAuthorization
        self.onFlowComplete = onFlowComplete
        // View가 다시 계산돼도 동일한 흐름 모델을 관찰하도록 State의 초기값으로 한 번만 만듭니다.
        _flowModel = State(initialValue: ScriptPreviewFlowModel())
    }

    /// Hero·시간·본문을 스크롤하고 하단 준비 버튼은 안전 영역에 고정해 언제나 시작 흐름을 찾을 수 있게 합니다.
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단 배경과 132pt Thumbnail은 route에서 선택된 같은 이미지 시리즈를 사용합니다.
                ScriptPreviewHero(
                    artworkSeries: route.artworkSeries,
                    targetGestationalWeek: route.sessionInput.script.targetGestationalWeek,
                    title: route.sessionInput.script.title
                )

                // 선택적으로 제공되는 소요 시간은 Hero 아래에 독립된 정보 묶음으로 배치합니다.
                ScriptPreviewDuration(
                    estimatedDurationSeconds: route.sessionInput.script.estimatedDurationSeconds
                )
                .padding(.top, Self.heroToDurationSpacing)

                // 번들 데이터 순서를 유지한 대본과 빈칸·생각힌트를 읽기 영역에 표시합니다.
                ScriptPreviewBody(
                    sentences: route.sessionInput.script.sentences,
                    bucketListPrompt: route.sessionInput.script.bucketListPrompt.previewText,
                    bucketListGuide: route.sessionInput.script.bucketListGuide
                )
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 28)
            }
        }
        // 상위 스크롤 컨테이너도 상단까지 확장해 Hero의 ignoresSafeArea가 NavigationStack에서 잘리지 않게 합니다.
        .ignoresSafeArea(edges: Self.ignoredSafeAreaEdges)
        .background(Color.background)
        // 스크롤과 겹치지 않으며 접근성 안전 영역에도 맞추기 위해 공통 하단 바를 safe area inset으로 고정합니다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ScriptPreviewBottomBar {
                flowModel.presentPreparation()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Home에서 push된 화면의 시스템 뒤로가기 버튼과 interactive pop을 명시적으로 유지합니다.
        .toolbar(Self.navigationBarVisibility, for: .navigationBar)
        // 시스템 뒤로가기 버튼은 유지하면서 Hero 배경이 navigation bar 뒤에서도 보이게 합니다.
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(
            isPresented: preparationBinding,
            onDismiss: flowModel.handlePreparationDismissed
        ) {
            TaedamPreparationView(
                babyNickname: route.sessionInput.babyNickname,
                isStarting: flowModel.isRequestingAuthorization,
                onClose: flowModel.dismissPreparation,
                onStart: requestSessionStart
            )
            // Figma와 같이 상단 일부가 보이는 준비자세 sheet 높이를 View의 단일 계약으로 유지합니다.
            .presentationDetents([
                .fraction(TaedamPreparationView.sheetDetentFraction)
            ])
            .presentationDragIndicator(.visible)
            .alert(
                authorizationAlertTitle,
                isPresented: authorizationIssueBinding
            ) {
                Button("닫기", role: .cancel) {
                    flowModel.dismissAuthorizationIssue()
                }
                Button("설정") {
                    openAppSettings()
                }
            } message: {
                Text(authorizationAlertMessage)
            }
        }
        .fullScreenCover(
            isPresented: sessionBinding,
            onDismiss: handleSessionDismissed
        ) {
            if let bucketListContent = flowModel.resultBucketListContent {
                // 저장에 성공한 한 문장과 선택 route의 표시 정보를 SwiftData 재조회 없이 Report에 전달합니다.
                TaedamResultView(
                    targetGestationalWeek: route.sessionInput.script.targetGestationalWeek,
                    title: route.sessionInput.script.title,
                    artworkAssetName: route.artworkSeries.thumbnailAssetName,
                    bucketListContent: bucketListContent,
                    onComplete: completeFlow
                )
            } else {
                // 준비자세 sheet 닫힘이 끝난 뒤 같은 실행 입력으로 태담 화면을 표시합니다.
                TaedamScreen(
                    input: route.sessionInput,
                    onBack: flowModel.dismissSession,
                    onFinish: saveAndPresentResult
                )
            }
        }
    }

    /// 준비자세 상태 모델을 sheet의 양방향 Binding으로 연결해 drag dismiss도 같은 닫기 동작을 사용하게 합니다.
    private var preparationBinding: Binding<Bool> {
        Binding(
            get: { flowModel.isPreparationPresented },
            set: { isPresented in
                // SwiftUI가 drag dismiss로 false를 전달했을 때만 모델에 닫힘을 반영합니다.
                if !isPresented {
                    flowModel.dismissPreparation()
                }
            }
        )
    }

    /// 태담 전체 화면이 스와이프로 닫혀도 모델의 표시 상태가 실제 화면과 일치하도록 연결합니다.
    private var sessionBinding: Binding<Bool> {
        Binding(
            get: { flowModel.isSessionPresented },
            set: { isPresented in
                // 사용자가 full screen cover를 닫았을 때만 세션 상태를 해제합니다.
                if !isPresented {
                    flowModel.dismissSession()
                }
            }
        )
    }

    /// 권한 문제 상태를 SwiftUI Alert 표시 여부와 연결합니다.
    private var authorizationIssueBinding: Binding<Bool> {
        Binding(
            get: { flowModel.authorizationIssue != nil },
            set: { isPresented in
                if !isPresented {
                    flowModel.dismissAuthorizationIssue()
                }
            }
        )
    }

    /// 현재 거부된 권한에 맞는 Alert 제목입니다.
    private var authorizationAlertTitle: String {
        switch flowModel.authorizationIssue {
        case .microphone:
            "마이크 권한이 필요해요"
        case .speechRecognition:
            "음성 인식 권한이 필요해요"
        case nil:
            "음성 권한이 필요해요"
        }
    }

    /// 현재 거부된 권한에 맞는 설정 안내 문구입니다.
    private var authorizationAlertMessage: String {
        switch flowModel.authorizationIssue {
        case .microphone:
            "설정에서 Siboya의 마이크 접근을 허용해 주세요."
        case .speechRecognition:
            "설정에서 Siboya의 음성 인식 접근을 허용해 주세요."
        case nil:
            ""
        }
    }

    /// 준비자세 시작 요청을 권한 확인과 세션 예약 순서로 실행합니다.
    private func requestSessionStart() {
        Task {
            await flowModel.requestSessionStart(using: requestAuthorization)
        }
    }

    /// 사용자가 최종 수정한 문장을 저장한 뒤 같은 전체 화면을 Report로 전환합니다.
    /// - Parameter bucketListContent: 공백을 정리한 최종 소원 문장입니다.
    @MainActor
    private func saveAndPresentResult(
        bucketListContent: String
    ) async throws {
        let command = SaveBucketListCommandDTO(
            category: route.sessionInput.script.category,
            content: bucketListContent
        )
        _ = try await saveBucketList(command)
        flowModel.presentResult(bucketListContent: bucketListContent)
    }

    /// 결과 화면 완료 시 전체 화면을 닫고 앱 루트의 태담 Home 복귀를 요청합니다.
    private func completeFlow() {
        shouldCompleteAfterSessionDismissal = true
        flowModel.dismissResult()
    }

    /// 전체 화면 닫힘 완료 후에만 미리보기 push를 제거해 화면 전환 충돌과 순간적인 화면 교체를 막습니다.
    private func handleSessionDismissed() {
        guard shouldCompleteAfterSessionDismissal else { return }

        shouldCompleteAfterSessionDismissal = false
        flowModel.clearResult()
        onFlowComplete()
    }

    /// 사용자가 직접 권한을 바꿀 수 있도록 앱별 설정 화면을 엽니다.
    private func openAppSettings() {
        guard let settingsURL = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}

// 실제 route 데이터로 Hero·본문·고정 하단 바의 세로 흐름을 확인합니다.
#Preview("대본 미리보기") {
    NavigationStack {
        ScriptPreviewView(
            route: ScriptPreviewRoute(
                sessionInput: .mock,
                artworkSeries: .one
            ),
            saveBucketList: { _ in
                SavedBucketListDTO(bucketListItemID: UUID())
            }
        )
    }
}

#Preview("대본 미리보기 - Dark") {
    NavigationStack {
        ScriptPreviewView(
            route: ScriptPreviewRoute(
                sessionInput: .mock,
                artworkSeries: .one
            ),
            saveBucketList: { _ in
                SavedBucketListDTO(bucketListItemID: UUID())
            }
        )
    }
    .preferredColorScheme(.dark)
}
