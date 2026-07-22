//
//  HomeViewStateTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Testing
@testable import Siboya

/// 프로필·주차 콘텐츠·대본 문서가 Home 표시 상태로 변환되는 규칙을 검증합니다.
struct HomeViewStateTests {
    /// Home 화면 모델이 SwiftData 저장소의 태명·주차와 두 번들 문서를 읽어 추천 상태를 만드는지 검증합니다.
    @Test @MainActor
    func screenModelLoadsStoredBabyProfileAndBundledContent() throws {
        let repository = HomeProfileRepositoryStub(
            fetchAction: {
                BabyProfile(nickname: "꾹꾹이", gestationalWeek: 22)
            }
        )
        let model = HomeScreenModel(
            weeklyContentLoader: { try BundledHomeWeeklyContentLoader.load() },
            scriptDocumentLoader: { try BundledTaedamScriptLoader.load() }
        )

        model.load(repository: repository)

        #expect(model.state.babyNickname == "꾹꾹이")
        #expect(model.state.recommendation?.item.title == "오후의 동네 산책")
        #expect(model.state.categories.flatMap(\.items).count == 6)
    }

    /// 주차 문서 로딩만 실패하면 SwiftData 태명과 정상 대본 카테고리는 계속 남는지 검증합니다.
    @Test @MainActor
    func weeklyContentFailureKeepsProfileAndScriptCategories() throws {
        let repository = HomeProfileRepositoryStub(
            fetchAction: {
                BabyProfile(nickname: "꾹꾹이", gestationalWeek: 22)
            }
        )
        let model = HomeScreenModel(
            weeklyContentLoader: { throw HomeScreenModelTestError.loadingFailed },
            scriptDocumentLoader: { try BundledTaedamScriptLoader.load() }
        )

        model.load(repository: repository)

        #expect(model.state.babyNickname == "꾹꾹이")
        #expect(model.state.recommendation == nil)
        #expect(model.state.categories.flatMap(\.items).count == 6)
    }

    /// SwiftData 조회만 실패하면 프로필 의존 영역은 숨기고 정상 대본 목록은 유지하는지 검증합니다.
    @Test @MainActor
    func profileFailureKeepsScriptCategories() throws {
        let repository = HomeProfileRepositoryStub(
            fetchAction: { throw HomeScreenModelTestError.loadingFailed }
        )
        let model = HomeScreenModel(
            weeklyContentLoader: { try BundledHomeWeeklyContentLoader.load() },
            scriptDocumentLoader: { try BundledTaedamScriptLoader.load() }
        )

        model.load(repository: repository)

        #expect(model.state.babyNickname == nil)
        #expect(model.state.recommendation == nil)
        #expect(model.state.categories.flatMap(\.items).count == 6)
    }

    /// 대본 문서 로딩만 실패하면 SwiftData 태명은 표시하되 대본 의존 영역은 비우는지 검증합니다.
    @Test @MainActor
    func scriptFailureKeepsBabyNickname() throws {
        let repository = HomeProfileRepositoryStub(
            fetchAction: {
                BabyProfile(nickname: "꾹꾹이", gestationalWeek: 22)
            }
        )
        let model = HomeScreenModel(
            weeklyContentLoader: { try BundledHomeWeeklyContentLoader.load() },
            scriptDocumentLoader: { throw HomeScreenModelTestError.loadingFailed }
        )

        model.load(repository: repository)

        #expect(model.state.babyNickname == "꾹꾹이")
        #expect(model.state.recommendation == nil)
        #expect(model.state.categories.isEmpty)
    }

    /// 20~40주의 21개 추천이 일곱 이미지 시리즈를 순서대로 세 번 반복하는지 검증합니다.
    @Test
    func recommendationArtworkCyclesThreeTimesAcrossTwentyOneWeeks() throws {
        let weeklyDocument = try BundledHomeWeeklyContentLoader.load()
        let scriptDocument = try BundledTaedamScriptLoader.load()

        let artworkNumbers = weeklyDocument.weeks.compactMap { weeklyContent in
            HomeViewStateBuilder.make(
                babyNickname: "꾹꾹이",
                gestationalWeek: weeklyContent.gestationalWeek,
                weeklyDocument: weeklyDocument,
                scriptDocument: scriptDocument
            ).recommendation?.item.artworkSeries.rawValue
        }

        #expect(artworkNumbers == Array(repeating: Array(1...7), count: 3).flatMap { $0 })
    }

