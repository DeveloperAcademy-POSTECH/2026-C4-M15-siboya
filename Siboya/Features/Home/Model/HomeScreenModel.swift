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

    /// 공백을 제거한 뒤 미리보기 대본의 태명 치환에 사용할 현재 아기 태명입니다.
    private var loadedNickname: String?

    /// 현재 프로필에서 읽은 임신 주차로, 이후 화면 이동에서도 같은 프로필 스냅샷을 유지합니다.
    private var loadedGestationalWeek: Int?

    /// Home 목록과 사용자의 선택을 정확한 대본으로 다시 해석할 때 사용할 로드 완료 문서입니다.
    private var loadedScriptDocument: TaedamScriptDocument?

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

        // 미리보기 이동은 현재 화면과 같은 프로필·대본 기준을 사용해야 하므로 로드 결과를 함께 보관합니다.
        loadedNickname = profile?.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        loadedGestationalWeek = profile?.gestationalWeek
        loadedScriptDocument = scriptDocument

        state = HomeViewStateBuilder.make(
            babyNickname: profile?.nickname,
            gestationalWeek: profile?.gestationalWeek,
            weeklyDocument: weeklyDocument,
            scriptDocument: scriptDocument
        )
    }

    /// 선택 UUID·버전에 정확히 일치하는 대본을 찾아 미리보기 화면이 사용할 이동 데이터를 만듭니다.
    /// - Parameter selection: Home 카드나 목록 행에서 전달받은 대본 식별자와 수정 버전입니다.
    /// - Returns: 태명·대본·이미지 시리즈가 모두 준비된 경우의 route, 하나라도 없거나 일치하지 않으면 `nil`입니다.
    func makePreviewRoute(for selection: ScriptSelectionDTO) -> ScriptPreviewRoute? {
        // 공백뿐인 태명으로 대본 문구를 치환하지 않도록 이동 전에 유효한 프로필을 확인합니다.
        guard let nickname = loadedNickname, !nickname.isEmpty,
              let scriptDocument = loadedScriptDocument,
              let scriptIndex = scriptDocument.scripts.firstIndex(where: {
                  $0.id == selection.scriptID && $0.version == selection.scriptVersion
              }) else {
            return nil
        }

        let script = scriptDocument.scripts[scriptIndex]
        let artworkSeries = ScriptArtworkSeries.cycling(forZeroBasedIndex: scriptIndex)

        return ScriptPreviewRoute(
            sessionInput: script.makeSessionInput(babyNickname: nickname),
            artworkSeries: artworkSeries
        )
    }
}
