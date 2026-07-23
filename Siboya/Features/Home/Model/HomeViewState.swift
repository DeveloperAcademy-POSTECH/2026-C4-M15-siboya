//
//  HomeViewState.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// 이번 주 추천 headline과 추천 카드가 항상 함께 존재하도록 묶은 표시 상태입니다.
struct HomeRecommendationState: Equatable, Sendable {
    /// 현재 임신 주차에 맞춰 Home JSON에서 가져온 추천 설명입니다.
    let headline: String

    /// 추천 카드가 표시하고 선택 결과로 전달할 대본 정보입니다.
    let item: HomeScriptItem
}

/// 같은 카테고리에 속한 Home 대본 행들을 최초 등장 순서대로 묶은 표시 상태입니다.
struct HomeScriptCategory: Identifiable, Equatable, Sendable {
    /// 카테고리 섹션 상단에 표시할 정리된 이름입니다.
    let title: String

    /// 번들 JSON의 순서를 유지해 표시할 대본 행 목록입니다.
    let items: [HomeScriptItem]

    /// 같은 카테고리 이름을 하나의 SwiftUI 섹션으로 식별합니다.
    var id: String {
        title
    }
}

/// Home View가 저장소나 JSON 모델을 알지 않고 화면만 그릴 수 있도록 만든 전체 표시 상태입니다.
struct HomeViewState: Equatable, Sendable {
    /// SwiftData 프로필에서 읽어 상단 Large Title에 표시할 태명입니다.
    let babyNickname: String?

    /// 주차 콘텐츠와 추천 대본 연결이 모두 유효할 때만 존재하는 추천 영역입니다.
    let recommendation: HomeRecommendationState?

    /// 번들 대본을 최초 등장 순서대로 묶은 카테고리 목록입니다.
    let categories: [HomeScriptCategory]

    /// 데이터 로딩 전에도 Home 기본 구조를 안전하게 표시하는 빈 상태입니다.
    static let empty = HomeViewState(
        babyNickname: nil,
        recommendation: nil,
        categories: []
    )
}

/// SwiftData 프로필 값과 두 번들 문서를 화면 전용 `HomeViewState`로 변환합니다.
enum HomeViewStateBuilder {
    /// 사용 가능한 데이터만 조합해 태명, 추천과 카테고리 목록을 독립적으로 만듭니다.
    /// - Parameters:
    ///   - babyNickname: SwiftData의 `BabyProfile.nickname` 값이며 공백을 정리해 사용합니다.
    ///   - gestationalWeek: SwiftData의 현재 임신 주차이며 Home 주차 항목을 찾는 키입니다.
    ///   - weeklyDocument: 주차별 headline과 추천 대본 ID를 담은 번들 문서입니다.
    ///   - scriptDocument: 카테고리·대본과 대상 주차를 담은 번들 문서입니다.
    /// - Returns: 누락된 데이터에 의존하는 영역만 제외한 Home 표시 상태입니다.
    static func make(
        babyNickname: String?,
        gestationalWeek: Int?,
        weeklyDocument: HomeWeeklyContentDocument?,
        scriptDocument: TaedamScriptDocument?
    ) -> HomeViewState {
        let resolvedNickname = nonemptyTrimmed(babyNickname)
        let categories = makeCategories(from: scriptDocument)
        let recommendation = makeRecommendation(
            hasValidProfile: resolvedNickname != nil,
            gestationalWeek: gestationalWeek,
            weeklyDocument: weeklyDocument,
            scriptDocument: scriptDocument
        )

        return HomeViewState(
            babyNickname: resolvedNickname,
            recommendation: recommendation,
            categories: categories
        )
    }