    /// 대본 JSON의 최초 등장 순서가 카테고리와 각 행의 이미지 번호에 그대로 반영되는지 검증합니다.
    @Test
    func categoriesAndRowArtworkPreserveBundledScriptOrder() throws {
        let scriptDocument = try BundledTaedamScriptLoader.load()

        let state = HomeViewStateBuilder.make(
            babyNickname: nil,
            gestationalWeek: nil,
            weeklyDocument: nil,
            scriptDocument: scriptDocument
        )

        #expect(state.categories.map(\.title) == [
            "집에서 소소하게",
            "밖으로 한 걸음",
            "멀리멀리 대모험"
        ])
        #expect(state.categories.flatMap(\.items).map(\.rowArtworkAssetName) == [
            "TitleImage1",
            "TitleImage2",
            "TitleImage3",
            "TitleImage4",
            "TitleImage5",
            "TitleImage6"
        ])
    }

    /// SwiftData 프로필의 현재 주차로 headline과 추천 대본을 찾고 목록에서도 같은 대본을 유지하는지 검증합니다.
    @Test
    func currentWeekBuildsLinkedRecommendationWithoutRemovingItsRow() throws {
        let weeklyDocument = try BundledHomeWeeklyContentLoader.load()
        let scriptDocument = try BundledTaedamScriptLoader.load()

        let state = HomeViewStateBuilder.make(
            babyNickname: " 꾹꾹이 ",
            gestationalWeek: 22,
            weeklyDocument: weeklyDocument,
            scriptDocument: scriptDocument
        )
        let recommendation = try #require(state.recommendation)

        #expect(state.babyNickname == "꾹꾹이")
        #expect(recommendation.headline == "목소리에 반응해 꼼지락 움직이는 시기")
        #expect(recommendation.item.title == "오후의 동네 산책")
        #expect(recommendation.item.cardArtworkAssetName == "TitleImage3Card")
        #expect(state.categories.flatMap(\.items).contains {
            $0.scriptID == recommendation.item.scriptID
        })
    }

    /// 추천 UUID에 맞는 대본이 없어도 정상 대본의 카테고리 목록은 남는지 검증합니다.
    @Test
    func missingRecommendedScriptHidesOnlyRecommendation() throws {
        let scriptDocument = try BundledTaedamScriptLoader.load()
        let weeklyDocument = HomeWeeklyContentDocument(
            weeks: [
                HomeWeeklyContent(
                    gestationalWeek: 22,
                    headline: "연결되지 않은 추천",
                    recommendedScriptID: UUID()
                )
            ]
        )

        let state = HomeViewStateBuilder.make(
            babyNickname: "꾹꾹이",
            gestationalWeek: 22,
            weeklyDocument: weeklyDocument,
            scriptDocument: scriptDocument
        )

        #expect(state.recommendation == nil)
        #expect(state.categories.flatMap(\.items).count == 6)
    }

    /// 프로필이 없을 때 태명과 추천만 숨기고 대본 탐색 목록은 계속 제공하는지 검증합니다.
    @Test
    func missingProfileKeepsScriptCategories() throws {
        let state = HomeViewStateBuilder.make(
            babyNickname: nil,
            gestationalWeek: nil,
            weeklyDocument: try BundledHomeWeeklyContentLoader.load(),
            scriptDocument: try BundledTaedamScriptLoader.load()
        )

        #expect(state.babyNickname == nil)
        #expect(state.recommendation == nil)
        #expect(state.categories.flatMap(\.items).count == 6)
    }

    /// 빈 카테고리나 제목의 대본만 제외하고 유효한 대본의 원래 이미지 순서는 바꾸지 않는지 검증합니다.
    @Test
    func invalidScriptsAreSkippedWithoutShiftingArtworkOrder() {
        let scriptDocument = TaedamScriptDocument(
            scripts: [
                makeScript(category: "   ", title: "카테고리 없음"),
                makeScript(category: "집에서 소소하게", title: "  "),
                makeScript(category: " 집에서 소소하게 ", title: " 유효한 제목 ")
            ]
        )

        let state = HomeViewStateBuilder.make(
            babyNickname: nil,
            gestationalWeek: nil,
            weeklyDocument: nil,
            scriptDocument: scriptDocument
        )
        let onlyCategory = state.categories.first

        #expect(state.categories.count == 1)
        #expect(onlyCategory?.title == "집에서 소소하게")
        #expect(onlyCategory?.items.map(\.title) == ["유효한 제목"])
        #expect(onlyCategory?.items.first?.rowArtworkAssetName == "TitleImage3")
    }

    /// 빈 값 제외 테스트에서 데이터 변환에 필요한 최소 대본 한 개를 생성합니다.
    /// - Parameters:
    ///   - category: 정리 및 유효성 검증을 거칠 카테고리 문자열입니다.
    ///   - title: 정리 및 유효성 검증을 거칠 대본 제목입니다.
    /// - Returns: Home 상태 생성기가 소비할 수 있는 번들 대본 모델입니다.
    private func makeScript(category: String, title: String) -> TaedamScriptContent {
        TaedamScriptContent(
            id: UUID(),
            version: 1,
            category: category,
            title: title,
            metadata: ScriptMetadataContent(
                targetGestationalWeek: 20,
                artworkAssetName: "legacy-artwork-name",
                estimatedDurationSeconds: nil
            ),
            sentences: ["안녕"],
            bucketListPrompt: "함께 하고 싶어.",
            bucketListGuide: "함께 할 일을 이야기해 보세요."
        )
    }
}

