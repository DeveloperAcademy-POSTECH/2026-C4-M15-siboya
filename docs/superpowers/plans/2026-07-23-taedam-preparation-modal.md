# Taedam Preparation Modal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SSD와 Figma에 맞는 준비자세 표시 컴포넌트를 Home 아래에 구현하고 기존 미리보기 sheet·권한 흐름에 조립한다.

**Architecture:** 이미지, 안내, 시작 버튼은 입력과 callback만 받는 순수 SwiftUI 컴포넌트로 `Home/Component`에 둔다. `TaedamPreparationView`는 이 컴포넌트와 닫기 버튼을 배치하고, 기존 `ScriptPreviewFlowModel`이 sheet·권한·세션 상태 전이를 계속 소유한다.

**Tech Stack:** Swift 5, SwiftUI, UIKit, Swift Testing, XCTest/XCUIAutomation, Xcode 26.5, iOS 26.5

## Global Constraints

- 플로우는 승인된 `docs/design/taedam-session-spec.md`의 준비자세 모달·권한 확인 계약을 따른다.
- 화면은 Figma `준비자세` 노드 `1009:12106`을 따른다.
- `TaedamPreparationView`는 마이크·Speech API 또는 카운트다운을 직접 호출하지 않는다.
- 닫기와 drag dismiss는 권한이나 세션을 시작하지 않고 같은 미리보기 상태를 유지한다.
- 권한 승인 뒤 sheet의 `onDismiss`가 호출된 후에만 기존 `TaedamScreen`을 표시한다.
- 새 컴포넌트는 `Siboya/Features/Home/Component`, 모달 View는 `Siboya/Features/Home/View`에 둔다.
- 신규·수정 Swift 코드와 테스트에는 역할, 처리 이유와 검증 의도를 설명하는 한국어 주석을 작성한다.
- 사용자 소유 `Siboya.xcodeproj/project.pbxproj`와 staged `img_profile.imageset` 파일은 수정하거나 작업 커밋에 포함하지 않는다.

---

### Task 1: 준비자세 표시 컴포넌트 구현

**Files:**
- Create: `Siboya/Features/Home/Component/TaedamPreparationArtwork.swift`
- Create: `Siboya/Features/Home/Component/TaedamPreparationGuidance.swift`
- Create: `Siboya/Features/Home/Component/TaedamPreparationStartButton.swift`
- Create: `SiboyaTests/Home/TaedamPreparationComponentsTests.swift`

**Interfaces:**
- Consumes: Asset Catalog의 `img_profile`, `babyNickname: String`, `isLoading: Bool`, `action: () -> Void`
- Produces: `TaedamPreparationArtwork`, `TaedamPreparationGuidance`, `TaedamPreparationStartButton`

- [ ] **Step 1: 컴포넌트 규격과 callback 실패 테스트 작성**

`SiboyaTests/Home/TaedamPreparationComponentsTests.swift`를 다음처럼 작성한다.

```swift
import SwiftUI
import Testing
@testable import Siboya

/// 준비자세를 구성하는 순수 표시 컴포넌트가 Figma 규격과 사용자 동작을 지키는지 검증합니다.
@MainActor
struct TaedamPreparationComponentsTests {
    /// 프로필 이미지가 지정된 에셋 이름과 Figma의 90×88pt 영역을 사용하는지 검증합니다.
    @Test
    func artworkUsesProfileAssetAndFigmaSize() {
        let artwork = TaedamPreparationArtwork()

        #expect(artwork.assetName == "img_profile")
        #expect(TaedamPreparationArtwork.width == 90)
        #expect(TaedamPreparationArtwork.height == 88)
    }

    /// 안내가 태명을 정확히 치환하고 Figma 제목·본문 크기와 8pt 간격을 사용하는지 검증합니다.
    @Test
    func guidanceBuildsNicknameMessageAndFigmaTypography() {
        let guidance = TaedamPreparationGuidance(babyNickname: "꾹꾹이")

        #expect(guidance.instructionText == "아내의 배에 손을 얹고\n꾹꾹이와 교감할 준비가 되면\n시작 버튼을 눌러주세요")
        #expect(TaedamPreparationGuidance.textSpacing == 8)
        #expect(TaedamPreparationGuidance.titleFontSize == 28)
        #expect(TaedamPreparationGuidance.instructionFontSize == 22)
    }

    /// 시작 버튼이 52pt 높이를 유지하고 로딩 여부에 따라 입력 가능 상태를 계산하는지 검증합니다.
    @Test
    func startButtonUsesFigmaHeightAndLoadingState() {
        let idleButton = TaedamPreparationStartButton(isLoading: false, action: {})
        let loadingButton = TaedamPreparationStartButton(isLoading: true, action: {})

        #expect(TaedamPreparationStartButton.height == 52)
        #expect(idleButton.isEnabled)
        #expect(!loadingButton.isEnabled)
    }

    /// 시작 버튼이 권한 확인을 소유하지 않고 전달받은 callback을 한 번 호출하는지 검증합니다.
    @Test
    func startButtonForwardsActionOnce() {
        var startCount = 0
        let button = TaedamPreparationStartButton(isLoading: false) {
            startCount += 1
        }

        button.start()

        #expect(startCount == 1)
    }
}
```

