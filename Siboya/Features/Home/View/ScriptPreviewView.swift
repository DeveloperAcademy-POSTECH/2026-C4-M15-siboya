//
//  ScriptPreviewView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import UIKit

/// 선택한 대본을 미리 보여주고 준비자세·권한 확인을 거쳐 기존 태담 화면으로 연결하는 화면입니다.
struct ScriptPreviewView: View {
    /// 미리보기와 태담 실행이 같은 대본 입력을 유지하도록 보관하는 이동 데이터입니다.
    let route: ScriptPreviewRoute

    /// 준비자세 시트와 권한·전체 화면 전환 순서를 관찰하는 화면 전용 상태 모델입니다.
    @State private var flowModel: ScriptPreviewFlowModel

    /// route와 권한 서비스를 주입해 실제 앱과 테스트 모두에서 같은 화면 조립 경로를 사용합니다.
    /// - Parameters:
    ///   - route: 제목·본문·태명·대표 이미지 시리즈를 포함한 미리보기 입력입니다.
    ///   - authorizer: 마이크와 음성 인식 권한을 확인할 서비스입니다.
    init(
        route: ScriptPreviewRoute,
        authorizer: any TaedamPermissionAuthorizing = TaedamPermissionAuthorizer()
    ) {
        self.route = route
        // View가 다시 계산돼도 동일한 흐름 모델을 관찰하도록 State의 초기값으로 한 번만 만듭니다.
        _flowModel = State(initialValue: ScriptPreviewFlowModel(authorizer: authorizer))
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
                .padding(.top, 8)

                // 번들 데이터 순서를 유지한 대본과 빈칸·생각힌트를 읽기 영역에 표시합니다.
                ScriptPreviewBody(
                    sentences: route.sessionInput.script.sentences,
                    bucketListPrompt: route.sessionInput.script.bucketListPrompt,
                    bucketListGuide: route.sessionInput.script.bucketListGuide
                )
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 28)
            }
        }
        .background(Color(.systemBackground))
        // 스크롤과 겹치지 않으며 접근성 안전 영역에도 맞추기 위해 공통 하단 바를 safe area inset으로 고정합니다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ScriptPreviewBottomBar {
                flowModel.presentPreparation()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: preparationBinding,
            onDismiss: flowModel.handlePreparationDismissed
        ) {
            TaedamPreparationView(
                babyNickname: route.sessionInput.babyNickname,
                isRequestingPermission: flowModel.isRequestingPermission,
                onClose: flowModel.dismissPreparation,
                onStart: requestPermissions
            )
            // Figma와 같이 상단 일부가 보이는 준비자세 sheet 높이를 시스템 detent로 유지합니다.
            .presentationDetents([.fraction(0.87)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "권한이 필요해요",
            isPresented: permissionAlertBinding
        ) {
            // 닫기는 안내만 해제하고 현재 준비자세 시트를 유지해 사용자의 재시도를 돕습니다.
            Button("닫기", role: .cancel) {
                flowModel.dismissPermissionAlert()
            }

            // 설정 이동 후에도 자동 시작하지 않고 사용자가 다시 시작하기를 선택하도록 흐름 상태를 그대로 둡니다.
            Button("설정") {
                openApplicationSettings()
                flowModel.dismissPermissionAlert()
            }
        } message: {
            Text(permissionAlertMessage)
        }
        .fullScreenCover(isPresented: sessionBinding) {
            // 권한 승인과 sheet 닫힘이 모두 끝난 뒤에만 기존 태담 화면을 같은 실행 입력으로 표시합니다.
            TaedamScreen(
                input: route.sessionInput,
                onBack: flowModel.dismissSession,
                onFinish: flowModel.dismissSession
            )
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

    /// 거부 권한의 유무를 Alert 표시로 바꾸고 사용자가 시스템 Alert를 닫아도 원인을 비우게 합니다.
    private var permissionAlertBinding: Binding<Bool> {
        Binding(
            get: { flowModel.permissionAlertIssue != nil },
            set: { isPresented in
                // Alert의 외부 dismiss 경로도 닫기 버튼과 동일하게 원인을 초기화합니다.
                if !isPresented {
                    flowModel.dismissPermissionAlert()
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

    /// 준비자세 시작 버튼 동작을 비동기 권한 흐름에 연결합니다.
    private func requestPermissions() {
        Task {
            // 권한 서비스는 모델이 중복 요청을 막으므로 View는 사용자 동작을 한 번만 전달합니다.
            await flowModel.requestPermissions()
        }
    }

    /// 거부된 권한 종류에 맞는 설정 안내 문구를 제공합니다.
    private var permissionAlertMessage: String {
        switch flowModel.permissionAlertIssue {
        case .microphone:
            return "음성기능을 사용하시려면 [설정 > 개인정보보호 > 마이크]에서 태담앱의 접근을 허용해 주세요."
        case .speechRecognition:
            return "음성 인식 기능을 사용하시려면 설정에서 태담앱의 음성 인식 접근을 허용해 주세요."
        case nil:
            // Alert가 사라지는 갱신 순간에도 안전한 기본 문자열을 제공해 불필요한 상태 변경을 피합니다.
            return ""
        }
    }

    /// 앱 전용 설정 화면을 열고 실패하더라도 준비자세·세션 상태를 변경하지 않습니다.
    private func openApplicationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }

        // 설정 앱을 열 수 없는 환경에서도 사용자가 다시 시도할 수 있도록 현재 sheet를 유지합니다.
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
            )
        )
    }
}
