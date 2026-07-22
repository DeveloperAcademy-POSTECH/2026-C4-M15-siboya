# Script Preview Top Safe Area Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ScriptPreviewHero`와 이를 담는 `ScriptPreviewView`가 상단 safe area를 지나 화면 물리적 최상단부터 표시되게 한다.

**Architecture:** 두 View가 실제 modifier에 사용하는 `Edge.Set` 계약을 각각 내부 정적 프로퍼티로 드러내 테스트와 구현이 같은 값을 참조하게 한다. Hero와 상위 `ScrollView` 모두 `.top`만 무시하고 navigation bar 배경만 숨기며, 기존 시스템 뒤로가기 버튼과 하단 `safeAreaInset`은 그대로 유지한다.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, Xcode 26 iOS Simulator

## Global Constraints

- 새로 작성하거나 수정하는 모든 Swift 코드와 테스트에는 역할, 레이아웃 이유, 검증 상황과 기대 결과를 설명하는 한국어 주석을 함께 작성한다.
- 상단 safe area만 무시하고 하단 `safeAreaInset`과 `ScriptPreviewBottomBar`는 기존 배치를 유지한다.
- 시스템 뒤로가기 버튼을 제거하거나 커스텀 버튼으로 교체하지 않는다.
- 음수 padding이나 기기별 safe-area 높이 계산을 사용하지 않는다.
- 권한, sheet, `TaedamScreen`, 대본 데이터와 이미지 에셋 매핑은 변경하지 않는다.

---

### Task 1: Hero와 미리보기 화면을 물리적 최상단까지 확장

**Files:**
- Modify: `Siboya/Features/Home/Component/ScriptPreviewHero.swift`
- Modify: `Siboya/Features/Home/View/ScriptPreviewView.swift`
- Test: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`
- Test: `SiboyaTests/Home/ScriptPreviewViewTests.swift`

**Interfaces:**
- Consumes: SwiftUI `View.ignoresSafeArea(_:edges:)`, `View.toolbarBackground(_:for:)`, 기존 `ScriptPreviewBottomBar` 하단 `safeAreaInset`
- Produces: `ScriptPreviewHero.ignoredSafeAreaEdges: Edge.Set`, `ScriptPreviewView.ignoredSafeAreaEdges: Edge.Set`

- [ ] **Step 1: 상단 safe area 계약을 검증하는 실패 테스트 작성**

`SiboyaTests/Home/ScriptPreviewComponentsTests.swift`의 `ScriptPreviewComponentsTests`에 다음 테스트를 추가한다.

```swift
    /// Hero가 화면 최상단까지 확장하되 하단 안전 영역은 침범하지 않는지 검증합니다.
    @Test @MainActor
    func heroExtendsThroughOnlyTopSafeArea() {
        #expect(ScriptPreviewHero.ignoredSafeAreaEdges.contains(.top))
        #expect(!ScriptPreviewHero.ignoredSafeAreaEdges.contains(.bottom))
    }
```

`SiboyaTests/Home/ScriptPreviewViewTests.swift` 상단에 `import SwiftUI`를 추가하고 `ScriptPreviewViewTests`에 다음 테스트를 추가한다.

```swift
    /// 미리보기 ScrollView가 Hero와 같은 기준으로 상단만 확장하는지 검증합니다.
    @Test
    func previewExtendsScrollThroughOnlyTopSafeArea() {
        #expect(ScriptPreviewView.ignoredSafeAreaEdges.contains(.top))
        #expect(!ScriptPreviewView.ignoredSafeAreaEdges.contains(.bottom))
    }
```

- [ ] **Step 2: 새 계약이 아직 없어서 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests/heroExtendsThroughOnlyTopSafeArea -only-testing:SiboyaTests/ScriptPreviewViewTests/previewExtendsScrollThroughOnlyTopSafeArea
```

Expected: FAIL at compile time with `type 'ScriptPreviewHero' has no member 'ignoredSafeAreaEdges'` and `type 'ScriptPreviewView' has no member 'ignoredSafeAreaEdges'`.

