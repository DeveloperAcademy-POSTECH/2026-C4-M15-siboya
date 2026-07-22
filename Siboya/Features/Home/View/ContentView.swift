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

    /// 화면 상태와 선택 동작을 `HomeView`에 전달하고 최초 표시 시 SwiftData 데이터를 준비합니다.
    var body: some View {
        HomeView(
            state: model.state,
            onSelectScript: onSelectScript,
            onSelectPromiseTab: onSelectPromiseTab
        )
        .task {
            await prepareAndLoadHome()
        }
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
