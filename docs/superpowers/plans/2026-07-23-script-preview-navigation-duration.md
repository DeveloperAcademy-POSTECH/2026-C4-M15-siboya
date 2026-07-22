# Script Preview Navigation and Duration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home에서 push된 대본 미리보기의 시스템 뒤로가기를 명시적으로 유지하고 `ScriptPreviewDuration`을 승인된 Figma·SSD 크기로 확대한다.

**Architecture:** `ScriptPreviewDuration`은 측정 가능한 레이아웃 상수를 실제 `HStack` 구조에서 사용해 1pt 세로선과 확대된 중앙 텍스트 영역을 구성한다. `ScriptPreviewView`는 시스템 navigation bar의 visible 계약을 명시하며, 기존 UI Test 타깃이 실제 Home → Preview → Home 경로와 `BackButton`을 검증한다.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest/XCUIAutomation, Xcode 26 iOS Simulator

## Global Constraints

- 기능과 이동 계약은 `docs/design/taedam-session-spec.md` 및 `docs/superpowers/specs/2026-07-22-script-preview-flow-design.md`를 따른다.
- 화면 크기와 간격은 Figma `대본&생각힌트 미리보기` 노드 `1009:11964`를 따른다.
- SSD가 명시한 세로 separator 두께 `1pt`는 Figma의 `0.5pt`보다 우선한다.
- 실제 문구와 소요 시간 값은 기존 번들 JSON과 `ScriptPreviewDuration.durationText` 변환 결과를 유지한다.
- 신규·수정 Swift 코드와 테스트에는 역할, 상호작용과 검증 의도를 설명하는 한국어 주석을 작성한다.
- 커스텀 뒤로가기 버튼이나 `navigationBarBackButtonHidden(true)`를 추가하지 않고 시스템 back swipe를 유지한다.
- 권한, sheet, Alert, `TaedamScreen`, Hero safe-area 배치, Home 데이터 조회와 사용자 소유 프로젝트·에셋 변경은 수정하지 않는다.

---

### Task 1: Duration을 Figma·SSD 크기로 확대

**Files:**
- Modify: `Siboya/Features/Home/Component/ScriptPreviewDuration.swift`
- Test: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`

**Interfaces:**
- Consumes: `estimatedDurationSeconds: Int?`, 기존 `durationText: String?`
- Produces: `separatorThickness`, `separatorHeight`, `itemSpacing`, `contentMinimumWidth`, `contentPadding` 레이아웃 계약과 확대된 SwiftUI View

- [ ] **Step 1: 레이아웃 수치와 fitting size를 검증하는 실패 테스트 작성**

`SiboyaTests/Home/ScriptPreviewComponentsTests.swift`의 기존 separator 테스트를 다음처럼 확장한다.

```swift
    /// 소요시간 영역이 SSD의 선 두께와 Figma의 높이·간격·중앙 크기를 함께 유지하는지 검증합니다.
    @Test @MainActor
    func durationUsesApprovedLayoutMetrics() {
        #expect(ScriptPreviewDuration.separatorThickness == 1)
        #expect(ScriptPreviewDuration.separatorHeight == 35)
        #expect(ScriptPreviewDuration.itemSpacing == 18)
        #expect(ScriptPreviewDuration.contentMinimumWidth == 73)
        #expect(ScriptPreviewDuration.contentPadding == 10)
    }

    /// 일반 글자 크기에서 Figma 기본 크기를 확보하고 접근성 글자 크기에서는 잘리지 않게 확장되는지 검증합니다.
    @Test @MainActor
    func durationMeetsFigmaSizeAndGrowsForAccessibilityText() {
        let regularSize = fittingSize(
            of: ScriptPreviewDuration(estimatedDurationSeconds: 61)
                .environment(\.dynamicTypeSize, .medium)
        )
        let accessibilitySize = fittingSize(
            of: ScriptPreviewDuration(estimatedDurationSeconds: 61)
                .environment(\.dynamicTypeSize, .accessibility3)
        )

        #expect(regularSize.width >= 111)
        #expect(regularSize.height >= 67)
        #expect(accessibilitySize.width > regularSize.width)
        #expect(accessibilitySize.height > regularSize.height)
    }