- [ ] **Step 3: Hero의 상단 full-bleed 계약과 modifier 구현**

`Siboya/Features/Home/Component/ScriptPreviewHero.swift`에서 Thumbnail 상수 앞에 다음 프로퍼티를 추가한다.

```swift
    /// Hero 배경과 대표 이미지가 상태바 영역까지 이어지도록 무시할 안전 영역 방향입니다.
    static let ignoredSafeAreaEdges: Edge.Set = .top
```

같은 파일의 `body` 마지막 modifier에 상단 safe area 무시를 추가한다.

```swift
        .frame(maxWidth: .infinity)
        // 기본 디자인 높이는 유지하되 접근성 글자 크기에서는 제목이 차지하는 만큼 확장합니다.
        .frame(minHeight: Self.backgroundHeight, alignment: .top)
        // 상위 화면과 단독 Preview 모두에서 Back 배경이 화면 물리적 최상단부터 이어지게 합니다.
        .ignoresSafeArea(edges: Self.ignoredSafeAreaEdges)
```

- [ ] **Step 4: 미리보기 ScrollView와 navigation bar를 full-bleed 배치에 맞게 구현**

`Siboya/Features/Home/View/ScriptPreviewView.swift`에서 `route` 앞에 다음 프로퍼티를 추가한다.

```swift
    /// ScrollView가 Hero의 full-bleed 배치를 보존하도록 무시할 안전 영역 방향입니다.
    static let ignoredSafeAreaEdges: Edge.Set = .top
```

같은 파일에서 `ScrollView`의 modifier와 navigation bar 설정을 다음처럼 갱신한다. 기존 하단 `safeAreaInset`, sheet, Alert, full-screen cover 코드는 그대로 둔다.

```swift
        }
        // 상위 스크롤 컨테이너도 상단까지 확장해 Hero의 ignoresSafeArea가 NavigationStack에서 잘리지 않게 합니다.
        .ignoresSafeArea(edges: Self.ignoredSafeAreaEdges)
        .background(Color(.systemBackground))
        // 스크롤과 겹치지 않으며 접근성 안전 영역에도 맞추기 위해 공통 하단 바를 safe area inset으로 고정합니다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ScriptPreviewBottomBar {
                flowModel.presentPreparation()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // 시스템 뒤로가기 버튼은 유지하면서 Hero 배경이 navigation bar 뒤에서도 보이게 합니다.
        .toolbarBackground(.hidden, for: .navigationBar)
```

- [ ] **Step 5: 새 계약 테스트와 기존 미리보기 레이아웃 테스트가 통과하는지 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests -only-testing:SiboyaTests/ScriptPreviewViewTests
```

Expected: PASS. 새 `.top`/`.bottom` 계약, 기존 132pt Thumbnail, Back 상단 정렬, Dynamic Type 확장, route 보존 테스트가 모두 성공한다.

- [ ] **Step 6: 전체 회귀 테스트, lint, Debug Simulator 빌드 실행**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests
./Scripts/lint.sh
xcodebuild build -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Expected: 모든 `SiboyaTests` PASS, SwiftLint 오류 0건, `** BUILD SUCCEEDED **`.

- [ ] **Step 7: 구현 변경만 커밋**

사용자 소유의 `Siboya.xcodeproj/project.pbxproj`와 `img_profile.imageset` 변경은 staging 대상에서 제외한 뒤 다음 파일만 커밋한다.

```bash
git add Siboya/Features/Home/Component/ScriptPreviewHero.swift Siboya/Features/Home/View/ScriptPreviewView.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift SiboyaTests/Home/ScriptPreviewViewTests.swift
git commit -m "fix: 대본 미리보기를 화면 최상단에 배치"
```

Expected: 커밋에는 위 네 파일만 포함되고 사용자 소유 변경의 staged/unstaged 상태는 작업 전과 동일하게 복원된다.
