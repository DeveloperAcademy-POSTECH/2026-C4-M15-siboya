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

        let backButton = app.buttons.matching(identifier: "BackButton").firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))

        backButton.tap()
        // 시스템 뒤로가기가 완료되면 Preview에만 있던 BackButton이 없어져야 합니다.
        XCTAssertFalse(backButton.waitForExistence(timeout: 3))
        // 같은 Home 버튼이 다시 나타나야 실제 navigation path 복귀를 검증할 수 있습니다.
        XCTAssertTrue(homeScriptButton.waitForExistence(timeout: 3))
    }

    /// 앱 시작 성능을 기존 Xcode 기본 기준으로 계속 측정합니다.
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
