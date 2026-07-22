# Script Preview Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home에서 선택한 대본을 실제 번들·SwiftData 값으로 미리보기하고, 준비자세·권한 확인을 거쳐 기존 `TaedamScreen`까지 연결한다.

**Architecture:** `HomeScreenModel`은 선택한 UUID·버전으로 정확한 대본을 찾아 태명 치환이 끝난 `TaedamSessionInputDTO`와 배열 인덱스 기반 `ScriptArtworkSeries`를 만든다. `ContentView`는 `NavigationStack`의 상위 조정자로 동작하고, `ScriptPreviewView`는 미리보기·sheet·full-screen 상태를 `ScriptPreviewFlowModel`에 위임한다. Apple 권한 API는 `TaedamPermissionAuthorizing` 뒤에 숨겨 테스트 대역으로 교체한다.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, Observation, AVFoundation, Speech, Testing, iOS 26.5.

## Global Constraints

- 모든 신규·수정 Swift 코드와 테스트에는 역할·상태·함수·레이아웃·핵심 분기를 설명하는 한국어 주석을 작성한다.
- View 파일은 `Siboya/Features/Home/View`, 조정 모델은 `Siboya/Features/Home/Model`, 시스템 권한 구현은 `Siboya/Features/Home/Service`에 둔다.
- 미리보기 132×132 대표 이미지는 `TitleImage1~7Thumbnail`, 상단 배경은 `TitleImage1~7Back`을 사용한다.
- 이미지 에셋이 없으면 해당 프레임만 중립색 박스로 대체한다.
- 선택한 대본의 이미지 시리즈는 선택 경로가 아니라 `taedam-scripts.json` 배열 인덱스로 결정한다.
- 권한 순서는 마이크 확인·요청 후 Speech 확인·요청이며, 모두 승인된 뒤 sheet `onDismiss` 이후에만 `TaedamScreen`을 표시한다.
- Debug와 Release 타깃에 `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` 생성 Info.plist 값을 추가한다.
- 사용자 소유의 `DEVELOPMENT_TEAM` 설정과 `img_profile` staged 에셋은 변경하거나 커밋에 포함하지 않는다.

---

### Task 1: 선택 DTO와 미리보기 Route 및 Home 데이터 해석

**Files:**
- Create: `Siboya/Features/Home/Model/ScriptSelectionDTO.swift`
- Create: `Siboya/Features/Home/Model/ScriptPreviewRoute.swift`
- Modify: `Siboya/Features/Home/Model/HomeScreenModel.swift`
- Test: `SiboyaTests/Home/HomeViewStateTests.swift`

**Interfaces:**
- Produces `ScriptSelectionDTO(scriptID: UUID, scriptVersion: Int)`.
- Produces `ScriptPreviewRoute(sessionInput: TaedamSessionInputDTO, artworkSeries: ScriptArtworkSeries)` and stable `id`.
- `HomeScreenModel.load(repository:)` caches the trimmed nickname, gestational week, and loaded script document; `makePreviewRoute(for:) -> ScriptPreviewRoute?` resolves an exact UUID/version pair.

- [ ] **Step 1: Write the failing tests**

```swift
@Test @MainActor
func previewRouteUsesExactVersionAndScriptArrayArtworkIndex() throws {
    let document = try BundledTaedamScriptLoader.load()
    let selected = try #require(document.scripts.first)
    let repository = HomeProfileRepositoryStub {
        BabyProfile(nickname: "꾹꾹이", gestationalWeek: 22)
    }
    let model = HomeScreenModel(
        weeklyContentLoader: { try BundledHomeWeeklyContentLoader.load() },
        scriptDocumentLoader: { document }
    )

    model.load(repository: repository)

    let route = try #require(model.makePreviewRoute(
        for: ScriptSelectionDTO(scriptID: selected.id, scriptVersion: selected.version)
    ))
    #expect(route.sessionInput.script.scriptID == selected.id)
    #expect(route.sessionInput.script.scriptVersion == selected.version)
    #expect(route.sessionInput.babyNickname == "꾹꾹이")
    #expect(route.artworkSeries == .one)
}

@Test @MainActor
func previewRouteDoesNotResolveDifferentVersionOrMissingProfile() throws {
    let document = try BundledTaedamScriptLoader.load()
    let selected = try #require(document.scripts.first)
    let model = HomeScreenModel(scriptDocumentLoader: { document })
    model.load(repository: HomeProfileRepositoryStub { nil })

    #expect(model.makePreviewRoute(
        for: ScriptSelectionDTO(scriptID: selected.id, scriptVersion: selected.version + 1)
    ) == nil)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/Home/HomeViewStateTests
```