- [ ] **Step 2: 새 컴포넌트가 없어서 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/TaedamPreparationComponentsTests
```

Expected: FAIL at compile time because the three `TaedamPreparation...` component types do not exist.

- [ ] **Step 3: 프로필 이미지 컴포넌트 구현**

`Siboya/Features/Home/Component/TaedamPreparationArtwork.swift`를 다음처럼 작성한다.

```swift
import SwiftUI
import UIKit

/// 준비자세 sheet에서 프로필 일러스트 또는 같은 크기의 대체 박스를 표시합니다.
struct TaedamPreparationArtwork: View {
    /// Figma가 지정한 프로필 일러스트 너비입니다.
    static let width: CGFloat = 90

    /// Figma가 지정한 프로필 일러스트 높이입니다.
    static let height: CGFloat = 88

    /// 에셋을 지정하지 않았을 때 사용할 준비자세 기본 이미지 이름입니다.
    static let defaultAssetName = "img_profile"

    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 기본 프로필 에셋 또는 테스트용 에셋 이름을 주입합니다.
    /// - Parameter assetName: Asset Catalog에서 찾을 이미지 이름입니다.
    init(assetName: String = Self.defaultAssetName) {
        self.assetName = assetName
    }

    /// 이미지 존재 여부와 무관하게 Figma의 90×88pt 레이아웃을 유지합니다.
    @ViewBuilder
    var body: some View {
        if let image = UIImage(named: assetName) {
            // 실제 일러스트 비율을 바꾸지 않고 지정된 프레임 안에 온전히 표시합니다.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: Self.width, height: Self.height)
                .accessibilityHidden(true)
        } else {
            // 아직 등록되지 않은 에셋도 화면 배치를 바꾸지 않도록 같은 크기의 박스로 대체합니다.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: Self.width, height: Self.height)
                .accessibilityHidden(true)
        }
    }
}
```

- [ ] **Step 4: 안내 컴포넌트 구현**

`Siboya/Features/Home/Component/TaedamPreparationGuidance.swift`를 다음처럼 작성한다.

```swift
import SwiftUI

/// 준비자세 제목과 태명이 치환된 행동 안내를 Figma의 텍스트 계층으로 표시합니다.
struct TaedamPreparationGuidance: View {
    /// Figma에서 제목과 안내 사이에 둔 간격입니다.
    static let textSpacing: CGFloat = 8

    /// Figma Title1/Emphasized에 해당하는 제목 글자 크기입니다.
    static let titleFontSize: CGFloat = 28

    /// Figma Title2/Regular에 해당하는 안내 글자 크기입니다.
    static let instructionFontSize: CGFloat = 22

    /// 실제 사용자에게 전달할 태명을 포함한 안내 문구입니다.
    let instructionText: String

    /// 태명을 한 번 치환해 화면 갱신 동안 같은 안내를 유지합니다.
    /// - Parameter babyNickname: 준비 안내 두 번째 줄에 표시할 태명입니다.
    init(babyNickname: String) {
        instructionText = "아내의 배에 손을 얹고\n\(babyNickname)와 교감할 준비가 되면\n시작 버튼을 눌러주세요"
    }

