//
//  HomeComponentsTests.swift
//  SiboyaTests
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Siboya

/// Home 모델과 컴포넌트가 표시 및 선택 계약을 지키는지 검증합니다.
struct HomeComponentsTests {
    /// 다크 모드 Home의 빈 상단 배경이 밝은 고정색으로 남지 않고 어두운 시스템 배경으로 렌더링되는지 검증합니다.
    @Test @MainActor
    func homeBackgroundAdaptsToDarkMode() throws {
        let renderer = ImageRenderer(
            content: HomeView(state: .empty)
                .environment(\.colorScheme, .dark)
                .frame(width: 402, height: 874)
        )
        renderer.scale = 1

        let image = try #require(renderer.uiImage)
        let components = try #require(
            pixelComponents(in: image, at: CGPoint(x: 201, y: 100))
        )

        // 세 색상 채널이 모두 낮아야 다크 모드의 어두운 시스템 배경으로 판단합니다.
        #expect(components.red < 0.2)
        #expect(components.green < 0.2)
        #expect(components.blue < 0.2)
    }

    /// 접근성 글자 크기에서는 하단 탭이 48pt에 잘리지 않고 내용 높이에 맞춰 확장되는지 검증합니다.
    @Test @MainActor
    func bottomTabBarGrowsForAccessibilityText() {
        let regularHeight = fittingHeight(
            of: HomeBottomTabBar(onSelectTaedam: {}, onSelectPromise: {})
                .environment(\.dynamicTypeSize, .medium)
        )
        let accessibilityHeight = fittingHeight(
            of: HomeBottomTabBar(onSelectTaedam: {}, onSelectPromise: {})
                .environment(\.dynamicTypeSize, .accessibility5)
        )

        #expect(accessibilityHeight > regularHeight)
    }

    /// 하단 탭 바의 태담과 약속 버튼이 각각 대응하는 상위 동작을 한 번씩 전달하는지 검증합니다.
    @Test @MainActor
    func bottomTabBarForwardsEachTabSelection() {
        var taedamSelectionCount = 0
        var promiseSelectionCount = 0
        let tabBar = HomeBottomTabBar(
            onSelectTaedam: { taedamSelectionCount += 1 },
            onSelectPromise: { promiseSelectionCount += 1 }
        )

        tabBar.selectTaedam()
        tabBar.selectPromise()

        #expect(taedamSelectionCount == 1)
        #expect(promiseSelectionCount == 1)
    }

    /// 첫 번째 이미지 시리즈가 행과 추천 카드에서 각각 올바른 에셋 이름을 만드는지 검증합니다.
    @Test
    func firstArtworkSeriesBuildsRoleSpecificAssetNames() {
        let series = HomeArtworkSeries.cycling(forZeroBasedIndex: 0)

        #expect(series.rowAssetName == "TitleImage1")
        #expect(series.cardAssetName == "TitleImage1Card")
    }

    /// 일곱 번째 뒤의 항목이 다시 첫 번째 이미지로 돌아와 임의 중복 규칙이 결정적으로 유지되는지 검증합니다.
    @Test
    func artworkSeriesCyclesAfterSeventhItem() {
        let seventhSeries = HomeArtworkSeries.cycling(forZeroBasedIndex: 6)
        let eighthSeries = HomeArtworkSeries.cycling(forZeroBasedIndex: 7)

        #expect(seventhSeries.rowAssetName == "TitleImage7")
        #expect(seventhSeries.cardAssetName == "TitleImage7Card")
        #expect(eighthSeries == .one)
    }

    /// 같은 대본이라도 버전이 다르면 서로 다른 화면 항목 ID를 만드는지 검증합니다.
    @Test
    func scriptItemIDIncludesVersion() throws {
        let scriptID = try #require(
            UUID(uuidString: "57A07A17-20D6-440C-989F-0B1208B6ED01")
        )
        let firstVersion = makeItem(scriptID: scriptID, version: 1)
        let secondVersion = makeItem(scriptID: scriptID, version: 2)

        #expect(firstVersion.id != secondVersion.id)
        #expect(firstVersion.id == "57A07A17-20D6-440C-989F-0B1208B6ED01-1")
    }

    /// 주입한 임신 주차가 사용자에게 보여줄 한국어 문자열로 변환되는지 검증합니다.
    @Test
    func gestationalWeekTextUsesInjectedWeek() {
        #expect(makeItem(week: 20).gestationalWeekText == "20주차")
        #expect(makeItem(week: 40).gestationalWeekText == "40주차")
    }

    /// 공백뿐인 에셋 이름을 유효한 이미지 이름으로 취급하지 않는지 검증합니다.
    @Test
    @MainActor
    func artworkIgnoresBlankAssetName() {
        let artwork = HomeArtworkView(assetName: "  \n", cornerRadius: 17)

        #expect(artwork.resolvedAssetName == nil)
        #expect(artwork.resolvedImage == nil)
    }

    /// 등록되지 않은 에셋 이름일 때 이미지 대신 플레이스홀더 조건이 만들어지는지 검증합니다.
    @Test
    @MainActor
    func artworkUsesPlaceholderWhenAssetDoesNotExist() {
        let artwork = HomeArtworkView(
            assetName: "missing-\(UUID().uuidString)",
            cornerRadius: 17
        )

        #expect(artwork.resolvedAssetName != nil)
        #expect(artwork.resolvedImage == nil)
    }

    /// 추천 카드를 선택하면 대본 UUID와 정확한 버전이 상위 화면으로 전달되는지 검증합니다.
    @Test
    @MainActor
    func recommendationCardForwardsScriptSelection() {
        let item = makeItem(version: 3)
        var receivedID: UUID?
        var receivedVersion: Int?
        let card = HomeRecommendationCard(item: item) { scriptID, version in
            receivedID = scriptID
            receivedVersion = version
        }

        card.select()

        #expect(receivedID == item.scriptID)
        #expect(receivedVersion == 3)
    }

    /// 디자인 규격에 따라 추천 카드 높이가 230pt로 고정되어 있는지 검증합니다.
    @Test
    func recommendationCardHeightIsFixedAt230Points() {
        #expect(HomeRecommendationCard.height == 230)
    }

    /// 대본 행을 선택하면 대본 UUID와 정확한 버전이 상위 화면으로 전달되는지 검증합니다.
    @Test
    @MainActor
    func scriptRowForwardsScriptSelection() {
        let item = makeItem(version: 4)
        var receivedID: UUID?
        var receivedVersion: Int?
        let row = HomeScriptRow(item: item) { scriptID, version in
            receivedID = scriptID
            receivedVersion = version
        }

        row.select()

        #expect(receivedID == item.scriptID)
        #expect(receivedVersion == 4)
    }

    /// 항목이 없는 카테고리는 숨기고 항목이 있는 카테고리만 표시하는지 검증합니다.
    @Test
    @MainActor
    func categorySectionHidesEmptyItems() {
        let emptySection = HomeCategorySection(
            title: "멀리멀리 대모험",
            items: [],
            onSelect: { _, _ in }
        )
        let populatedSection = HomeCategorySection(
            title: "멀리멀리 대모험",
            items: [makeItem()],
            onSelect: { _, _ in }
        )

        #expect(!emptySection.hasContent)
        #expect(populatedSection.hasContent)
    }

    /// 각 테스트가 필요한 값만 바꿀 수 있도록 기본 Home 대본 모델을 생성합니다.
    private func makeItem(
        scriptID: UUID = UUID(),
        version: Int = 1,
        week: Int = 20
    ) -> HomeScriptItem {
        HomeScriptItem(
            scriptID: scriptID,
            scriptVersion: version,
            title: "일요일 아침 냄새",
            targetGestationalWeek: week,
            artworkSeries: .one
        )
    }

    /// 주어진 SwiftUI View를 402pt 화면 너비에 배치했을 때 필요한 세로 길이를 계산합니다.
    /// - Parameter view: Dynamic Type 환경이 주입된 하단 탭 View입니다.
    /// - Returns: 402×1000pt 제약 안에서 View가 선택한 적정 높이입니다.
    @MainActor
    private func fittingHeight<Content: View>(of view: Content) -> CGFloat {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 402, height: 1000))
            .height
    }

    /// 렌더링 이미지의 한 지점을 1×1 RGBA 컨텍스트에 그려 정규화한 색상 채널을 읽습니다.
    /// - Parameters:
    ///   - image: 다크 모드 환경에서 렌더링한 Home 이미지입니다.
    ///   - point: 배경색만 존재하는 화면 좌표입니다.
    /// - Returns: 해당 픽셀의 0~1 범위 RGB 값이며 읽지 못하면 `nil`입니다.
    private func pixelComponents(
        in image: UIImage,
        at point: CGPoint
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        guard let cgImage = image.cgImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // 전체 이미지를 반대 방향으로 이동해 요청한 한 픽셀만 1×1 컨텍스트에 들어오게 합니다.
        context.translateBy(x: -point.x, y: -point.y)
        context.draw(
            cgImage,
            in: CGRect(
                x: 0,
                y: 0,
                width: cgImage.width,
                height: cgImage.height
            )
        )

        return (
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255
        )
    }
}