/// Home 화면 모델 테스트에서 의도적인 저장소·로더 실패를 표현합니다.
private enum HomeScreenModelTestError: Error {
    /// 특정 데이터 소스가 값을 제공하지 못하는 상황입니다.
    case loadingFailed
}

/// 전체 저장소 구현 없이 Home이 사용하는 프로필 조회 결과만 제어하는 테스트 대역입니다.
private final class HomeProfileRepositoryStub: TaedamRepository, @unchecked Sendable {
    /// 프로필 반환 또는 오류 발생을 테스트별로 결정하는 동작입니다.
    private let fetchAction: () throws -> BabyProfile?

    /// 테스트가 전달한 프로필 조회 동작을 저장합니다.
    /// - Parameter fetchAction: 호출 시 프로필 또는 오류를 반환할 클로저입니다.
    init(fetchAction: @escaping () throws -> BabyProfile?) {
        self.fetchAction = fetchAction
    }

    /// `HomeScreenModel`이 호출할 프로필 조회 결과를 테스트가 지정한 대로 반환합니다.
    /// - Returns: 저장된 테스트 프로필 또는 `nil`입니다.
    func fetchBabyProfile() throws -> BabyProfile? {
        try fetchAction()
    }

    /// Home 읽기 테스트에서는 프로필 생성이 필요하지 않아 아무 작업도 하지 않습니다.
    func ensureBabyProfile(nickname: String, gestationalWeek: Int) async throws {}

    /// Home 읽기 테스트에서는 태명 수정이 필요하지 않아 아무 작업도 하지 않습니다.
    func updateNickname(_ nickname: String) async throws {}

    /// Home 읽기 테스트에서 예기치 않은 버킷리스트 저장 호출을 오류로 드러냅니다.
    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO {
        throw HomeScreenModelTestError.loadingFailed
    }

    /// Home 읽기 테스트에서는 버킷리스트 내용을 수정하지 않습니다.
    func updateContent(command: UpdateBucketListContentCommandDTO) async throws {}

    /// Home 읽기 테스트에서는 버킷리스트 완료 상태를 변경하지 않습니다.
    func toggleCompletion(bucketListItemID: UUID) async throws {}

    /// Home 읽기 테스트에서는 버킷리스트를 삭제하지 않습니다.
    func delete(bucketListItemID: UUID) async throws {}
}