Expected: FAIL because `ScriptSelectionDTO`, `ScriptPreviewRoute`, and `makePreviewRoute(for:)` do not exist.

- [ ] **Step 3: Write the minimal implementation**

```swift
struct ScriptSelectionDTO: Equatable, Sendable {
    /// Home에서 선택한 대본 자체와 수정 버전을 함께 보관합니다.
    let scriptID: UUID
    /// 같은 UUID의 여러 수정본을 정확히 구분합니다.
    let scriptVersion: Int
}

struct ScriptPreviewRoute: Identifiable, Equatable, Sendable {
    /// 미리보기·준비자세·태담 화면이 공유할 태명 치환 완료 입력입니다.
    let sessionInput: TaedamSessionInputDTO
    /// JSON 배열 위치에서 계산한 TitleImage 시리즈입니다.
    let artworkSeries: ScriptArtworkSeries

    /// NavigationStack에서 UUID와 버전 조합으로 동일 대본을 식별합니다.
    var id: String {
        "\(sessionInput.script.scriptID.uuidString)-\(sessionInput.script.scriptVersion)"
    }
}
```

`HomeScreenModel`에는 `loadedNickname`, `loadedGestationalWeek`, `loadedScriptDocument` 캐시를 추가한다. `load` 성공 여부와 무관하게 캐시를 함께 갱신하고, route 생성 시 `trimmingCharacters(in: .whitespacesAndNewlines)` 후 비어 있지 않은 태명, exact UUID/version, `firstIndex` 배열 위치를 guard로 확인한다. 확인되면 `script.makeSessionInput(babyNickname:)`과 `.cycling(forZeroBasedIndex:)`를 결합한다.

- [ ] **Step 4: Run tests to verify they pass**

Run the same `xcodebuild test ... -only-testing:SiboyaTests/Home/HomeViewStateTests` command. Expected: PASS, with all existing Home state tests still passing.

- [ ] **Step 5: Commit**

```bash
git add Siboya/Features/Home/Model/ScriptSelectionDTO.swift Siboya/Features/Home/Model/ScriptPreviewRoute.swift Siboya/Features/Home/Model/HomeScreenModel.swift SiboyaTests/Home/HomeViewStateTests.swift
git commit -m "feat: 대본 미리보기 route 데이터 연결"
```

### Task 2: 권한 서비스와 준비자세 흐름 상태 전이

**Files:**
- Create: `Siboya/Features/Home/Service/TaedamPermissionAuthorizer.swift`
- Create: `Siboya/Features/Home/Model/ScriptPreviewFlowModel.swift`
- Test: `SiboyaTests/Home/ScriptPreviewFlowModelTests.swift`

**Interfaces:**
- `TaedamPermissionIssue`: `.microphone`, `.speechRecognition`.
- `TaedamPermissionResult`: `.granted`, `.denied(TaedamPermissionIssue)`.
- `TaedamPermissionAuthorizing.requestRequiredPermissions() async -> TaedamPermissionResult`.
- `ScriptPreviewFlowModel` exposes `isPreparationPresented`, `isRequestingPermission`, `permissionAlertIssue`, `shouldStartSessionAfterDismissal`, `isSessionPresented`, plus `presentPreparation()`, `requestPermissions() async`, `handlePreparationDismissed()`, `dismissSession()`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test @MainActor
func permissionDenialStoresMatchingAlertAndKeepsPreparationSheet() async {
    let model = ScriptPreviewFlowModel(
        authorizer: PermissionAuthorizerStub(result: .denied(.microphone))
    )
    model.presentPreparation()

    await model.requestPermissions()

    #expect(model.isPreparationPresented)
    #expect(model.permissionAlertIssue == .microphone)
    #expect(!model.isSessionPresented)
}

@Test @MainActor
func grantedPermissionsWaitForSheetDismissalBeforePresentingSession() async {
    let model = ScriptPreviewFlowModel(
        authorizer: PermissionAuthorizerStub(result: .granted)
    )
    model.presentPreparation()

    await model.requestPermissions()

    #expect(model.shouldStartSessionAfterDismissal)
    #expect(!model.isSessionPresented)
    #expect(!model.isPreparationPresented)

    model.handlePreparationDismissed()

    #expect(model.isSessionPresented)
    #expect(!model.shouldStartSessionAfterDismissal)
}

