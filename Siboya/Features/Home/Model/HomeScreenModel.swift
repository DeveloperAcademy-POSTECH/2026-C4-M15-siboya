//
//  HomeScreenModel.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Observation

/// SwiftData 프로필과 두 번들 문서를 읽어 `HomeView`가 소비할 표시 상태를 관리합니다.
@MainActor
@Observable
final class HomeScreenModel {
    /// 로딩 전에는 빈 구조를, 로딩 후에는 사용 가능한 데이터로 만든 Home 상태를 보관합니다.
    private(set) var state: HomeViewState = .empty

    /// 현재 주차의 headline과 추천 UUID를 읽는 주차 콘텐츠 로더입니다.
    private let weeklyContentLoader: () throws -> HomeWeeklyContentDocument

    /// Home 목록과 추천 카드에 사용할 여섯 대본을 읽는 번들 로더입니다.
    private let scriptDocumentLoader: () throws -> TaedamScriptDocument

    /// 실제 번들 로더를 기본으로 사용하되 테스트에서는 각 데이터 소스의 성공·실패를 주입할 수 있게 합니다.
    /// - Parameters:
    ///   - weeklyContentLoader: 호출 시 주차별 Home 문서를 반환하는 동작입니다.
    ///   - scriptDocumentLoader: 호출 시 태담 대본 문서를 반환하는 동작입니다.
    init(
        weeklyContentLoader: @escaping () throws -> HomeWeeklyContentDocument = {
            try BundledHomeWeeklyContentLoader.load()
        },
        scriptDocumentLoader: @escaping () throws -> TaedamScriptDocument = {
            try BundledTaedamScriptLoader.load()
        }
    ) {
        self.weeklyContentLoader = weeklyContentLoader
        self.scriptDocumentLoader = scriptDocumentLoader
    }

    /// 저장된 아기 프로필과 정적 문서를 각각 읽고, 실패한 소스에 의존하는 영역만 비운 상태로 갱신합니다.
    /// - Parameter repository: SwiftData의 `BabyProfile`을 조회할 저장소 구현입니다.
    /// - Result: 공개된 `state`가 최신 프로필 주차와 번들 콘텐츠를 반영합니다.
    func load(repository: any TaedamRepository) {
        // 세 소스를 독립적으로 읽어 한 파일의 문제가 정상적인 다른 화면 영역까지 숨기지 않게 합니다.
        let profile = try? repository.fetchBabyProfile()
        let weeklyDocument = try? weeklyContentLoader()
        let scriptDocument = try? scriptDocumentLoader()

        state = HomeViewStateBuilder.make(
            babyNickname: profile?.nickname,
            gestationalWeek: profile?.gestationalWeek,
            weeklyDocument: weeklyDocument,
            scriptDocument: scriptDocument
        )
    }
}