```

기존 `heroGrowsForAccessibilityText()`는 새 크기 helper의 `.height`를 사용하도록 바꾸고 `fittingHeight`를 다음 helper로 교체한다.

```swift
        let regularHeight = fittingSize(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .medium)
        ).height
        let accessibilityHeight = fittingSize(
            of: makeLongTitleHero()
                .environment(\.dynamicTypeSize, .accessibility3)
        ).height
```

```swift
    /// 주어진 SwiftUI View가 402×1000pt 제약 안에서 선택한 적정 크기를 계산합니다.
    /// - Parameter view: 크기를 측정할 SwiftUI View입니다.
    /// - Returns: 402×1000pt 제약 안에서 View가 선택한 적정 크기입니다.
    @MainActor
    private func fittingSize<Content: View>(of view: Content) -> CGSize {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 402, height: 1000))
    }
```

- [ ] **Step 2: 새 레이아웃 계약이 없어서 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests/durationUsesApprovedLayoutMetrics -only-testing:SiboyaTests/ScriptPreviewComponentsTests/durationMeetsFigmaSizeAndGrowsForAccessibilityText
```

Expected: FAIL at compile time because `separatorHeight`, `itemSpacing`, `contentMinimumWidth`, and `contentPadding` do not exist.

- [ ] **Step 3: 승인된 수치를 실제 Duration 레이아웃에 적용**

`Siboya/Features/Home/Component/ScriptPreviewDuration.swift`의 수치 계약과 `body`, `separator`를 다음처럼 구현한다.

```swift
    /// SSD가 승인한 세로 장식선의 고정 두께입니다.
    static let separatorThickness: CGFloat = 1

    /// Figma에서 양쪽 장식선이 차지하는 세로 길이입니다.
    static let separatorHeight: CGFloat = 35

    /// Figma에서 장식선과 중앙 텍스트 영역 사이에 둔 간격입니다.
    static let itemSpacing: CGFloat = 18

    /// 일반 글자 크기에서 중앙 정보 영역이 유지할 최소 너비입니다.
    static let contentMinimumWidth: CGFloat = 73

    /// 중앙 정보 영역이 텍스트 둘레에 제공하는 Figma 기준 여백입니다.
    static let contentPadding: CGFloat = 10
```

```swift
    /// 값이 있을 때 확대된 중앙 텍스트 영역을 양쪽 세로선으로 감싸 가운데 정렬합니다.
    @ViewBuilder
    var body: some View {
        if let durationText {
            HStack(spacing: Self.itemSpacing) {
                separator

                VStack(spacing: 4) {
                    Text("소요시간")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)

                    Text(durationText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                }
                // 일반 크기에서는 Figma의 73pt를 지키고 접근성 글자 크기에서는 필요한 만큼 확장합니다.
                .padding(Self.contentPadding)
                .frame(minWidth: Self.contentMinimumWidth)

                separator
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Figma 높이와 SSD 두께를 함께 적용한 세로 장식선입니다.
    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(
                width: Self.separatorThickness,
                height: Self.separatorHeight
            )
            .accessibilityHidden(true)
    }
```

- [ ] **Step 4: Duration 집중 테스트와 기존 Hero 접근성 테스트 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests
```

Expected: PASS. Duration 표시값·레이아웃·Dynamic Type와 기존 Hero·Body·BottomBar 테스트가 모두 성공한다.

- [ ] **Step 5: Task 1 변경만 커밋**

```bash
git add Siboya/Features/Home/Component/ScriptPreviewDuration.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift
git commit -m "fix: 대본 미리보기 소요시간 크기 조정"
```

Expected: 커밋에는 위 두 파일만 포함되고 사용자 소유 프로젝트·에셋 변경의 staged/unstaged 상태는 유지된다.

---

### Task 2: 시스템 뒤로가기 표시를 명시하고 실제 이동 경로 검증

**Files:**
- Modify: `Siboya/Features/Home/View/ScriptPreviewView.swift`
- Modify: `SiboyaTests/Home/ScriptPreviewViewTests.swift`
- Modify: `SiboyaUITests/SiboyaUITests.swift`

**Interfaces:**
- Consumes: `ContentView`의 기존 `NavigationStack(path:)`와 `ScriptPreviewRoute` push
- Produces: `ScriptPreviewView.navigationBarVisibility: Visibility == .visible`, Home → Preview → Home UI 회귀 테스트

- [ ] **Step 1: navigation bar 계약과 실제 BackButton 경로 테스트 작성**

`SiboyaTests/Home/ScriptPreviewViewTests.swift`에 다음 실패 테스트를 추가한다.

```swift
    /// 미리보기 화면이 상위 설정과 무관하게 시스템 navigation bar 표시를 요청하는지 검증합니다.
    @Test
    func previewKeepsSystemNavigationBarVisible() {
        #expect(ScriptPreviewView.navigationBarVisibility == .visible)
    }