    /// 제목과 세 줄 안내를 가운데 정렬해 읽기 순서를 유지합니다.
    var body: some View {
        VStack(spacing: Self.textSpacing) {
            Text("태담 준비하기")
                .font(.system(size: Self.titleFontSize, weight: .bold))
                .tracking(0.38)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier("TaedamPreparationTitle")

            Text(instructionText)
                .font(.system(size: Self.instructionFontSize, weight: .regular))
                .tracking(-0.26)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("TaedamPreparationInstruction")
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 5: 시작 버튼 컴포넌트 구현**

`Siboya/Features/Home/Component/TaedamPreparationStartButton.swift`를 다음처럼 작성한다.

```swift
import SwiftUI

/// 준비자세 sheet 하단에서 시작 callback과 권한 요청 로딩 상태를 표시합니다.
struct TaedamPreparationStartButton: View {
    /// Figma ready 버튼의 고정 높이입니다.
    static let height: CGFloat = 52

    /// 권한 요청 중 버튼을 비활성화하고 진행 표시로 바꿀 상태입니다.
    let isLoading: Bool

    /// 실제 권한 확인을 상위 흐름에 요청할 callback입니다.
    let action: () -> Void

    /// 로딩 중 중복 탭을 막기 위해 계산한 입력 가능 상태입니다.
    var isEnabled: Bool {
        !isLoading
    }

    /// 버튼 입력을 별도 메서드로 전달해 View가 권한 API를 직접 소유하지 않게 합니다.
    func start() {
        action()
    }

    /// Figma의 52pt capsule과 프로젝트 강조색으로 시작 동작을 표시합니다.
    var body: some View {
        Button(action: start) {
            Group {
                if isLoading {
                    // 시스템 권한 응답을 기다리는 동안 현재 처리가 진행 중임을 알립니다.
                    ProgressView()
                        .tint(.white)
                        .accessibilityHidden(true)
                } else {
                    Text("시작하기")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .foregroundStyle(Color.white)
        .background(
            isEnabled ? Color.primaryRed : Color.gray.opacity(0.4),
            in: Capsule()
        )
        .disabled(!isEnabled)
        .accessibilityLabel("시작하기")
        .accessibilityValue(isLoading ? "처리 중" : "")
        .accessibilityIdentifier("TaedamPreparationStartButton")
    }
}
```

- [ ] **Step 6: 컴포넌트 집중 테스트 확인**

Run:

```bash
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/TaedamPreparationComponentsTests
```

Expected: PASS. 이미지·안내·버튼의 규격과 callback 테스트가 모두 성공한다.

- [ ] **Step 7: Task 1 변경만 커밋**

```bash
git commit --only Siboya/Features/Home/Component/TaedamPreparationArtwork.swift Siboya/Features/Home/Component/TaedamPreparationGuidance.swift Siboya/Features/Home/Component/TaedamPreparationStartButton.swift SiboyaTests/Home/TaedamPreparationComponentsTests.swift -m "feat: 태담 준비자세 컴포넌트 구현"
```

Expected: 커밋에는 새 컴포넌트와 테스트만 포함되고 사용자 소유 프로젝트·에셋 변경은 유지된다.

---

### Task 2: 준비자세 View 조립과 실제 sheet 경로 검증

**Files:**
- Modify: `Siboya/Features/Home/View/TaedamPreparationView.swift`
- Modify: `Siboya/Features/Home/View/ScriptPreviewView.swift`
- Modify: `SiboyaTests/Home/ScriptPreviewViewTests.swift`
- Modify: `SiboyaUITests/SiboyaUITests.swift`

**Interfaces:**
- Consumes: Task 1의 세 컴포넌트, `babyNickname`, `isRequestingPermission`, `onClose`, `onStart`
- Produces: `TaedamPreparationView.sheetDetentFraction == 0.95`, Figma 배치 상수, 실제 Preview → Preparation → Preview UI 경로

- [ ] **Step 1: View 배치와 callback 실패 테스트 작성**

`SiboyaTests/Home/ScriptPreviewViewTests.swift`에 다음 테스트를 추가한다.

```swift
    /// 준비자세 sheet가 Figma의 detent와 주요 세로·하단 배치 수치를 사용하는지 검증합니다.
    @Test
    func preparationUsesFigmaSheetMetrics() {
        #expect(TaedamPreparationView.sheetDetentFraction == 0.95)
        #expect(TaedamPreparationView.headerHeight == 44)
        #expect(TaedamPreparationView.closeLabelSize == 22)
        #expect(TaedamPreparationView.artworkTopSpacing == 52)
        #expect(TaedamPreparationView.guidanceTopSpacing == 67)
        #expect(TaedamPreparationView.horizontalPadding == 20)
        #expect(TaedamPreparationView.bottomPadding == 22)
    }

    /// 준비자세 View가 닫기와 시작 동작을 직접 처리하지 않고 상위 callback으로 한 번씩 전달하는지 검증합니다.
    @Test
    func preparationForwardsCloseAndStartActions() {
        var closeCount = 0
        var startCount = 0
        let view = TaedamPreparationView(
            babyNickname: "꾹꾹이",
            isRequestingPermission: false,
            onClose: { closeCount += 1 },
            onStart: { startCount += 1 }
        )

        view.close()
        view.start()

        #expect(closeCount == 1)
        #expect(startCount == 1)
    }
```

- [ ] **Step 2: 새 View 계약이 없어서 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/ScriptPreviewViewTests/preparationUsesFigmaSheetMetrics -only-testing:SiboyaTests/ScriptPreviewViewTests/preparationForwardsCloseAndStartActions
```

Expected: FAIL at compile time because the layout constants, `close()`, and `start()` do not exist.

- [ ] **Step 3: 준비자세 View를 새 컴포넌트로 조립**

`Siboya/Features/Home/View/TaedamPreparationView.swift`를 다음 구조로 교체한다.

```swift
import SwiftUI

/// 태담 시작 전 자세를 안내하고 닫기·권한 확인 동작을 상위 흐름으로 전달하는 bottom sheet입니다.
struct TaedamPreparationView: View {
    /// 안전 영역을 제외한 시스템 최대 detent에서 Figma의 화면 높이 약 87%를 재현하는 비율입니다.
    static let sheetDetentFraction = 0.95

    /// Figma close control이 차지하는 header 높이입니다.
    static let headerHeight: CGFloat = 44

    /// 시스템 glass 여백을 포함했을 때 닫기 control 외곽이 약 44pt가 되게 하는 label 크기입니다.
    static let closeLabelSize: CGFloat = 22

    /// Header 아래에서 프로필 이미지까지 확보할 세로 간격입니다.
    static let artworkTopSpacing: CGFloat = 52

    /// 프로필 이미지와 안내 제목 사이의 Figma 기준 간격입니다.
    static let guidanceTopSpacing: CGFloat = 67

    /// 시작 버튼이 화면 양쪽에서 유지할 여백입니다.
    static let horizontalPadding: CGFloat = 20

    /// 시작 버튼과 sheet 하단 사이의 Figma 기준 여백입니다.
    static let bottomPadding: CGFloat = 22

    /// 기존 테스트와 외부 표시 계약이 확인할 기본 프로필 에셋 이름입니다.
    let profileAssetName = TaedamPreparationArtwork.defaultAssetName

    /// 안내 컴포넌트에 전달할 사용자 태명입니다.
    let babyNickname: String

    /// 권한 요청 중 시작 버튼의 중복 입력을 막을 상태입니다.
    let isRequestingPermission: Bool

    /// 닫기 버튼을 선택했을 때 sheet 상태를 갱신할 상위 callback입니다.
    let onClose: () -> Void

    /// 시작하기를 선택했을 때 권한 확인을 요청할 상위 callback입니다.
    let onStart: () -> Void

    /// 기존 표시 계약과 테스트가 확인할 태명 치환 안내 문구입니다.
    var instructionText: String {
        TaedamPreparationGuidance(babyNickname: babyNickname).instructionText
    }

    /// 닫기 동작을 상위 흐름으로 전달해 View가 sheet 상태를 직접 소유하지 않게 합니다.
    func close() {
        onClose()
    }

    /// 시작 동작을 상위 흐름으로 전달해 View가 권한 API를 직접 호출하지 않게 합니다.
    func start() {
        onStart()
    }

    /// 상단 닫기, Figma 위치의 안내 콘텐츠와 하단 시작 버튼을 하나의 sheet에 조립합니다.
    var body: some View {
        VStack(spacing: 0) {
            // 시스템 grabber 아래에 iOS 26 glass 닫기 버튼을 오른쪽 정렬합니다.
            HStack {
                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .frame(
                            width: Self.closeLabelSize,
                            height: Self.closeLabelSize
                        )
                }
                .buttonStyle(.glass)
                .frame(width: 44, height: 44)
                .accessibilityLabel("준비자세 닫기")
                .accessibilityIdentifier("TaedamPreparationCloseButton")
            }
            .frame(height: Self.headerHeight)
            .padding(.horizontal, 16)

            // Figma의 sheet 상단 좌표를 유지하면서 누락 에셋에는 같은 크기의 대체 박스를 표시합니다.
            TaedamPreparationArtwork(assetName: profileAssetName)
                .padding(.top, Self.artworkTopSpacing)

            // 제목과 태명 안내를 이미지 아래의 승인된 간격으로 배치합니다.
            TaedamPreparationGuidance(babyNickname: babyNickname)
                .padding(.top, Self.guidanceTopSpacing)

            // 일반 글자 크기에서는 버튼을 하단에 고정하고 큰 글자에서는 남은 공간이 먼저 줄어들게 합니다.
            Spacer(minLength: 24)

            TaedamPreparationStartButton(
                isLoading: isRequestingPermission,
                action: start
            )
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.bottom, Self.bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
```

같은 파일의 `#Preview`는 기존 `babyNickname`, `onClose`, `onStart` 입력과 `TaedamPreparationView.sheetDetentFraction`을 사용하도록 갱신한다.

- [ ] **Step 4: ScriptPreviewView의 detent를 View 계약에 연결**

`Siboya/Features/Home/View/ScriptPreviewView.swift`의 sheet modifier를 다음처럼 변경한다.

```swift
            // Figma와 같이 상단 일부가 보이는 준비자세 sheet 높이를 View의 단일 계약으로 유지합니다.
            .presentationDetents([
                .fraction(TaedamPreparationView.sheetDetentFraction)
            ])
            .presentationDragIndicator(.visible)
```

- [ ] **Step 5: 실제 준비자세 sheet UI 경로 테스트 작성**

`SiboyaUITests/SiboyaUITests.swift`에 다음 테스트를 추가한다.

```swift
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
```

- [ ] **Step 6: View 단위 테스트와 실제 modal UI 테스트 확인**

Run:

```bash
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/ScriptPreviewViewTests
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaUITests/SiboyaUITests/testPreparationSheetShowsFigmaContentAndReturnsPreview
```

Expected: PASS. View 배치와 callback 테스트가 성공하고 실제 준비자세 sheet가 표시된 뒤 미리보기로 복귀한다.

- [ ] **Step 7: 전체 회귀 테스트, lint와 Debug Simulator 빌드 실행**

Run:

```bash
xcodebuild test -quiet -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests
./Scripts/lint.sh
xcodebuild build -quiet -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
git diff --check
```

Expected: 모든 단위 테스트 PASS, SwiftLint 오류 0건, Debug Simulator 빌드 성공, 작업 파일 whitespace 오류 0건.

- [ ] **Step 8: Task 2 변경만 커밋**

```bash
git commit --only Siboya/Features/Home/View/TaedamPreparationView.swift Siboya/Features/Home/View/ScriptPreviewView.swift SiboyaTests/Home/ScriptPreviewViewTests.swift SiboyaUITests/SiboyaUITests.swift -m "feat: 태담 준비자세 모달 화면 구현"
```

Expected: 커밋에는 준비자세 View 조립과 테스트만 포함되고 사용자 소유 프로젝트·에셋 변경은 유지된다.
