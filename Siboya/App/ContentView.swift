//
//  ContentView.swift
//  Siboya
//
//  Created by Gosan on 7/13/26.
//

import SwiftData
import SwiftUI

/// 앱 환경의 SwiftData 저장소를 Home 화면 모델과 연결하는 최상위 조립 View입니다.
struct ContentView: View {
    /// 앱의 공용 `ModelContext`로 최신 SCRUM-28 저장소 구현을 생성합니다.
    @Environment(\.modelContext) private var modelContext

    /// 프로필과 번들 문서를 읽은 결과를 관찰해 순수 `HomeView`에 전달합니다.
    @State private var model = HomeScreenModel()

    /// Home에서 선택한 대본 route를 차례로 보관해 뒤로 가기 후에도 동일한 Home 상태를 유지합니다.
    @State private var navigationPath = NavigationPath()

    /// 태담 Home과 저장된 소원 목록 사이의 앱 루트 탭 선택 상태입니다.
    @State private var selectedTab: SiboyaTab = .taedam

    /// 대본 선택을 이후 미리보기 화면 조정자에게 전달할 동작입니다.
    private let onSelectScript: (UUID, Int) -> Void

    /// 약속 탭 선택을 이후 앱 탭 조정자에게 전달할 동작입니다.
    private let onSelectPromiseTab: () -> Void

    /// 아직 미리보기·약속 화면이 연결되지 않은 앱 진입점에서도 Home을 독립 실행할 수 있게 합니다.
    /// - Parameters:
    ///   - onSelectScript: 대본 UUID와 버전을 받을 상위 선택 콜백입니다.
    ///   - onSelectPromiseTab: 약속 탭으로 전환할 상위 콜백입니다.
    init(
        onSelectScript: @escaping (UUID, Int) -> Void = { _, _ in },
        onSelectPromiseTab: @escaping () -> Void = {}
    ) {
        self.onSelectScript = onSelectScript
        self.onSelectPromiseTab = onSelectPromiseTab
    }

    /// 태담 Home과 소원 목록을 공통 탭 바로 전환하고 태담 상세 흐름에서는 탭 바를 숨깁니다.
    var body: some View {
        Group {
            switch selectedTab {
            case .taedam:
                NavigationStack(path: $navigationPath) {
                    HomeView(
                        state: model.state,
                        onSelectScript: handleScriptSelection
                    )
                    .navigationDestination(for: ScriptPreviewRoute.self) { route in
                        ScriptPreviewView(
                            route: route,
                            saveBucketList: saveBucketList,
                            onFlowComplete: completeTaedamFlow
                        )
                    }
                }

            case .wish:
                // Summary의 @Query가 공용 ModelContainer를 관찰해 저장 직후 목록을 자동 갱신합니다.
                TaedamChecklistView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if shouldShowRootTabBar {
                HomeBottomTabBar(
                    selectedTab: selectedTab,
                    onSelectTaedam: selectTaedamTab,
                    onSelectPromise: selectWishTab
                )
            }
        }
        .task {
            await prepareAndLoadHome()
        }
    }

    /// Home 컴포넌트의 분리된 UUID·버전 인자를 route 해석에 필요한 선택 DTO로 묶습니다.
    /// - Parameters:
    ///   - scriptID: 사용자가 누른 대본의 고유 식별자입니다.
    ///   - scriptVersion: 사용자가 누른 대본 수정본 번호입니다.
    /// - Returns: 대본·수정본 조합을 잃지 않고 보관한 선택 DTO입니다.
    static func makeScriptSelection(
        scriptID: UUID,
        scriptVersion: Int
    ) -> ScriptSelectionDTO {
        ScriptSelectionDTO(scriptID: scriptID, scriptVersion: scriptVersion)
    }

    /// Home 선택을 외부 알림과 미리보기 route 생성으로 연결하고, 해석 성공 시에만 화면 전환을 추가합니다.
    /// - Parameters:
    ///   - scriptID: Home 카드 또는 행이 전달한 대본 UUID입니다.
    ///   - scriptVersion: Home 카드 또는 행이 전달한 대본 수정 버전입니다.
    private func handleScriptSelection(scriptID: UUID, scriptVersion: Int) {
        let selection = Self.makeScriptSelection(
            scriptID: scriptID,
            scriptVersion: scriptVersion
        )

        // 기존 상위 선택 알림 계약을 보존해 ContentView를 외부 조정자와 함께 사용해도 이벤트가 사라지지 않게 합니다.
        onSelectScript(scriptID, scriptVersion)

        // 프로필·대본 누락 또는 버전 불일치 시 잘못된 태담 실행을 막기 위해 미리보기를 열지 않습니다.
        guard let route = model.makePreviewRoute(for: selection) else { return }

        navigationPath.append(route)
    }

    /// 최종 수정 문장을 현재 태담 카테고리와 함께 SwiftData에 한 번 저장합니다.
    @MainActor
    private func saveBucketList(
        command: SaveBucketListCommandDTO
    ) async throws -> SavedBucketListDTO {
        let repository = SwiftDataTaedamRepository(modelContext: modelContext)
        return try await repository.save(command: command)
    }

    /// 결과 화면 완료 시 전체 화면 흐름과 미리보기 push를 닫고 태담 Home으로 돌아갑니다.
    private func completeTaedamFlow() {
        navigationPath = NavigationPath()
        selectedTab = .taedam
    }

    /// Home 루트와 소원 탭에서만 공통 탭 바를 표시합니다.
    private var shouldShowRootTabBar: Bool {
        selectedTab == .wish || navigationPath.isEmpty
    }

    /// 태담 탭 선택을 앱 루트 상태에 반영합니다.
    private func selectTaedamTab() {
        selectedTab = .taedam
    }

    /// 소원 탭 선택을 외부 알림 계약과 앱 루트 상태에 함께 반영합니다.
    private func selectWishTab() {
        onSelectPromiseTab()
        selectedTab = .wish
    }

    /// 온보딩 전 MVP 기본 프로필을 멱등적으로 보장한 뒤 저장된 실제 값으로 Home 상태를 갱신합니다.
    /// - Result: 기존 프로필은 보존하고, 프로필이 없을 때만 `꾹꾹이` 22주 값을 한 번 생성합니다.
    @MainActor
    private func prepareAndLoadHome() async {
        let repository = SwiftDataTaedamRepository(modelContext: modelContext)

        // SCRUM-28의 멱등 계약을 사용하므로 앱 재진입 시 사용자의 기존 태명과 주차를 덮어쓰지 않습니다.
        try? await repository.ensureBabyProfile(
            nickname: "꾹꾹이",
            gestationalWeek: 22
        )
        model.load(repository: repository)
    }
}

// 메모리에만 프로필을 생성해 실제 앱과 같은 SwiftData 연결 흐름을 확인합니다.
#Preview {
    ContentView()
        .modelContainer(PersistenceContainer.makeContainer(inMemory: true))
}