```

`SiboyaUITests/SiboyaUITests.swift`의 Xcode 템플릿 주석을 한국어로 바꾸고 실제 이동 테스트를 추가한다.

```swift
import XCTest

/// 실제 앱을 실행해 Home과 대본 미리보기 사이의 시스템 navigation 동작을 검증합니다.
final class SiboyaUITests: XCTestCase {
    /// 각 테스트가 사용할 앱 프로세스입니다.
    private var app: XCUIApplication!

    /// 실패 뒤 다음 검증을 계속하지 않고 앱을 Home에서 새로 시작합니다.
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    /// 테스트가 끝난 앱을 종료해 다음 테스트의 navigation path가 남지 않게 합니다.
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    /// Home 대본을 선택하면 시스템 BackButton이 나타나고 선택 시 같은 Home 목록으로 돌아오는지 검증합니다.
    @MainActor
    func testPreviewShowsSystemBackButtonAndReturnsHome() throws {
        let scriptRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "일요일 아침 냄새"))
            .firstMatch
        XCTAssertTrue(scriptRow.waitForExistence(timeout: 5))

        scriptRow.tap()

        let backButton = app.buttons.matching(identifier: "BackButton").firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))

        backButton.tap()
        XCTAssertTrue(scriptRow.waitForExistence(timeout: 3))
    }

    /// 앱 시작 성능을 기존 Xcode 기본 기준으로 계속 측정합니다.
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
```

- [ ] **Step 2: 새 navigation bar 계약이 없어서 단위 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewViewTests/previewKeepsSystemNavigationBarVisible
```

Expected: FAIL at compile time with `type 'ScriptPreviewView' has no member 'navigationBarVisibility'`.

- [ ] **Step 3: 시스템 navigation bar visible 계약을 실제 View에 적용**

`Siboya/Features/Home/View/ScriptPreviewView.swift`에 다음 계약을 추가한다.

```swift
    /// 상위 화면 설정과 무관하게 시스템 뒤로가기 버튼을 제공하도록 요청할 navigation bar 상태입니다.
    static let navigationBarVisibility: Visibility = .visible
```

기존 navigation modifier를 다음처럼 갱신한다.

```swift
        .navigationBarTitleDisplayMode(.inline)
        // Home에서 push된 화면의 시스템 뒤로가기 버튼과 interactive pop을 명시적으로 유지합니다.
        .toolbar(Self.navigationBarVisibility, for: .navigationBar)
        // 시스템 뒤로가기 버튼은 유지하면서 Hero 배경이 navigation bar 뒤에서도 보이게 합니다.
        .toolbarBackground(.hidden, for: .navigationBar)
```

- [ ] **Step 4: navigation 단위 테스트와 실제 UI 이동 테스트 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewViewTests
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaUITests/SiboyaUITests/testPreviewShowsSystemBackButtonAndReturnsHome
```

Expected: PASS. visible 계약이 성공하고 실제 앱에서 `BackButton`이 표시된 뒤 Home 목록으로 복귀한다.

- [ ] **Step 5: 전체 회귀 테스트, lint와 Debug Simulator 빌드 실행**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests
./Scripts/lint.sh
xcodebuild build -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Expected: 모든 `SiboyaTests` PASS, SwiftLint 오류 0건, `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Task 2 변경만 커밋**

```bash
git add Siboya/Features/Home/View/ScriptPreviewView.swift SiboyaTests/Home/ScriptPreviewViewTests.swift SiboyaUITests/SiboyaUITests.swift
git commit -m "fix: 대본 미리보기 시스템 뒤로가기 유지"
```

Expected: 커밋에는 위 세 파일만 포함되고 사용자 소유 프로젝트·에셋 변경의 staged/unstaged 상태는 유지된다.
