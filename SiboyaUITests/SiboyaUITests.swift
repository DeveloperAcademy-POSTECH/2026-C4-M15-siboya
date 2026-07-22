//
//  SiboyaUITests.swift
//  SiboyaUITests
//
//  Created by Gosan on 7/13/26.
//

import XCTest

/// 실제 앱을 실행해 Home과 대본 미리보기 사이의 시스템 navigation 동작을 검증합니다.
final class SiboyaUITests: XCTestCase {
    /// 각 테스트가 사용할 앱 프로세스입니다.
    private var app: XCUIApplication?

    /// 실패 뒤 다음 검증을 계속하지 않고 앱을 Home에서 새로 시작합니다.
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app?.launch()
    }

    /// 테스트가 끝난 앱을 종료해 다음 테스트의 navigation path가 남지 않게 합니다.
    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    /// Home 대본 버튼을 선택하면 시스템 BackButton이 나타나고 사라진 뒤 같은 Home 버튼으로 돌아오는지 검증합니다.
    @MainActor
    func testPreviewShowsSystemBackButtonAndReturnsHome() throws {
        // setUp에서 생성한 앱이 없으면 이후의 화면 탐색이 무의미하므로 즉시 실패 처리합니다.
        guard let app else {
            XCTFail("UI 테스트 앱을 시작하지 못했습니다.")
            return
        }

        // Preview Hero의 같은 제목 Text와 구분하고 주차 value가 합쳐진 label도 허용하도록 Home 버튼만 찾습니다.
        let homeScriptButton = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", "일요일 아침 냄새"))
            .firstMatch
        XCTAssertTrue(homeScriptButton.waitForExistence(timeout: 5))

        homeScriptButton.tap()

        // 다른 화면의 동명 버튼이 아닌 현재 navigation bar의 시스템 BackButton만 찾습니다.
        let backButton = app.navigationBars.buttons.matching(identifier: "BackButton").firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))

        backButton.tap()
        // 시스템 뒤로가기 애니메이션이 끝날 때까지 기다려 Preview에만 있던 BackButton의 소멸을 검증합니다.
        XCTAssertTrue(backButton.waitForNonExistence(timeout: 3))
        // 같은 Home 버튼이 다시 나타나야 실제 navigation path 복귀를 검증할 수 있습니다.
        XCTAssertTrue(homeScriptButton.waitForExistence(timeout: 3))
    }

    /// 미리보기의 준비하기가 준비자세 sheet만 열고 닫기 뒤 같은 미리보기를 유지하는지 검증합니다.
    @MainActor
    func testPreparationSheetShowsFigmaContentAndReturnsPreview() throws {
        // setUp에서 생성한 앱이 없으면 이후의 화면 탐색이 무의미하므로 즉시 실패 처리합니다.
        guard let app else {
            XCTFail("UI 테스트 앱을 시작하지 못했습니다.")
            return
        }

        // Home 대본 버튼을 통해 실제 navigation과 route 생성 경로를 사용합니다.
        let homeScriptButton = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", "일요일 아침 냄새"))
            .firstMatch
        XCTAssertTrue(homeScriptButton.waitForExistence(timeout: 5))

        // 수정된 탭바 배경이 단색이 아닌지 xcresult에서 Figma와 직접 비교할 Home 화면을 남깁니다.
        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "HomeTabBarGradient"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)

        homeScriptButton.tap()

        let prepareButton = app.buttons["준비하기"]
        XCTAssertTrue(prepareButton.waitForExistence(timeout: 3))
        prepareButton.tap()

        // Figma에 있는 제목, 태명 안내, 시작과 닫기 control이 sheet에 함께 나타나야 합니다.
        let title = app.staticTexts["TaedamPreparationTitle"]
        let instruction = app.staticTexts["TaedamPreparationInstruction"]
        let startButton = app.buttons["TaedamPreparationStartButton"]
        let closeButton = app.buttons["TaedamPreparationCloseButton"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertTrue(instruction.waitForExistence(timeout: 3))
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(closeButton.exists)
        XCTAssertTrue(instruction.label.contains("교감할 준비가 되면"))

        // XCUI가 원형 antialias 경계를 안쪽으로 계산해도 최소 40pt 이상의 접근 영역은 유지해야 합니다.
        XCTAssertGreaterThanOrEqual(closeButton.frame.width, 40)
        XCTAssertGreaterThanOrEqual(closeButton.frame.height, 40)

        // xcresult에서 Figma와 비교할 수 있도록 실제 modal 화면을 첨부합니다.
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TaedamPreparationSheet"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        closeButton.tap()

        // 닫기 뒤에는 세션으로 이동하지 않고 미리보기의 준비하기 버튼이 다시 보여야 합니다.
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))
        XCTAssertTrue(prepareButton.waitForExistence(timeout: 3))
    }

    /// 앱 시작 성능을 기존 Xcode 기본 기준으로 계속 측정합니다.
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