@Test @MainActor
func dismissingPreparationWithoutStartingDoesNotPresentSession() {
    let model = ScriptPreviewFlowModel(authorizer: PermissionAuthorizerStub(result: .granted))
    model.presentPreparation()
    model.handlePreparationDismissed()

    #expect(!model.isSessionPresented)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/Home/ScriptPreviewFlowModelTests
```

Expected: FAIL because the permission result types and flow model do not exist.

- [ ] **Step 3: Write the minimal implementation**

Implement the `@MainActor @Observable` model with a guard on `isRequestingPermission` so repeated starts are ignored. Set `isRequestingPermission = true` before awaiting the injected authorizer, then on denial set the issue and keep the sheet, while on approval set `shouldStartSessionAfterDismissal = true` and dismiss only the sheet. `handlePreparationDismissed()` presents the session only when that flag is true. `dismissSession()` clears the full-screen flag.

Implement `TaedamPermissionAuthorizer` with `AVAudioApplication.shared.recordPermission` and `SFSpeechRecognizer.authorizationStatus()`. Request undetermined states, map denied/restricted states to the matching issue, and import `AVFoundation` and `Speech`. Keep the protocol independent from UIKit so tests never invoke a system prompt.

- [ ] **Step 4: Run tests to verify they pass**

Run the same focused command. Expected: PASS, including denial, approval-after-dismissal, direct dismiss, and duplicate-request tests.

- [ ] **Step 5: Commit**

```bash
git add Siboya/Features/Home/Service/TaedamPermissionAuthorizer.swift Siboya/Features/Home/Model/ScriptPreviewFlowModel.swift SiboyaTests/Home/ScriptPreviewFlowModelTests.swift
git commit -m "feat: 대본 미리보기 권한 흐름 추가"
```

### Task 3: ScriptPreviewView와 준비자세 View 조립

**Files:**
- Create: `Siboya/Features/Home/View/ScriptPreviewView.swift`
- Create: `Siboya/Features/Home/View/TaedamPreparationView.swift`
- Modify: `Siboya/Features/Home/View/ContentView.swift`
- Test: `SiboyaTests/Home/ScriptPreviewViewTests.swift`

**Interfaces:**
- `ScriptPreviewView(route: ScriptPreviewRoute, authorizer: any TaedamPermissionAuthorizing = TaedamPermissionAuthorizer())`.
- `TaedamPreparationView(babyNickname: String, isRequestingPermission: Bool, onClose: @escaping () -> Void, onStart: @escaping () -> Void)`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test @MainActor
func preparationMessageIncludesResolvedBabyNickname() {
    let view = TaedamPreparationView(
        babyNickname: "꾹꾹이",
        isRequestingPermission: false,
        onClose: {},
        onStart: {}
    )

    #expect(view.instructionText.contains("꾹꾹이"))
    #expect(view.profileAssetName == "img_profile")
}

@Test @MainActor
func previewRouteKeepsSessionInputAndArtworkSeries() {
    let route = ScriptPreviewRoute(
        sessionInput: .mock,
        artworkSeries: .seven
    )
    let view = ScriptPreviewView(route: route, authorizer: PermissionAuthorizerStub(result: .granted))

    #expect(view.route == route)
    #expect(view.route.artworkSeries == .seven)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/Home/ScriptPreviewViewTests
```

Expected: FAIL because the two View types and their display accessors do not exist.

- [ ] **Step 3: Write the minimal implementation**

`ScriptPreviewView` owns a `@State` flow model, places `ScriptPreviewHero`, `ScriptPreviewDuration`, and `ScriptPreviewBody` in one vertical `ScrollView`, fixes the bottom bar with `.safeAreaInset(edge: .bottom)`, presents `TaedamPreparationView` with `.sheet` and `.fraction(0.87)`, and presents `TaedamScreen(input:)` with `.fullScreenCover` only after `handlePreparationDismissed()` enables it. The alert uses the issue-specific message and `UIApplication.openSettingsURLString`; dismissing or opening settings leaves the preparation sheet and never auto-starts.

`TaedamPreparationView` uses `Image("img_profile")` in a 132×132 frame with a neutral rounded rectangle fallback when the asset is unavailable, a top-aligned close button, the Korean instruction with the injected nickname, and the existing `PrimaryButton(title: "시작하기", isEnabled: !isRequestingPermission, isLoading: isRequestingPermission)`. Every layout group and interaction branch receives a Korean comment.

- [ ] **Step 4: Run tests to verify they pass**

Run the focused view command and then:
```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/Home/ScriptPreviewComponentsTests -only-testing:SiboyaTests/Home/ScriptPreviewViewTests
```

Expected: PASS, including existing component tests.

- [ ] **Step 5: Commit**

```bash
git add Siboya/Features/Home/View/ScriptPreviewView.swift Siboya/Features/Home/View/TaedamPreparationView.swift Siboya/Features/Home/View/ContentView.swift SiboyaTests/Home/ScriptPreviewViewTests.swift
git commit -m "feat: 대본 미리보기와 준비자세 화면 구현"
```

### Task 4: Home Navigation과 권한 설명 설정

**Files:**
- Modify: `Siboya/Features/Home/View/ContentView.swift`
- Modify: `Siboya.xcodeproj/project.pbxproj`
- Test: `SiboyaTests/Home/ContentViewNavigationTests.swift`

**Interfaces:**
- `ContentView` converts Home callbacks into `ScriptSelectionDTO`, asks `HomeScreenModel.makePreviewRoute(for:)`, and appends only successful routes to a `NavigationStack` path.
- `NavigationDestination` builds `ScriptPreviewView(route:)`, preserving the selected session input on return.

- [ ] **Step 1: Write the failing test**

```swift
@Test @MainActor
func contentViewSelectionMappingPreservesUUIDAndVersion() {
    let id = UUID()
    let selection = ContentView.makeScriptSelection(scriptID: id, scriptVersion: 3)

    #expect(selection.scriptID == id)
    #expect(selection.scriptVersion == 3)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run the focused `ContentViewNavigationTests` command. Expected: FAIL until the DTO and ContentView route integration are present.

- [ ] **Step 3: Write the minimal implementation**

Add the testable `ContentView.makeScriptSelection(scriptID:version:)` helper, then wrap `HomeView` in `NavigationStack(path: $navigationPath)`, pass a callback that uses that helper, append the route returned by the model, and declare `navigationDestination(for: ScriptPreviewRoute.self)`. Keep the existing `prepareAndLoadHome()` and `onSelectPromiseTab` behavior. Add these target build settings to both app Debug and Release configurations without changing the user’s team value:

```text
INFOPLIST_KEY_NSMicrophoneUsageDescription = "태담 진행과 버킷리스트 음성 입력을 위해 마이크 접근이 필요합니다."
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "말한 약속을 텍스트로 변환하기 위해 음성 인식 접근이 필요합니다."
```

- [ ] **Step 4: Run tests to verify they pass**

Run the focused navigation test, then inspect generated settings:
```bash
xcodebuild -project Siboya.xcodeproj -scheme Siboya -showBuildSettings | rg 'NSMicrophoneUsageDescription|NSSpeechRecognitionUsageDescription|DEVELOPMENT_TEAM'
```

Expected: both usage strings and `Y9CSYFT846` appear for the app target.

- [ ] **Step 5: Commit**

```bash
git add Siboya/Features/Home/View/ContentView.swift Siboya.xcodeproj/project.pbxproj SiboyaTests/Home/ContentViewNavigationTests.swift
git commit -m "feat: Home에서 대본 미리보기로 이동 연결"
```

### Task 5: Full verification and implementation audit

**Files:**
- Modify: any changed Swift file whose comments no longer match behavior.
- Test: all existing `SiboyaTests` and available UI/build checks.

- [ ] **Step 1: Run focused Home tests**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/Home
```

Expected: PASS.

- [ ] **Step 2: Run all unit tests**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests
```

Expected: PASS with no new warnings from the changed files.

- [ ] **Step 3: Run SwiftLint and Debug build**

```bash
Scripts/lint.sh
xcodebuild build -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: lint succeeds and Debug build succeeds.

- [ ] **Step 4: Audit Figma and runtime criteria**

Confirm in source and, when a simulator is available, visually inspect: `TitleImageNBack` top alignment, `TitleImageNThumbnail` at 132pt, `ScriptPreviewDuration` vertical separators, fixed bottom button, `.fraction(0.87)` preparation sheet, `img_profile` fallback box, denial Alert, and delayed `TaedamScreen` presentation after sheet dismissal.

- [ ] **Step 5: Commit any verification-only comment corrections**

```bash
git add Siboya/Features/Home SiboyaTests/Home
git commit -m "chore: 대본 미리보기 흐름 검증 정리"
```

If the verification step changes `project.pbxproj`, stage only the newly added usage-description hunks with `git add -p`; leave the pre-existing `DEVELOPMENT_TEAM` hunk unstaged. Do not stage or commit the user-owned `img_profile` files unless the user explicitly asks for that asset commit.