    /// 대본 배열을 한 번 순회해 최초 카테고리 순서와 각 대본의 원래 이미지 순서를 함께 보존합니다.
    /// - Parameter scriptDocument: 카테고리로 묶을 번들 대본 문서입니다.
    /// - Returns: 빈 이름의 대본을 제외하고 최초 등장 순서대로 만든 카테고리 상태입니다.
    private static func makeCategories(
        from scriptDocument: TaedamScriptDocument?
    ) -> [HomeScriptCategory] {
        guard let scripts = scriptDocument?.scripts else { return [] }

        var categoryOrder: [String] = []
        var itemsByCategory: [String: [HomeScriptItem]] = [:]

        for (scriptIndex, script) in scripts.enumerated() {
            guard let category = nonemptyTrimmed(script.category),
                  let item = makeItem(
                      from: script,
                      artworkSeries: .cycling(forZeroBasedIndex: scriptIndex)
                  ) else {
                // 잘못된 한 대본이 나머지 정상 목록을 가리지 않도록 해당 항목만 건너뜁니다.
                continue
            }

            if itemsByCategory[category] == nil {
                // Dictionary 순서에 기대지 않고 별도 배열에 최초 등장 순서를 기록합니다.
                categoryOrder.append(category)
                itemsByCategory[category] = []
            }

            itemsByCategory[category, default: []].append(item)
        }

        return categoryOrder.compactMap { category in
            guard let items = itemsByCategory[category], !items.isEmpty else {
                return nil
            }

            return HomeScriptCategory(title: category, items: items)
        }
    }

    /// 현재 주차 항목과 추천 UUID가 모두 연결될 때만 완전한 추천 상태를 만듭니다.
    /// - Parameters:
    ///   - hasValidProfile: 태명까지 유효한 SwiftData 프로필이 존재하는지 나타냅니다.
    ///   - gestationalWeek: 정확히 같은 주차 항목을 찾을 현재 임신 주차입니다.
    ///   - weeklyDocument: 주차별 추천 내용을 제공하는 번들 문서입니다.
    ///   - scriptDocument: 추천 UUID에 대응하는 대본을 제공하는 번들 문서입니다.
    /// - Returns: 모든 연결이 성공하면 추천 상태를, 하나라도 없으면 `nil`을 반환합니다.
    private static func makeRecommendation(
        hasValidProfile: Bool,
        gestationalWeek: Int?,
        weeklyDocument: HomeWeeklyContentDocument?,
        scriptDocument: TaedamScriptDocument?
    ) -> HomeRecommendationState? {
        guard hasValidProfile,
              let gestationalWeek,
              let weeklyDocument,
              let weeklyIndex = weeklyDocument.weeks.firstIndex(where: {
                  $0.gestationalWeek == gestationalWeek
              }),
              let headline = nonemptyTrimmed(
                  weeklyDocument.weeks[weeklyIndex].headline
              ),
              let scriptDocument else {
            return nil
        }

        let weeklyContent = weeklyDocument.weeks[weeklyIndex]
        guard let script = scriptDocument.scripts.first(where: {
            $0.id == weeklyContent.recommendedScriptID
        }),
        let item = makeItem(
            from: script,
            artworkSeries: .cycling(forZeroBasedIndex: weeklyIndex)
        ) else {
            // 추천 연결만 실패했으므로 호출자가 이미 만든 카테고리 목록은 그대로 유지합니다.
            return nil
        }

        return HomeRecommendationState(headline: headline, item: item)
    }

    /// 번들 대본의 표시 필드만 골라 Home 컴포넌트용 경량 모델로 변환합니다.
    /// - Parameters:
    ///   - script: UUID, 버전, 제목과 대상 주차를 제공하는 번들 대본입니다.
    ///   - artworkSeries: 카드 또는 행이 역할별 에셋 이름을 계산할 이미지 묶음입니다.
    /// - Returns: 제목과 카테고리가 유효하면 Home 대본 항목을, 아니면 `nil`을 반환합니다.
    private static func makeItem(
        from script: TaedamScriptContent,
        artworkSeries: ScriptArtworkSeries
    ) -> HomeScriptItem? {
        guard nonemptyTrimmed(script.category) != nil,
              let title = nonemptyTrimmed(script.title) else {
            return nil
        }

        return HomeScriptItem(
            scriptID: script.id,
            scriptVersion: script.version,
            title: title,
            targetGestationalWeek: script.metadata.targetGestationalWeek,
            artworkSeries: artworkSeries
        )
    }

    /// 선택적 문자열의 앞뒤 공백을 제거하고 비어 있지 않은 값만 화면에 전달합니다.
    /// - Parameter value: 프로필 또는 번들 문서에서 읽은 선택적 원문입니다.
    /// - Returns: 정리 후 내용이 있으면 문자열을, 없으면 `nil`을 반환합니다.
    private static func nonemptyTrimmed(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
