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
    /// Home 배경이 컬러 시스템의 라이트·다크 값을 각각 사용해 명암을 반전하는지 검증합니다.
    @Test @MainActor
    func homeBackgroundAdaptsToDarkMode() throws {
        let lightRenderer = ImageRenderer(
            content: HomeView(state: .empty)
                .environment(\.colorScheme, .light)
                .frame(width: 402, height: 874)
        )
        lightRenderer.scale = 1

        let darkRenderer = ImageRenderer(
            content: HomeView(state: .empty)
                .environment(\.colorScheme, .dark)
                .frame(width: 402, height: 874)
        )
        darkRenderer.scale = 1

        let lightImage = try #require(lightRenderer.uiImage)
        let darkImage = try #require(darkRenderer.uiImage)
        let lightComponents = try #require(
            pixelComponents(in: lightImage, at: CGPoint(x: 201, y: 100))
        )
        let darkComponents = try #require(
            pixelComponents(in: darkImage, at: CGPoint(x: 201, y: 100))
        )

        #expect(lightComponents.red > 0.9)
        #expect(lightComponents.green > 0.9)
        #expect(lightComponents.blue > 0.9)
        #expect(darkComponents.red < 0.2)
        #expect(darkComponents.green < 0.2)
        #expect(darkComponents.blue < 0.2)
    }

    /// 접근성 글자 크기에서는 하단 탭이 48pt에 잘리지 않고 내용 높이에 맞춰 확장되는지 검증합니다.
    @Test @MainActor
    func bottomTabBarGrowsForAccessibilityText() {
        let regularHeight = fittingHeight(
            of: HomeBottomTabBar(
                selectedTab: .taedam,
                onSelectTaedam: {},
                onSelectPromise: {}
            )
                .environment(\.dynamicTypeSize, .medium)
        )
        let accessibilityHeight = fittingHeight(
            of: HomeBottomTabBar(
                selectedTab: .taedam,
                onSelectTaedam: {},
                onSelectPromise: {}
            )
                .environment(\.dynamicTypeSize, .accessibility5)
        )

        #expect(accessibilityHeight > regularHeight)
    }

    /// 탭바 상단은 뒤 콘텐츠를 노출하고 하단은 시스템 배경으로 이어져 단색 흰 띠가 되지 않는지 검증합니다.
    @Test @MainActor
    func bottomTabBarBackgroundFadesFromContentToSystemBackground() throws {
        // Figma는 탭바 높이의 절반까지 투명 상태를 유지하고 하단 바깥 지점까지 배경색을 보간합니다.
        #expect(HomeBottomTabBar.backgroundFadeStartY == 0.5)
        #expect(HomeBottomTabBar.backgroundFadeEndY == 1.1684)

        let renderer = ImageRenderer(
            content: HomeBottomTabBar(
                selectedTab: .taedam,
                onSelectTaedam: {},
                onSelectPromise: {}
            )
                // 투명 gradient가 실제로 뒤 콘텐츠를 드러내는지 판별하기 위한 대비색입니다.
                .background(Color.red)
                .frame(width: 402)
        )
        renderer.scale = 1

        let image = try #require(renderer.uiImage)
        // Core Graphics의 원점은 좌하단이므로 이미지 상단은 큰 y, 하단은 작은 y 좌표로 읽습니다.
        let visualTopPixel = try #require(
            pixelComponents(
                in: image,
                at: CGPoint(x: 4, y: image.size.height - 2)
            )
        )
        let visualBottomPixel = try #require(
            pixelComponents(in: image, at: CGPoint(x: 4, y: 1))
        )

        // 상단보다 하단의 녹색 채널이 충분히 커야 흰 시스템 배경으로 실제 보간됐다고 판단합니다.
        #expect(visualTopPixel.green < visualBottomPixel.green)
        #expect(visualBottomPixel.green - visualTopPixel.green > 0.3)
    }

    /// 하단 탭 바의 태담과 약속 버튼이 각각 대응하는 상위 동작을 한 번씩 전달하는지 검증합니다.
    @Test @MainActor
    func bottomTabBarForwardsEachTabSelection() {
        var taedamSelectionCount = 0
        var promiseSelectionCount = 0
        let tabBar = HomeBottomTabBar(
            selectedTab: .taedam,
            onSelectTaedam: { taedamSelectionCount += 1 },
            onSelectPromise: { promiseSelectionCount += 1 }
        )

        tabBar.selectTaedam()
        tabBar.selectPromise()

        #expect(taedamSelectionCount == 1)
        #expect(promiseSelectionCount == 1)
    }

    /// 첫 번째 이미지 시리즈가 네 표시 위치에 맞는 에셋 이름을 만드는지 검증합니다.
    @Test
    func firstArtworkSeriesBuildsRoleSpecificAssetNames() {
        let series = ScriptArtworkSeries.cycling(forZeroBasedIndex: 0)

        #expect(series.rowAssetName == "TitleImage1")
        #expect(series.cardAssetName == "TitleImage1Card")
        #expect(series.thumbnailAssetName == "TitleImage1Thumbnail")
        #expect(series.backgroundAssetName == "TitleImage1Back")
    }

    /// 일곱 번째 뒤의 항목이 다시 첫 번째 이미지 묶음으로 순환하는지 검증합니다.
    @Test
    func artworkSeriesCyclesAfterSeventhItem() {
        let seventhSeries = ScriptArtworkSeries.cycling(forZeroBasedIndex: 6)
        let eighthSeries = ScriptArtworkSeries.cycling(forZeroBasedIndex: 7)

        #expect(seventhSeries.rowAssetName == "TitleImage7")
        #expect(seventhSeries.cardAssetName == "TitleImage7Card")
        #expect(seventhSeries.thumbnailAssetName == "TitleImage7Thumbnail")
        #expect(seventhSeries.backgroundAssetName == "TitleImage7Back")
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
        let artwork = ScriptArtworkView(assetName: "  \n", cornerRadius: 17)

        #expect(artwork.resolvedAssetName == nil)
        #expect(artwork.resolvedImage == nil)
    }

    /// 등록되지 않은 에셋 이름일 때 이미지 대신 플레이스홀더 조건이 만들어지는지 검증합니다.
    @Test
    @MainActor
    func artworkUsesPlaceholderWhenAssetDoesNotExist() {
        let artwork = ScriptArtworkView(
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
